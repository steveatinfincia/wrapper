@echo off

setlocal enabledelayedexpansion

ECHO Building release for %TARGET% (%TOOLSET%-%CONFIGURATION%)

set SRC_PREFIX=%cd%\src
mkdir "%SRC_PREFIX%"
mkdir build

set DIST_PREFIX=%cd%\dist\%TARGET%\%TOOLSET%\%CONFIGURATION%

del /q "%DIST_PREFIX%"

mkdir "%DIST_PREFIX%" > NUL
mkdir "%DIST_PREFIX%\lib" > NUL
mkdir "%DIST_PREFIX%\include" > NUL
mkdir "%DIST_PREFIX%\bin" > NUL

IF "!ARCH!"=="x64" (
    set BITS=64
)

IF "!ARCH!"=="x86" (
    set BITS=32
)

pushd "%SRC_PREFIX%"

IF NOT EXIST wrapper_%WRAPPER_VERSION%_src.tar.gz (
    @echo downloading wrapper source
    curl -L https://wrapper.tanukisoftware.com/download/%WRAPPER_VERSION%/wrapper_%WRAPPER_VERSION%_src.tar.gz -o wrapper_%WRAPPER_VERSION%_src.tar.gz
)

popd

IF NOT EXIST "%SRC_PREFIX%\wrapper_%WRAPPER_VERSION%_src.tar.gz" goto :error

@echo checking source tarball sha256

@powershell -Command "$rhs = ($env:WRAPPER_SHA256); $rhslower = ($rhs).toLower(); $fileHash = Get-FileHash -Path %SRC_PREFIX%\wrapper_%WRAPPER_VERSION%_src.tar.gz; $hslower = ($fileHash.Hash).ToLower(); if(($hslower) -ne ($rhslower)) { Write-Output \"SHA256 does not match: $hslower \"; exit 1; } else { Write-Output \"SHA256 OK: $hslower\"; exit 0; }" || goto :error

pushd build

@echo unpacking wrapper source

del /q wrapper_%WRAPPER_VERSION%_src

7z x -y "%SRC_PREFIX%\wrapper_%WRAPPER_VERSION%_src.tar.gz"> NUL || goto :error
7z x -y "wrapper_%WRAPPER_VERSION%_src.tar"> NUL || goto :error

pushd wrapper_%WRAPPER_VERSION%_src

@echo copying customized makefiles

copy /y "..\..\makefiles\Makefile-windows-x86-64.nmake" "src\c" || goto :error

@echo patching build.xml

@powershell -Command "(Get-content build.xml) | Foreach-Object {$_ -replace 'Windows Server 2012', 'Windows Server 2012 R2'} | Set-Content build.xml"

@echo building wrapper

call "%ANT_HOME%\bin\ant.bat" -f "build.xml"  -Dbits=!BITS! %1 %2 %3 %4 %5 %6 %7 %8

ECHO Copying build artifacts for %TARGET% (%TOOLSET%-%CONFIGURATION%)

ECHO copying "lib\wrapper.dll" "%DIST_PREFIX%\lib\"
copy /y "lib\wrapper.dll" "%DIST_PREFIX%\lib\" || goto :error

ECHO copying "lib\wrapper.jar" "%DIST_PREFIX%\lib\"
copy /y "lib\wrapper.jar" "%DIST_PREFIX%\" || goto :error

ECHO copying "bin\wrapper.exe" "%DIST_PREFIX%\bin\"
copy /y "bin\wrapper.exe" "%DIST_PREFIX%\bin\" || goto :error

del /q wrapper_%WRAPPER_VERSION%_src

popd
popd

goto :EOF

:error
echo Failed with error #!errorlevel!.
exit /b !errorlevel!
