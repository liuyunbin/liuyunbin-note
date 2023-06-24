#!/usr/bin/env bash

set -x

SOURCE_DIR=`pwd`
BUILD_DIR=${BUILD_DIR:-${SOURCE_DIR}/build}
BUILD_TYPE=${BUILD_TYPE:-debug}
INSTALL_DIR=${INSTALL_DIR:-${BUILD_DIR}/${BUILD_TYPE}-install}

mkdir -p ${BUILD_DIR}/${BUILD_TYPE} \
  && cd  ${BUILD_DIR}/${BUILD_TYPE} \
  && cmake \
           -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
           -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
           $SOURCE_DIR \
  && make $*

