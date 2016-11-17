#!/bin/sh

# build_lipo.sh
# build an arm64 / armv7s / armv7 / i386 / x86_64 lib of fftw3
# make sure to check that all the paths used in this script exist on your system
#
# adopted from:
# http://robertcarlsen.net/2009/07/15/cross-compiling-for-iphone-dev-884
# changed by Adam
# original: by Nickun
# http://stackoverflow.com/questions/3588904/how-to-link-third-party-libraries-like-fftw3-and-sndfile-to-an-iphone-project-in

# fftw-3.3.5

# this is the folder where the results of our efforts will end up:
export RESULT_DIR=ios-library

# Select toolchains folder
export XCODE_TOOLCHAINS=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
# Select the desired iPhone SDK
export DEVROOT_IOS=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
export SDKROOT_IOS=$DEVROOT_IOS/SDKs/iPhoneOS.sdk
# Select the OSX SDK
export DEVROOT_OSX=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer
export SDKROOT_OSX=$DEVROOT_OSX/SDKs/MacOSX10.11.sdk

# ------------------------ i386 ---------------------------
echo "------------------------ i386 ---------------------------"
# Do it for i386
make clean

# Restore default environment variables
unset CPPFLAGS CFLAGS CPP CC LD CXX LDFLAGS CXXFLAGS

export CFLAGS="-arch i386"

# TODO: error checking
./configure --host=i386-apple-darwin9.2.0 --target=i386-apple-darwin9.2.0
make -j2

# Copy the FAT native library to a temporary location
mkdir $RESULT_DIR
cp .libs/libfftw3.a $RESULT_DIR/libfftw3_i386.a
rm -fr .libs/libfftw3.a

# ------------------------ x86_64 ---------------------------
echo "------------------------ x86_64 ---------------------------"
# Do it all again for x86_64
make clean

# Restore default environment variables
unset CPPFLAGS CFLAGS CPP CC LD CXX LDFLAGS CXXFLAGS

# TODO: error checking
./configure
make -j2

# Copy the FAT native library to the temporary location
cp .libs/libfftw3.a $RESULT_DIR/libfftw3_x86_64.a
rm -fr .libs/libfftw3.a

# ------------------------ armv7---------------------------
echo "------------------------ armv7 ---------------------------"
# Do it all again for armv7
make clean

# Restore default environment variables
unset CPPFLAGS CFLAGS CPP LD CXX CC LDFLAGS CXXFLAGS

# Set up relevant environment variables
export CPPFLAGS="-I$SDKROOT_IOS/usr/include/ "
export CFLAGS="$CPPFLAGS -arch armv7  -no-cpp-precomp -miphoneos-version-min=6.1 -isysroot $SDKROOT_IOS"
export LD=$XCODE_TOOLCHAINS/usr/bin/ld
export CXX="$XCODE_TOOLCHAINS/usr/bin/clang -x c++ -arch armv7 -std=gnu++11 -stdlib=libc++ "
export CC="$XCODE_TOOLCHAINS/usr/bin/clang -x c -arch armv7 -std=gnu99 "
export CXXFLAGS="$CFLAGS"

# TODO: add custom flags as necessary for package
#  remove '--enable-float' for double precision
#  and take a 'libfftw3.a' file instead
./configure --host=arm-apple-darwin --target=arm-apple-darwin

make -j2

cp .libs/libfftw3.a $RESULT_DIR/libfftw3_armv7.a
rm -fr .libs/libfftw3.a

# Copy the header file too, just for convenience
cp api/fftw3.h $RESULT_DIR/fftw3.h

# ------------------------ armv7s---------------------------
echo "------------------------ armv7s ---------------------------"
# Do it all again for i386
make clean

# Restore default environment variables
unset CPPFLAGS CFLAGS CPP LD CXX CC LDFLAGS CXXFLAGS

# Set up relevant environment variables
export CPPFLAGS="-I$SDKROOT_IOS/usr/include/ "
export CFLAGS="$CPPFLAGS -arch armv7s  -no-cpp-precomp -miphoneos-version-min=6.1 -isysroot $SDKROOT_IOS"
export LD=$XCODE_TOOLCHAINS/usr/bin/ld
export CXX="$XCODE_TOOLCHAINS/usr/bin/clang -x c++ -arch armv7s -std=gnu++11 -stdlib=libc++ "
export CC="$XCODE_TOOLCHAINS/usr/bin/clang -x c -arch armv7s -std=gnu99 "
export CXXFLAGS="$CFLAGS"

# TODO: add custom flags as necessary for package
#  remove '--enable-float' for double precision
#  and take a 'libfftw3.a' file instead
./configure --host=arm-apple-darwin --target=arm-apple-darwin

make -j2

# Copy the ARM library to a temporary location
cp .libs/libfftw3.a $RESULT_DIR/libfftw3_armv7s.a
rm -fr .libs/libfftw3.a

# ------------------------ arm64 ---------------------------
echo "------------------------ arm64 ---------------------------"
# Do it all again for arm64
make clean

# Restore default environment variables
unset CPPFLAGS CFLAGS CPP LD CXX CC LDFLAGS CXXFLAGS

# Set up relevant environment variables
export CPPFLAGS="-I$SDKROOT_IOS/usr/include/ "
export CFLAGS="$CPPFLAGS -arch arm64  -no-cpp-precomp -miphoneos-version-min=6.1 -isysroot $SDKROOT_IOS"
export LD=$XCODE_TOOLCHAINS/usr/bin/ld
export CXX="$XCODE_TOOLCHAINS/usr/bin/clang -x c++ -arch arm64 -std=gnu++11 -stdlib=libc++ "
export CC="$XCODE_TOOLCHAINS/usr/bin/clang -x c -arch arm64 -std=gnu99 "
export CXXFLAGS="$CFLAGS"

# TODO: add custom flags as necessary for package
#  remove '--enable-float' for double precision
#  and take a 'libfftw3.a' file instead
./configure --host=arm-apple-darwin --target=arm-apple-darwin

make -j2

# Copy the ARM library to a temporary location
cp .libs/libfftw3.a ios-library/libfftw3_arm64.a
rm -fr .libs/libfftw3.a

# Create fat lib by combining the two versions
echo "------------------------ Create fat lib by combining the two versions ---------------------------"
lipo -arch armv7 $RESULT_DIR/libfftw3_armv7.a -arch armv7s $RESULT_DIR/libfftw3_armv7s.a -arch i386 $RESULT_DIR/libfftw3_i386.a -arch x86_64 $RESULT_DIR/libfftw3_x86_64.a -arch arm64 $RESULT_DIR/libfftw3_arm64.a -create -output $RESULT_DIR/libfftw3.a

# Remove intermediate binaries
#rm $RESULT_DIR/libfftw3_armv7.a
#rm $RESULT_DIR/libfftw3_i386.a
#rm $RESULT_DIR/libfftw3_x86_64.a

# Unset used environment variables
unset CPPFLAGS CFLAGS CPP LD LDFLAGS CC CXX CXXFLAGS