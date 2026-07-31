#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
derived_data="$project_dir/.build/xcode"
built_app="$derived_data/Build/Products/Release/PangyoMenu.app"
output_app="$project_dir/dist/PangyoMenu.app"

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
print "$output_app"
