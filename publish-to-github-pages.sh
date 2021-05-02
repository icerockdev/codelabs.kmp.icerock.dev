#!/bin/sh


git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"

git checkout gh-pages
git add .
git commit -m "Update versions" -a
remote_repo="https://${GITHUB_ACTOR}:$2}@github.com/${GITHUB_REPOSITORY}.git"
git push "${remote_repo}" HEAD:gh-pages
