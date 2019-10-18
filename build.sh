#!/usr/bin/env sh

claat export -o codelabs lesson1.md
claat export -o codelabs lesson-moko-template-1.md
claat export -o codelabs lesson-moko-template-2.md
claat export -o codelabs lesson-moko-template-3.md
gulp dist
rm -r docs
mv dist docs
rm docs/codelabs
mv codelabs docs/codelabs
cp CNAME docs/