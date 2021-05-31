#!/bin/sh

[ -z "${INPUT_GITHUB_TOKEN}" ] && {
    echo 'Missing input "github_token: ${{ secrets.GITHUB_TOKEN }}".';
    exit 1;
};

remote_repo="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

rm -rf build
git clone -b gh-pages "${remote_repo}" build
cp -R build/codelabs codelabs
./build.sh
./node_modules/.bin/gulp build
rm build/codelabs
cp -R codelabs build/codelabs
source_commit=$(git rev-parse --short HEAD)
cd build || exit 1
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git add .
git commit -m "Deploy from $source_commit" -a
git push "${remote_repo}" HEAD:gh-pages
