#! /bin/sh
# Script to build, it it called by travis-ci and vagrant
#
# The script emits some output, as it's *very* interesting to have it, and
# travis is clever enough to collapse it

# Failing *FAST*
set -e

# Setting up ccache if it is in $PATH
if [ command -v ccache >/dev/null 2>&1 ]
then
	ccache -M 1G
	ccache -s
	CC="ccache $CC"
	CXX="ccache $CXX"
fi

PKG_CONFIG_PATH=~/dependency-prefix/lib/pkgconfig

# Debug
${CXX} --version
${CC} --version

TIME_BIN=$(which time)

# setup some default settings
export LSAN_OPTIONS="exitcode=0"
export NUM_CORES=$(grep '^processor' /proc/cpuinfo|wc -l)
# Try to ignore hyperthreading
export NUM_REAL_CORES=$(grep '^core id' /proc/cpuinfo|sort -u|wc -l)
echo "Num cores ${NUM_CORES} Real cores ${NUM_REAL_CORES}"

export CFLAGS="-Wall -Wextra" CXXFLAGS="-Wall -Wextra"

$TIME_BIN cmake . -DGLM_INCLUDE_DIR=~/dependency-prefix/include -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCLANG_TIDY=clang-tidy-3.9 -DCLANG_FORMAT=clang-format-3.9 -DENABLE_TESTS=ON -DCMAKE_C_FLAGS="${CFLAGS}" -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DENABLE_COTIRE=OFF

# Do the format before the script so the output is cleaner - just showing the diff (if any) and the tidy results
if [ "${TIDY}" = "true" ]; then make format -j2 > /dev/null; fi

# Create the GameState as that triggers the generated source commands
$TIME_BIN make -j2 && $TIME_BIN ctest -V -j 2 && git --no-pager diff --ignore-submodules --stat
if [ "${TIDY}" = "true" ]; then $(which time) make tidy; fi
if [ $TRAVIS_OS_NAME = "linux" ]; then ccache -s; fi
