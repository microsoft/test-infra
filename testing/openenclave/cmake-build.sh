#!/usr/bin/env bash

set -ex
##====================================================================================
##
## Default run with no parameters builds with Debug build-type
##
## Run this from the root of the test-infra image.
## Please note that this script does not install any packages needed for build/test.
## Please install all packages necessary for your test before invoking this script.
##
## For CI runs, the Docker image will contain the necessary packages.
##
##====================================================================================
if [[ $1 == "-h" || $1 == "--help" ]]; then
   echo "Script to fire OE build and test with specified platform/build-type/test mode" 
   echo " Usage: "
   echo " ./testing/openenclave/cmake-build.sh.sh"
   echo "        -b Debug|RelWithDebInfo|Release or -b=Debug|RelWithDebInfo|Release"
   echo "        -h or --help to Display usage and exit"
   echo "        --compiler=[clang-7,clang-8,gcc] to build with a specified compiler"
   echo "        --build_package to Build a .deb package after testing"
   echo "        --install_package to install a .deb package after testing"
   echo "        --test_package to test the installed package"
   echo "        --enable_snmalloc builds with snmalloc"
   echo "        --simulation_mode to run in simulation mode"
   echo "        --hardware_mode to run in hardware mode"
   echo "        --enable_full_libcxx_tests to Enable libcxx tests"
   echo "        --enable_lvi_mitigation to Enable lvi mitigation"
   echo "        --enable_full_libc_tests to Enable libc tests"
   echo "        --ninja to build with ninja"
   echo ""
   exit 0
fi

# Valid BUILDTYPE values are Debug|Release|RelWithDebInfo
BUILD_TYPE="Debug"
# Build a package. Default is enabled
BUILD_PACKAGE=1
# Instal directory for package build
OE_INSTALL_DIR="/opt/openenclave"
# Flag for enabling full libcxx tests.
ENABLE_FULL_LIBCXX_TESTS=0
# Valid COMPILER_VALUE inputs are clang-7|gcc
COMPILER_VALUE="clang-8"
# Install a package. Default is enabled
INSTALL_PACKAGE=1
# Test a package. Default is enabled
TEST_PACKAGE=1
# Run in simulation mode. Default is disabled
SIMULATION_MODE=1
# build with ninja. Defailt is disabled
NINJA=0
# build with lvi mitigation. Defailt is disabled
LVI_MITIGATION=0
# build with snmalloc. Defailt is disabled
SNMALLOC=0
# Hack to allow scripts to run locally and in a container
if ! [ -f /.dockerenv ]; then
    echo SUDO=sudo
fi

# Parse the command line - keep looping as long as there is at least one more argument
while [[ $# -gt 0 ]]; do
    key=$1
    case $key in
        # This is a flag type option. Will catch --enable_lvi_mitigation 
        --enable_lvi_mitigation )
        LVI_MITIGATION=1
        ;;
        # This is a flag type option. Will catch --ninja 
        --ninja )
        NINJA=1
        ;;
        # This is a flag type option. Will catch --test_package 
        --test_package )
        TEST_PACKAGE=1
        ;;
        # This is a flag type option. Will catch --install_package
        --install_package)
        INSTALL_PACKAGE=1
        ;;
        # This is a flag type option. Will catch --simulation_mode
        --simulation_mode)
        SIMULATION_MODE=1
        ;;
        # This is a flag type option. Will catch --hardware_mode
        --hardware_mode)
        SIMULATION_MODE=0
        ;;
        # This is a flag type option. Will catch --build_package
        --build_package)
        BUILD_PACKAGE=1
        ;;
        # This is a flag type option. Will catch --enable_snmalloc
        --enable_snmalloc)
        SNMALLOC=1
        ;;
        # This is an arg value type option. Will catch -b value or --build_type value
        -b|--build_type)
        shift # past the key and to the value
        BUILD_TYPE=$1
        ;;
        --compiler=*)
        COMPILER_VALUE="${key#*=}"
        ;;
        # This is an arg=value type option. Will catch -b=value or --build_type=value
        -b=*|--build_type=*)
        # No need to shift here since the value is part of the same string
        BUILD_TYPE="${key#*=}"
        ;;
        --enable_full_libcxx_tests)
        ENABLE_FULL_LIBCXX_TESTS=1
        ;;
        *)
        echo "Unknown option '${key}'"
        exit 1
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

if [[ ${BUILD_TYPE} != "Debug" && ${BUILD_TYPE} != "Release" && ${BUILD_TYPE} != "RelWithDebInfo" ]]; then
   echo "Invalid value for ${BUILD_TYPE}"
   exit 1
fi

# Delete the build directory if it exists. This allows calling this script iteratively
# for multiple configurations for a platform.
if [[ -d ./build ]]; then
  ${SUDO} rm -rf ./build 
fi

mkdir build && cd build || exit 1

CMAKE="cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"

if [[ ${BUILD_PACKAGE} -eq 1 ]]; then
    CMAKE+=" -DCMAKE_INSTALL_PREFIX=${OE_INSTALL_DIR} -DCPACK_GENERATOR=DEB"
fi
if [[ ${NINJA} -eq 1 ]]; then
    CMAKE+=" -G Ninja"
fi
if [[ ${ENABLE_FULL_LIBCXX_TESTS} -eq 1 ]]; then
    CMAKE+=" -DENABLE_FULL_LIBCXX_TESTS=1"
fi
if [[ ${LVI_MITIGATION} -eq 1 ]]; then
    CMAKE+=" -DLVI_MITIGATION_BINDIR=/usr/local/lvi-mitigation/bin -DLVI_MITIGATION_SKIP_TESTS=OFF"
fi
if [[ ${SNMALLOC} -eq 1 ]]; then
    CMAKE+=" -DUSE_SNMALLOC=ON"
fi

echo "CMake command is '${CMAKE}'"

if [[ ${COMPILER_VALUE} == "gcc" ]]; then
    export CC="gcc"
    export CXX="g++"
elif [[ ${COMPILER_VALUE} == "clang-8" ]]; then
    export CC="clang-8"
    export CXX="clang++-8"
elif [[ ${COMPILER_VALUE} == "clang-7" ]]; then
    export CC="clang-7"
    export CXX="clang++-7"
fi

if ! ${CMAKE}; then
    echo ""
    echo "cmake failed"
    echo ""
    exit 1
fi

if [[ ${NINJA} -eq 1 ]]; then
    if ! ninja; then
        echo ""
        echo "Build failed"
        echo ""
        exit 1
    fi 
else
    if ! make; then
        echo ""
        echo "Build failed"
        echo ""
        exit 1
    fi 
fi

# Finally run the tests in simulation or on Hardware
if [[ ${SIMULATION_MODE} -eq 1 ]]; then
    SIMULATION_MODE_TEXT="simulation"
    export OE_SIMULATION=1
fi

if ! ctest --output-on-failure; then
    echo ""
    echo "Test failed for ${SIMULATION_MODE_TEXT} ${COMPILER_VALUE} ${BUILD_TYPE} ${SIMULATION_MODE_TEXT}"
    echo ""
    exit 1
fi

if [[ ${BUILD_PACKAGE} -eq 1 ]]; then
    echo "Building package"
    echo ""
    if [[ ${NINJA} -eq 1 ]]; then
        ninja -v
        ninja -v package
    else
        ${SUDO} make package
    fi
fi

if [[ ${INSTALL_PACKAGE} -eq 1 ]]; then
    echo "Installing package"
    echo ""
    if [[ ${NINJA} -eq 1 ]]; then
        ${SUDO} ninja -v install
    else
        ${SUDO} make install
    fi
fi

if [[ ${TEST_PACKAGE} -eq 1 ]] && [[ ${SIMULATION_MODE} -eq 1 ]]; then
    echo "Testing package installation"
    echo ""
    if [[ -d ~/samples ]]; then
        ${SUDO} rm -rf ~/samples 
    fi
    cp -r /opt/openenclave/share/openenclave/samples ~/
    cd ~/samples
    source /opt/openenclave/share/openenclave/openenclaverc
    for i in * 
    do
        if [ -d ${i} ]; then
            cd ${i}
            mkdir build
            cd build
            cmake ..
            make
            make run
            cd ../..
        fi
    done
fi
