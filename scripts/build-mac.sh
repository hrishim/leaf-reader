#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
MAC_CACHE_DIR="${MAC_CACHE_DIR:-/Volumes/codex_Extender/Caches/leaf-swift}"
MAC_TMP_DIR="${MAC_TMP_DIR:-/Volumes/codex_Extender/Work/leaf-tmp}"
mkdir -p "$MAC_CACHE_DIR" "$MAC_TMP_DIR" 'build/Leaf Reader.app/Contents/MacOS' 'build/Leaf Reader.app/Contents/Resources'
cp mac/Resources/* 'build/Leaf Reader.app/Contents/Resources/'
cp mac/Info.plist 'build/Leaf Reader.app/Contents/Info.plist'
CLANG_MODULE_CACHE_PATH="$MAC_CACHE_DIR" TMPDIR="$MAC_TMP_DIR" swiftc mac/LeafReader.swift mac/LeafReader+ContextMenus.swift mac/LeafReader+Settings.swift mac/LeafReader+Library.swift mac/ReaderStore.swift mac/ReaderNetwork.swift mac/ReaderOPML.swift mac/ReaderLinks.swift -parse-as-library -o 'build/Leaf Reader.app/Contents/MacOS/LeafReader' -framework AppKit -framework WebKit -module-cache-path "$MAC_CACHE_DIR"
codesign --force --deep --sign - 'build/Leaf Reader.app'
