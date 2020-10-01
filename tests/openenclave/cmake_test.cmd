REM Clean up past workspave
(if exist openenclave rmdir /s/q openenclave)

REM Clone openenclave
git clone --recursive https://github.com/openenclave/openenclave

REM Set up environment
cd openenclave && mkdir build && cd build

REM Configure build
vcvars64.bat && cmake .. -G Ninja -DNUGET_PACKAGE_PATH=C:\Downloads\prereqs\nuget -DCPACK_GENERATOR=NuGet -DCMAKE_BUILD_TYPE=Release -DBUILD_ENCLAVES=ON -DLVI_MITIGATION=None -DHAS_QUOTE_PROVIDER=ON

REM Build
vcvars64.bat && ninja -j 1 -v

REM Test
vcvars64.bat && ctest.exe -V -C Debug --timeout 480

REM Package Hostverify
vcvars64.bat && cpack.exe -D CPACK_NUGET_COMPONENT_INSTALL=ON -DCPACK_COMPONENTS_ALL=OEHOSTVERIFY

REM Package
vcvars64.bat && cpack.exe

REM Remove past install
(if exist C:\\oe rmdir /s/q C:\\oe)

REM Install
nuget.exe install open-enclave -Source %cd%\\openenclave\\build -OutputDirectory C:\\oe -ExcludeVersion

REM Test Package installation
set CMAKE_PREFIX_PATH=C:\\oe\\open-enclave\\openenclave\\lib\\openenclave\\cmake
cd C:\\oe\\open-enclave\\openenclave\\share\\openenclave\\samples
setlocal enabledelayedexpansion
REM #TODO AddSamplesTesting