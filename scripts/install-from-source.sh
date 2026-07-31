#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
source_app="$project_dir/dist/PangyoMenu.app"
built_app="$project_dir/.build/xcode/Build/Products/Release/PangyoMenu.app"
launch_services='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

if ! xcode-select -p >/dev/null 2>&1 || ! xcodebuild -version >/dev/null 2>&1; then
  print -u2 "소스 빌드에는 Xcode 16 이상이 필요합니다."
  exit 1
fi

"$project_dir/scripts/build-app.sh"
PANGYO_MENU_LOCAL_APP="$source_app" "$project_dir/scripts/install.sh"

# 개발용 빌드 산출물이 별도 위젯으로 등록되지 않도록 정리합니다.
/usr/bin/pluginkit -r "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
"$launch_services" -u "$built_app/Contents/PlugIns/MenuWidgetExtension.appex" 2>/dev/null || true
"$launch_services" -u "$built_app" 2>/dev/null || true
xcodebuild -quiet \
  -project "$project_dir/PangyoMenuWidget.xcodeproj" \
  -scheme MenuWidgetHost \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$project_dir/.build/xcode" \
  clean
