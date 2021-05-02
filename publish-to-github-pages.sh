#!/bin/sh


git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

git clone -b gh-pages git@github.com:icerockdev/codelabs.kmp.icerock.dev.git build
./build.sh
./node_modules/.bin/gulp build
rm  build/codelabs
cp -R  codelabs build/codelabs
cd build
git add .
git commit -m "Update versions" -a
#remote_repo="https://${GITHUB_ACTOR}:$2}@github.com/${GITHUB_REPOSITORY}.git"
#git push "${remote_repo}" HEAD:gh-pages
