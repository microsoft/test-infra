versions=( 1604 1804 )
build_types=( Release Debug RelWithDebInfo)
compiler_types=(clang-7 gcc)
docker_version=latest

echo "periodics:"

for version in "${versions[@]}"
do
    for build_type in "${build_types[@]}"
    do
        for compiler in "${compiler_types[@]}"
        do
            echo   "
  - name: ci-openenclave-oeedger8r-cmake-${version}-${build_type}-${compiler}
    extra_refs:
    - org: openenclave
      repo: oeedger8r-cpp
      base_ref: master
    decorate: true
    interval: 6h
    spec:
      containers:
        - image: openenclave/ubuntu${version}:${docker_version}
          command:
            - sh
            - '-c'
            - '/hack/cmake-build.sh -b=${build_type} --compiler=${compiler}'"
        done
    done
done
