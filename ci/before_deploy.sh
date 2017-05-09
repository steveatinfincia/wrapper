#!/usr/bin/env bash

# `before_deploy` phase: here we package the build artifacts

set -ex

mk_tarball() {
    echo building release tarball
    pwd
    pushd dist/$TARGET/
    tar -zcf ../../${PROJECT_NAME}-${TRAVIS_TAG}-${TARGET}.tar.gz *
    ls -la .
    pwd
    popd
    ls -la .
    pwd
}

main() {
    rvm get head || true
    rvm reload
    mk_tarball
}

main
