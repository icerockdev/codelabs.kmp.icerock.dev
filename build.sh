#!/usr/bin/env sh

claat export -o codelabs lesson1.md
gulp dist --base-url=https://codelabs.kmp.icerock.dev --codelabs-dir=codelabs
rm -r docs
mv dist docs
rm docs/codelabs
mv codelabs docs/codelabs