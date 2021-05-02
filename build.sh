#!/usr/bin/env sh

find ./src -name '*.md' -exec claat export -o codelabs {} \;
cp CNAME build/
cp -a files build
