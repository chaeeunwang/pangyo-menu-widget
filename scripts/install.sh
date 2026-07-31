#!/bin/zsh
set -euo pipefail

readonly repository="chaeeunwang/pangyo-menu-widget"
readonly asset_name="PangyoMenu.app.zip"
readonly bundle_identifier="com.chaeeun.pangyo-menu-widget"
readonly extension_identifier="com.chaeeun.pangyo-menu-widget.extension"
readonly launch_services='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

readonly applications_dir="${PANGYO_MENU_APPLICATIONS_DIR:-${HOME}/Applications}"
readonly installed_app="$applications_dir/PangyoMenu.app"
readonly staging_app="$applications_dir/.PangyoMenu.installing.app"
readonly installed_extension="$installed_app/Contents/PlugIns/MenuWidgetExtension.appex"

download_dir=''

cleanup() {
  if [[ -n "$download_dir" && -d "$download_dir" ]]; then
    rm -rf "$download_dir"
  fi
}

fail() {
  print -u2 "설치 실패: $1"
  exit 1
}

trap cleanup EXIT INT TERM

macos_major=$(sw_vers -productVersion | cut -d. -f1)
if (( macos_major < 14 )); then
  fail "오늘의 메뉴 위젯은 macOS 14 이상이 필요합니다."
fi

if [[ "$installed_app" != "$applications_dir/PangyoMenu.app" || \
      "$staging_app" != "$applications_dir/.PangyoMenu.installing.app" ]]; then
  fail "안전하지 않은 설치 경로입니다."
fi

if [[ -n "${PANGYO_MENU_LOCAL_APP:-}" ]]; then
  source_app="$PANGYO_MENU_LOCAL_APP"
else
  command -v curl >/dev/null 2>&1 || fail "macOS 기본 curl 명령을 찾지 못했습니다."

  release_base="https://github.com/$repository/releases/latest/download"
  download_dir=$(mktemp -d "${TMPDIR:-/tmp}/pangyo-menu-install.XXXXXX")
  archive_path="$download_dir/$asset_name"
  checksum_path="$archive_path.sha256"
  extract_dir="$download_dir/extracted"
  cache_buster=$(date +%s)

  print "오늘의 메뉴 최신 버전을 내려받는 중입니다..."
  curl --fail --location --silent --show-error \
    --proto '=https' --tlsv1.2 --retry 3 \
    --output "$archive_path" "$release_base/$asset_name?cache=$cache_buster"
  curl --fail --location --silent --show-error \
    --proto '=https' --tlsv1.2 --retry 3 \
    --output "$checksum_path" "$release_base/$asset_name.sha256?cache=$cache_buster"

  expected_hash=$(awk '{print $1}' "$checksum_path")
  actual_hash=$(shasum -a 256 "$archive_path" | awk '{print $1}')
  if [[ ! "$expected_hash" =~ '^[0-9a-fA-F]{64}$' || "$actual_hash" != "$expected_hash" ]]; then
    fail "다운로드 파일의 SHA-256 체크섬이 일치하지 않습니다."
  fi

  mkdir -p "$extract_dir"
  ditto -x -k "$archive_path" "$extract_dir"
  source_app="$extract_dir/PangyoMenu.app"
fi

source_extension="$source_app/Contents/PlugIns/MenuWidgetExtension.appex"
[[ -d "$source_app" ]] || fail "배포 파일에서 PangyoMenu.app을 찾지 못했습니다."
[[ -d "$source_extension" ]] || fail "앱에서 위젯 확장을 찾지 못했습니다."

app_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")
extension_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_extension/Contents/Info.plist")
[[ "$app_id" == "$bundle_identifier" ]] || fail "앱 식별자가 올바르지 않습니다."
[[ "$extension_id" == "$extension_identifier" ]] || fail "위젯 식별자가 올바르지 않습니다."
codesign --verify --deep --strict "$source_app" || fail "앱 코드 서명이 유효하지 않습니다."

# 같은 식별자의 개발용 빌드가 남아 있으면 macOS가 잘못된 위젯을 실행할 수 있습니다.
while IFS= read -r registered_extension; do
  [[ "$registered_extension" == */Contents/PlugIns/MenuWidgetExtension.appex ]] || continue
  /usr/bin/pluginkit -r "$registered_extension" 2>/dev/null || true
  "$launch_services" -u "$registered_extension" 2>/dev/null || true
  "$launch_services" -u "${registered_extension%%/Contents/PlugIns/*}" 2>/dev/null || true
done < <(
  /usr/bin/pluginkit -m -A -D -vvv -i "$extension_identifier" 2>/dev/null \
    | sed -n 's/^[[:space:]]*Path = //p'
)

mkdir -p "$applications_dir"
rm -rf "$staging_app"
ditto "$source_app" "$staging_app"
xattr -dr com.apple.quarantine "$staging_app" 2>/dev/null || true
codesign --verify --deep --strict "$staging_app" || fail "설치 준비 중 코드 서명이 손상되었습니다."

# 임시 압축 해제 위치와 기존 설치본이 위젯 후보로 남지 않도록 등록을 해제합니다.
/usr/bin/pluginkit -r "$source_extension" 2>/dev/null || true
"$launch_services" -u "$source_extension" 2>/dev/null || true
"$launch_services" -u "$source_app" 2>/dev/null || true

pkill -x MenuWidgetHost 2>/dev/null || true

if [[ -d "$installed_app" ]]; then
  /usr/bin/pluginkit -r "$installed_extension" 2>/dev/null || true
  "$launch_services" -u "$installed_extension" 2>/dev/null || true
  "$launch_services" -u "$installed_app" 2>/dev/null || true
  rm -rf "$installed_app"
fi

mv "$staging_app" "$installed_app"
"$launch_services" -gc
"$launch_services" -f -R "$installed_app"
/usr/bin/pluginkit -a "$installed_extension"

killall chronod 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true
killall Dock 2>/dev/null || true

print ""
print "설치 완료: $installed_app"
print "바탕화면을 우클릭하고 ‘위젯 편집’에서 ‘오늘의 메뉴’를 추가하세요."
