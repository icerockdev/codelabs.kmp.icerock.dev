#!/usr/bin/env sh

claat export lesson1.md
gulp dist --base-url=https://codelabs.kmp.icerock.dev
rm -r docs
mv dist docs