#! /bin/sh
# Script to setup the build env, it it called by travis-ci and vagrant
#
# The script emits some output, as it's *very* interesting to have it, and
# travis is clever enough to collapse it

# Failing *FAST*
set -e

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

	sudo apt-get update -qq

	if [ $CXX = "clang++" ]
	then
		sudo apt-get install clang-3.9 --force-yes -yqq
		CXX="clang++-3.9"
		CC="clang-3.9"


	else
		# GCC
		sudo apt-get install g++-5 -yqq
		CXX="g++-5"
		CC="cc-5"
	fi

	sudo apt-get install libunwind8-dev libsdl2-dev libboost-locale-dev libboost-filesystem-dev libboost-program-options-dev -yqq
fi

[ "${TIDY}" = "true" ] && sudo apt-get install clang-tidy-3.9 clang-format-3.9 clang-3.9 --force-yes -yqq

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
