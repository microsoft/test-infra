versions=( 1604 1804 )
build_types=( Release Debug RelWithDebInfo)
compiler_types=(clang-7 gcc)
docker_version=latest

echo "presubmits:
  openenclave/oeedger8r-cpp:"

for version in "${versions[@]}"
do
    for build_type in "${build_types[@]}"
    do
        for compiler in "${compiler_types[@]}"
        do
            echo   "
  - name: pr-openenclave-oeedger8r-cmake-${version}-${build_type}-${compiler}
    branches:
    - master
    always_run: true
    decorate: true
    skip_report: false
    max_concurrency: 10
    spec:
      containers:
      - image: openenclave/ubuntu${version}:${docker_version}
        command:
        - /bin/bash
        args:
        - -c
        - '/hack/cmake-build.sh -b=${build_type} --compiler=${compiler}'"
        done
    done
done
