#!/bin/bash
set -ex

# CMake Image Validation

for repo in openenclave
do
  # Remove repo if exists
  if [[ -d ./${repo} ]]; then
    rm -rf ./${repo} || sudo rm -rf ./${repo} 
  fi

  git clone --recursive https://github.com/openenclave/openenclave.git

  cd ${repo}
  git fetch origin +refs/pull/*/merge:refs/remotes/origin/pr/* && \
  git checkout origin/pr/2527

  for compiler in clang-7 #clang-8
  do
    # TODO re-enable RelDebInfo once clang-8 incompatability is fixed
    for build in Debug Release #RelDebInfo
      do
        ../testing/${repo}/cmake-build.sh -b=${build} --compiler=${compiler}
      done
  done
  # cd back to root
  cd ../..
  # remove repo to save space
  if [[ -d ./${repo} ]]; then
    rm -rf ./${repo} || sudo rm -rf ./${repo} 
  fi
done
