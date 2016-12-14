#! /bin/sh
# Script to setup the build env, it it called by travis-ci and vagrant
#
# The script emits some output, as it's *very* interesting to have it, and
# travis is clever enough to collapse it


if [ $TRAVIS_OS_NAME = "osx" ]
then
	brew update && brew install sdl2 xz
fi

if [ $TRAVIS_OS_NAME = "linux" ]
then
	# Adding the correct toolchain
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y

	if [ $CXX = "clang++" ]
	then
		wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add -
		[ $BUILD_TYPE != "Sanitize" ] && export TIDY=true
	fi

	sudo apt-get update

	if [ $CXX = "clang++" ]
	then
		sudo apt-get install clang-3.9 --force-yes -y
		CXX="clang++-3.9"
		CC="clang-3.9"


	else
		# GCC
		sudo apt-get install g++-5 -y
		CXX="g++-5"
		CC="cc-5"
	fi

	sudo apt-get install libunwind8-dev libsdl2-dev libboost-locale-dev libboost-filesystem-dev libboost-program-options-dev -y
fi

[ "${TIDY}" = "true" ] && sudo apt-get install clang-tidy-3.9 clang-format-3.9 clang-3.9 --force-yes -y

# Setting up ccache if it is in $PATH
if [ command -v ccache >/dev/null 2>&1 ]
then
	ccache -M 1G
	ccache -s
	CC="ccache $CC"
	CXX="ccache $CXX"
PKG_CONFIG_PATH=~/dependency-prefix/lib/pkgconfig

# Debug
${CXX} --version
${CC} --version

mkdir -p ~/dependency-prefix
export PKG_CONFIG_PATH=~/dependency-prefix/lib/pkgconfig

# Installing the glm dep
(
	cd dependencies/glm
	cmake -DCMAKE_INSTALL_PREFIX=~/dependency-prefix . && make && make install
)

# Download the cd_minimal.iso.xz that is just enough for the build
wget http://s2.jonnyh.net/pub/cd_minimal.iso.xz -O data/cd.iso.xz
xz -d data/cd.iso.xz

# setup some default settings
export LSAN_OPTIONS="exitcode=0"
export NUM_CORES=$(grep '^processor' /proc/cpuinfo|wc -l)
# Try to ignore hyperthreading
export NUM_REAL_CORES=$(grep '^core id' /proc/cpuinfo|sort -u|wc -l)
echo "Num cores ${NUM_CORES} Real cores ${NUM_REAL_CORES}"

export CFLAGS="-Wall -Wextra" CXXFLAGS="-Wall -Wextra"

$(which time) cmake . -DGLM_INCLUDE_DIR=~/dependency-prefix/include -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCLANG_TIDY=clang-tidy-3.9 -DCLANG_FORMAT=clang-format-3.9 -DENABLE_TESTS=ON -DCMAKE_C_FLAGS="${CFLAGS}" -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DENABLE_COTIRE=OFF

# Do the format before the script so the output is cleaner - just showing the diff (if any) and the tidy results
if [ "${TIDY}" = "true" ]; then make format -j2 > /dev/null; fi

# Start an X server to run tests on
if [ $TRAVIS_OS_NAME = "linux" ] ; then export DISPLAY=:99.0 ; fi
if [ $TRAVIS_OS_NAME = "linux" ] ; then sh -e /etc/init.d/xvfb start ; fi

# give xvfb some time to start
if [ $TRAVIS_OS_NAME = "linux" ] ; then sleep 3 ; fi

# Create the GameState as that triggers the generated source commands
$(which time) make -j2 && `which time` ctest -V -j 2 && git --no-pager diff --ignore-submodules --stat
if [ "${TIDY}" = "true" ]; then $(which time) make tidy; fi
if [ $TRAVIS_OS_NAME = "linux" ]; then ccache -s; fi
