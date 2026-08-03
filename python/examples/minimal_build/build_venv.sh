#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -ex

#----------------------------------------------------------------------
# Change this to whatever makes sense for your system
HOME=/io/dist
WORKDIR=${WORKDIR:-$HOME}
MINICONDA=$WORKDIR/miniconda-for-arrow
LIBRARY_INSTALL_DIR=$WORKDIR/local-libs
CPP_BUILD_DIR=$WORKDIR/arrow-cpp-build
ARROW_ROOT=/arrow
export ARROW_HOME=$WORKDIR/dist
export LD_LIBRARY_PATH=$ARROW_HOME/lib:$LD_LIBRARY_PATH

export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_PARALLEL=4

# Override version to create release build instead of dev build
export SETUPTOOLS_SCM_PRETEND_VERSION=25.0.0

python3 -m venv $WORKDIR/venv
source $WORKDIR/venv/bin/activate

git config --global --add safe.directory $ARROW_ROOT

pip install -r $ARROW_ROOT/python/requirements-build.txt
pip install wheel

#----------------------------------------------------------------------
# Build C++ library

mkdir -p $CPP_BUILD_DIR
pushd $CPP_BUILD_DIR

cmake -GNinja \
      -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_UNITY_BUILD=ON \
      -DARROW_ACERO="ON" \
      -DARROW_BUILD_STATIC="OFF" \
      -DARROW_COMPUTE="ON" \
      -DARROW_CSV="ON" \
      -DARROW_DATASET="ON" \
      -DARROW_FILESYSTEM="ON" \
      -DARROW_GCS="ON" \
      -DARROW_HDFS="ON" \
      -DARROW_JSON="ON" \
      -DARROW_MIMALLOC="ON" \
      -DARROW_ORC="ON" \
      -DARROW_PARQUET="ON" \
      -DARROW_S3="ON" \
      -DARROW_SUBSTRAIT="ON" \
      -DARROW_WITH_BROTLI="ON" \
      -DARROW_WITH_BZ2="ON" \
      -DARROW_WITH_LZ4="ON" \
      -DARROW_WITH_RE2="OFF" \
      -DARROW_WITH_SNAPPY="ON" \
      -DARROW_WITH_UTF8PROC="OFF" \
      -DARROW_WITH_ZLIB="ON" \
      -DARROW_WITH_ZSTD="ON" \
      -DARROW_WITH_UTF8PROC="ON" \
      -DARROW_WITH_BACKTRACE="ON" \
      -DCMAKE_BUILD_TYPE="Release" \
      -DPARQUET_REQUIRE_ENCRYPTION="ON" \
      $ARROW_ROOT/cpp

ninja install

popd

#----------------------------------------------------------------------
# Build Python wheel (Arrow 25+ uses scikit-build-core; no setup.py)
pushd $ARROW_ROOT/python

rm -rf build/  # remove any pesky preexisting build directory

export CMAKE_PREFIX_PATH=${ARROW_HOME}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}
export PYARROW_WITH_GCS=1
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_S3=1
export PYARROW_WITH_ORC=1
export PYARROW_WITH_PARQUET_ENCRYPTION=1
export PYARROW_WITH_HDFS=1
export PYARROW_BUNDLE_ARROW_CPP=ON
export CMAKE_GENERATOR=Ninja

pip install build wheel
python -m build --wheel --no-isolation --outdir "$HOME"

popd
