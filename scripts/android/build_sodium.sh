#!/bin/sh

. ./config.sh
SODIUM_SRC_DIR=${WORKDIR}/libsodium
SODIUM_BRANCH=1.0.16

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=${WORKDIR}/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}-${arch}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	) TARGET="arm";;
	"i686"		) TARGET="x86";;
	*		) TARGET="${arch}";;
esac  

HOST="${TARGET}-linux-android"
cd $WORKDIR
rm -rf $SODIUM_SRC_DIR
git clone https://github.com/jedisct1/libsodium.git $SODIUM_SRC_DIR -b $SODIUM_BRANCH
cd $SODIUM_SRC_DIR
./autogen.sh || exit 1
CC=clang CXX=clang++ ./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared || exit 1
make -j$THREADS || exit 1
make install || exit 1

done

