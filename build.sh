#!/usr/bin/env sh

find ./src -name '*.md' -exec claat export -o codelabs {} \;
