#!/bin/bash

set -ex

# CMake Validation
for repo in  oeedger8r-cpp openenclave
do
  if [[ -d ./${repo} ]]; then
    rm -rf ./${repo} || sudo rm -rf ./${repo} 
  fi
  # TODO Iterate through build config types
  git clone --recursive https://github.com/openenclave/${repo}.git && cd ${repo}
  for buildConfig in Release RelWithDebInfo Debug
  do
    bash -c  "/hack/cmake-build.sh  -b=${buildConfig} --compiler=clang-8"
  done
  cd ..
done
