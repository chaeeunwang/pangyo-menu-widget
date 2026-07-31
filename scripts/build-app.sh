#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
derived_data="$project_dir/.build/xcode"
built_app="$derived_data/Build/Products/Release/PangyoMenu.app"
output_app="$project_dir/dist/PangyoMenu.app"
launch_services='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

cleanup_development_registration() {
  /usr/bin/pluginkit -r "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
  "$launch_services" -u "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
  "$launch_services" -u "$built_app" 2>/dev/null || true
}

trap cleanup_development_registration EXIT INT TERM

if ! command -v xcodebuild >/dev/null 2>&1; then
  print -u2 "Xcode를 설치한 뒤 다시 실행해주세요."
  exit 1
fi

xcodebuild -quiet \
  -project "$project_dir/PangyoMenuWidget.xcodeproj" \
  -scheme MenuWidgetHost \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data" \
  clean build \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM=

if [[ "$output_app" != "$project_dir/dist/PangyoMenu.app" ]]; then
  print -u2 "Unexpected output path"
  exit 1
fi

rm -rf "$output_app"
mkdir -p "$project_dir/dist"
ditto "$built_app" "$output_app"
codesign --verify --deep --strict "$output_app"

host_architectures=$(lipo -archs "$output_app/Contents/MacOS/MenuWidgetHost")
extension_architectures=$(lipo -archs "$output_app/Contents/PlugIns/MenuWidgetExtension.appex/Contents/MacOS/MenuWidgetExtension")
[[ "$host_architectures" == *arm64* && "$host_architectures" == *x86_64* ]]
[[ "$extension_architectures" == *arm64* && "$extension_architectures" == *x86_64* ]]
print "$output_app"
