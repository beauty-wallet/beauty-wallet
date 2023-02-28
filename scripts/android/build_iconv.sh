#!/bin/sh

. ./config.sh
export ICONV_FILENAME=libiconv-1.16.tar.gz
export ICONV_FILE_PATH=$WORKDIR/$ICONV_FILENAME
export ICONV_SRC_DIR=$WORKDIR/libiconv-1.16
ICONV_SHA256="e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"

curl http://ftp.gnu.org/pub/gnu/libiconv/$ICONV_FILENAME -o $ICONV_FILE_PATH
echo $ICONV_SHA256 $ICONV_FILE_PATH | sha256sum -c - || exit 1

for arch in aarch aarch64 i686 x86_64
do

PREFIX=${WORKDIR}/prefix_${arch}

case $arch in
	"aarch"	)
		CLANG=arm-linux-androideabi-clang
 		CXXLANG=arm-linux-androideabi-clang++
		BUILD_64=OFF
		TAG="android-armv7"
		ARCH="armv7-a"
		ARCH_ABI="armeabi-v7a"
		FLAGS="-D CMAKE_ANDROID_ARM_MODE=ON -D NO_AES=true"
		TOOLCHAIN_ARCH=arm
		CRTDIR=arm-linux-androideabi
		;;
	"aarch64"	)
		CLANG=clang
 		CXXLANG=clang++
		BUILD_64=ON
		TAG="android-armv8"
		ARCH="armv8-a"
		ARCH_ABI="arm64-v8a"
		TOOLCHAIN_ARCH=arm64
		CRTDIR=aarch64-linux-android
		;;
	"i686"		)
		CLANG=clang
 		CXXLANG=clang++
		BUILD_64=OFF
		TAG="android-x86"
		ARCH="i686"
		ARCH_ABI="x86"
		TOOLCHAIN_ARCH=x86
		CRTDIR=i686-linux-android
		;;
	"x86_64"	)  
		CLANG=clang
 		CXXLANG=clang++
		BUILD_64=ON
		TAG="android-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64"
		TOOLCHAIN_ARCH=x86_64
		CRTDIR=x86_64-linux-android
		;;
esac

echo "Creating toolchain..."
ANDROID_STANDALONE_TOOLCHAIN_PATH="$TOOLCHAIN_BASE_DIR-${arch}"
PATH="${ANDROID_STANDALONE_TOOLCHAIN_PATH}/bin:${ORIGINAL_PATH}"
#usage: make_standalone_toolchain.py [-h] --arch {arm,arm64,x86,x86_64} [--api API] [--stl {gnustl,libc++,stlport}] [--force] [-v]
#                                    [--package-dir PACKAGE_DIR | --install-dir INSTALL_DIR]
echo python3 $ANDROID_NDK_ROOT/build/tools/make_standalone_toolchain.py --arch $TOOLCHAIN_ARCH --api $ANDROID_APILEVEL --install-dir $ANDROID_STANDALONE_TOOLCHAIN_PATH
python3 $ANDROID_NDK_ROOT/build/tools/make_standalone_toolchain.py --arch $TOOLCHAIN_ARCH --api $ANDROID_APILEVEL --install-dir $ANDROID_STANDALONE_TOOLCHAIN_PATH
echo "Creating toolchain... - done."

CRTDIR_FULL_OPT="-B$ANDROID_STANDALONE_TOOLCHAIN_PATH/sysroot/usr/lib/$CRTDIR/$ANDROID_APILEVEL"
COMMONFLAGS="-v --sysroot=$ANDROID_STANDALONE_TOOLCHAIN_PATH/sysroot -pthread"
CFLAGS="$COMMONFLAGS $CRTDIR_FULL_OPT $CFLAGS"
CXXFLAGS="$COMMONFLAGS $CRTDIR_FULL_OPT $CXXFLAGS"
LDFLAGS="$COMMONFLAGS $CRTDIR_FULL_OPT $LDFLAGS"

case $arch in
	"aarch"	)
        HOST="arm-linux-android"
;;
	*		)
		HOST="${arch}-linux-android"
;;
esac 

cd $WORKDIR
rm -rf $ICONV_SRC_DIR
tar -xzf $ICONV_FILE_PATH -C $WORKDIR
cd $ICONV_SRC_DIR
CC=${CLANG} CXX=${CXXLANG} ./configure --build=x86_64-linux-gnu --host=${HOST} --prefix=${PREFIX} --disable-rpath || exit 1
make -j$THREADS || exit 1
make install || exit 1

done

