#!/bin/bash

# CMake Validation
for repo in  oeedger8r-cpp openenclave
do
  if [[ -d ./${repo} ]]; then
    rm -rf ./${repo} || sudo rm -rf ./${repo} 
  fi
  git clone --recursive https://github.com/openenclave/${repo}.git && cd ${repo} && exec "../hack/cmake-build.sh" && cd ..
done
