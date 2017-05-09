#!/usr/bin/env bash

set -e

echo "Building release for ${TARGET}"

export DIST_PREFIX=$PWD/dist/${TARGET}

export CFLAGS="-O3 -fPIC -Wall --pedantic"
export CPPFLAGS="-O3 -fPIC -Wall --pedantic"
export LDFLAGS=""

export MACOSX_DEPLOYMENT_TARGET=10.9
export OSX_VERSION_MIN="10.9"
export OSX_CPU_ARCH="core2"
export MAC_ARGS="-arch x86_64 -mmacosx-version-min=${OSX_VERSION_MIN} -march=${OSX_CPU_ARCH}"

case ${TARGET} in
    x86_64-apple-darwin)
        export CFLAGS="${CFLAGS} ${MAC_ARGS}"
        export CPPFLAGS="${CPPFLAGS} ${MAC_ARGS}"
        export LDFLAGS="${LDFLAGS} ${MAC_ARGS}"
        export CC=clang
        export BITS=64
        export JAVA_HOME=$(/usr/libexec/java_home)
        ;;
    x86_64-unknown-linux-gnu)
        export CFLAGS="${CFLAGS}"
        export CPPFLAGS="${CPPFLAGS}"
        export LDFLAGS="${LDFLAGS}"
        export CC=gcc
        export BITS=64
        ;;
    i686-unknown-linux-gnu)
        export CFLAGS="${CFLAGS} -m32"
        export CPPFLAGS="${CPPFLAGS} -m32"
        export LDFLAGS="${LDFLAGS}"
        export CC=gcc
        export BITS=32
        ;;
    arm64-unknown-linux-gnu)
        export CFLAGS="${CFLAGS}"
        export CPPFLAGS="${CPPFLAGS}"
        export LDFLAGS="${LDFLAGS}"
        export CC=aarch64-linux-gnu-gcc
        export BITS=64
        ;;
    armhf-unknown-linux-gnu)
        export CFLAGS="${CFLAGS}"
        export CPPFLAGS="${CPPFLAGS}"
        export LDFLAGS="${LDFLAGS}"
        export CC=arm-linux-gnueabihf-gcc
        export BITS=32
        ;;
esac

mkdir -p src
mkdir -p build
rm -rf ${DIST_PREFIX}
mkdir -p ${DIST_PREFIX}/lib
mkdir -p ${DIST_PREFIX}/include
mkdir -p ${DIST_PREFIX}/bin

pushd src > /dev/null

if [ ! -f wrapper_${WRAPPER_VERSION}_src.tar.gz ]; then
    echo "Downloading wrapper_${WRAPPER_VERSION}_src.tar.gz"
    curl -L https://wrapper.tanukisoftware.com/download/${WRAPPER_VERSION}/wrapper_${WRAPPER_VERSION}_src.tar.gz  -o wrapper_${WRAPPER_VERSION}_src.tar.gz > /dev/null
fi

echo Checking source tarball sha256

HS=$(shasum -a 256 wrapper_${WRAPPER_VERSION}_src.tar.gz | awk '{ print $1 }')

if [ ! ${HS} = ${WRAPPER_SHA256} ]; then
    echo SHA256 does not match: ${HS}
    exit 1
else
    echo SHA256 OK: ${HS}
fi

popd > /dev/null

pushd build > /dev/null
        echo "Building wrappper ${WRAPPER_VERSION} for ${TARGET}"
        rm -rf wrapper*
        tar xf ../src/wrapper_${WRAPPER_VERSION}_src.tar.gz > /dev/null
        pushd wrapper_${WRAPPER_VERSION}_src > /dev/null

            echo "Copying customized makefiles"

            cp -af ../../makefiles/* src/c/

            ant -f "build.xml" -Dbits=${BITS}

            echo "Copying build artifacts for ${TARGET}"

            cp -a bin/wrapper ${DIST_PREFIX}/bin/wrapper
            cp -a lib/wrapper.jar ${DIST_PREFIX}/lib/wrapper.jar

            case ${TARGET} in
                x86_64-apple-darwin)
                    cp -a lib/libwrapper.jnilib ${DIST_PREFIX}/lib/libwrapper.jnilib
                    ;;
                i686-unknown-linux-gnu|x86_64-unknown-linux-gnu|arm64-unknown-linux-gnu|armhf-unknown-linux-gnu)
                    cp -a lib/libwrapper.so ${DIST_PREFIX}/lib/libwrapper.so
                    ;;
                *)
                    ;;
            esac

        popd > /dev/null
        rm -rf wrapper*
popd > /dev/null

