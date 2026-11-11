#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
volume_info="$(diskutil info -plist /Volumes/codex_Extender)"
[[ "$(print -r -- "$volume_info" | plutil -extract VolumeUUID raw -o - -)" == "67158BC2-8049-47D6-AF79-BC96D9E6CC9E" ]] || { print -u2 'Reconnect the required external Samsung T7.'; exit 1; }
MAC_CACHE_DIR="${MAC_CACHE_DIR:-/Volumes/codex_Extender/Caches/leaf-swift}"
MAC_TMP_DIR="${MAC_TMP_DIR:-/Volumes/codex_Extender/Work/leaf-tmp}"
mkdir -p "$MAC_CACHE_DIR" "$MAC_TMP_DIR" 'build/Leaf Reader.app/Contents/MacOS' 'build/Leaf Reader.app/Contents/Resources'
cp web/feed-updates.json 'build/Leaf Reader.app/Contents/Resources/'
cp mac/Resources/* 'build/Leaf Reader.app/Contents/Resources/'
cp mac/Info.plist 'build/Leaf Reader.app/Contents/Info.plist'
CLANG_MODULE_CACHE_PATH="$MAC_CACHE_DIR" TMPDIR="$MAC_TMP_DIR" swift -module-cache-path "$MAC_CACHE_DIR" scripts/make-mac-icon.swift build/LeafReader.iconset
iconutil -c icns build/LeafReader.iconset -o 'build/Leaf Reader.app/Contents/Resources/LeafReader.icns'
for architecture in arm64 x86_64; do
  CLANG_MODULE_CACHE_PATH="$MAC_CACHE_DIR" TMPDIR="$MAC_TMP_DIR" swiftc mac/LeafReader.swift mac/LeafReader+ContextMenus.swift mac/LeafReader+Settings.swift mac/LeafReader+Library.swift mac/ReaderStore.swift mac/ReaderNetwork.swift mac/ReaderOPML.swift mac/ReaderLinks.swift -target "$architecture-apple-macos14.0" -parse-as-library -o "build/LeafReader-$architecture" -framework AppKit -framework WebKit -module-cache-path "$MAC_CACHE_DIR"
done
lipo -create build/LeafReader-arm64 build/LeafReader-x86_64 -output 'build/Leaf Reader.app/Contents/MacOS/LeafReader'
codesign --force --deep --sign - 'build/Leaf Reader.app'
