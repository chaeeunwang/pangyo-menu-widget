#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
source_app="$project_dir/dist/PangyoMenu.app"
built_app="$project_dir/.build/xcode/Build/Products/Release/PangyoMenu.app"
applications_dir="${HOME}/Applications"
installed_app="$applications_dir/PangyoMenu.app"
staging_app="$applications_dir/.PangyoMenu.installing.app"
extension_path="$installed_app/Contents/PlugIns/MenuWidgetExtension.appex"
launch_services='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

macos_major=$(sw_vers -productVersion | cut -d. -f1)
if (( macos_major < 14 )); then
  print -u2 "오늘의 메뉴 위젯은 macOS 14 이상이 필요합니다."
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  print -u2 "Mac App Store에서 Xcode를 설치하고 한 번 실행한 뒤 다시 시도해주세요."
  exit 1
fi

"$project_dir/scripts/build-app.sh"
mkdir -p "$applications_dir"

if [[ "$staging_app" != "$applications_dir/.PangyoMenu.installing.app" ]]; then
  print -u2 "안전하지 않은 설치 경로입니다."
  exit 1
fi

rm -rf "$staging_app"
ditto "$source_app" "$staging_app"
codesign --verify --deep --strict "$staging_app"

# Xcode가 개발용 빌드 산출물까지 위젯으로 등록하는 것을 막기 위해
# 설치본 외 경로를 등록 해제하고 빌드 디렉터리를 정리합니다.
/usr/bin/pluginkit -r "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
/usr/bin/pluginkit -r "$source_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
"$launch_services" -u "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
"$launch_services" -u "$built_app" 2>/dev/null || true
"$launch_services" -u "$source_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
"$launch_services" -u "$source_app" 2>/dev/null || true
xcodebuild -quiet \
  -project "$project_dir/PangyoMenuWidget.xcodeproj" \
  -scheme MenuWidgetHost \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$project_dir/.build/xcode" \
  clean

pkill -x MenuWidgetHost 2>/dev/null || true

if [[ -d "$installed_app" ]]; then
  /usr/bin/pluginkit -r "$extension_path" 2>/dev/null || true
  "$launch_services" -u "$extension_path" 2>/dev/null || true
  "$launch_services" -u "$installed_app" 2>/dev/null || true
  rm -rf "$installed_app"
fi

mv "$staging_app" "$installed_app"
"$launch_services" -gc
"$launch_services" -f -R "$installed_app"
/usr/bin/pluginkit -a "$extension_path"

killall chronod 2>/dev/null || true
killall NotificationCenter 2>/dev/null || true
killall Dock 2>/dev/null || true

open "$installed_app"

print ""
print "설치 완료: $installed_app"
print "바탕화면을 우클릭하고 ‘위젯 편집’에서 ‘오늘의 메뉴’를 추가하세요."
