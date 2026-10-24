#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
cache=/Volumes/codex_Extender/Caches/leaf-swift
scratch=/Volumes/codex_Extender/Work/leaf-tmp
mkdir -p qa "$cache" "$scratch"
sed '/^@main$/d' mac/LeafReader.swift > qa/LeafReaderForTests.swift
CLANG_MODULE_CACHE_PATH="$cache" TMPDIR="$scratch" swiftc qa/LeafReaderForTests.swift mac/LeafReader+ContextMenus.swift mac/LeafReader+Settings.swift mac/ReaderStore.swift mac/ReaderNetwork.swift mac/ReaderOPML.swift mac/ReaderLinks.swift mac/Tests/DisplayRegressionTests.swift -parse-as-library -framework AppKit -framework WebKit -module-cache-path "$cache" -o qa/display-regression-tests
qa/display-regression-tests
