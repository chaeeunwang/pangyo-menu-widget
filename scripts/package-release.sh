#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
source_app="$project_dir/dist/PangyoMenu.app"
release_dir="$project_dir/dist/release"
archive_path="$release_dir/PangyoMenu.app.zip"
checksum_path="$archive_path.sha256"

"$project_dir/scripts/build-app.sh"

if [[ "$release_dir" != "$project_dir/dist/release" ]]; then
  print -u2 "안전하지 않은 배포 경로입니다."
  exit 1
fi

rm -rf "$release_dir"
mkdir -p "$release_dir"
ditto -c -k --sequesterRsrc --keepParent "$source_app" "$archive_path"

archive_hash=$(shasum -a 256 "$archive_path" | awk '{print $1}')
print "$archive_hash  PangyoMenu.app.zip" > "$checksum_path"

codesign --verify --deep --strict "$source_app"
unzip -t "$archive_path" >/dev/null
print "$archive_path"
print "$checksum_path"
