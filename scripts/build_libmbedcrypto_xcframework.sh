# logging
function banner {
	echo ""
	echo "$(tput setaf 5; tput bold;)######## $1 #######$(tput sgr0)"
	echo ""
}
function warning {
	echo "$(tput setaf 3; tput bold;)WARNING: $1$(tput sgr0)"
}
function info {
	echo "$(tput setaf 2; tput bold;)INFO: $1$(tput sgr0)"
}
function error {
	echo "$(tput setaf 1; tput bold;)ERROR: $1$(tput sgr0)"
	exit 1
}

# xcpretty
if ! command -v xcpretty &> /dev/null; then
    alias xcpretty="cat"  # If xcpretty is not installed, use cat (no formatting)
fi

# main

mkdir -p "./build/mbedtls"
cd "./build/mbedtls"

rm -rf bin lib src

VERSION="3.4.0"
SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)

CURRENTPATH=$(pwd)
ARCHS_AND_PLATFORMS="arm64|iPhoneOS  arm64|iPhoneSimulator x86_64|iPhoneSimulator"
DEVELOPER=$(xcode-select -print-path)

##########
set -e
if [ ! -e "v${VERSION}.zip" ]; then
    info "Downloading v${VERSION}.zip"
    curl -OsL https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/v${VERSION}.zip
else
    info "Using v${VERSION}.zip"
fi

mkdir -p bin/iPhoneOS
mkdir -p bin/iPhoneSimulator
mkdir -p lib/iPhoneOS
mkdir -p lib/iPhoneSimulator
mkdir -p src

for ARCH_AND_PLATFORM in ${ARCHS_AND_PLATFORMS}; do
    ARCH=$(echo "${ARCH_AND_PLATFORM}" | cut -d'|' -f1)
    PLATFORM=$(echo "${ARCH_AND_PLATFORM}" | cut -d'|' -f2)

    rm -rf src/mbedtls-${VERSION}

    unzip "v${VERSION}.zip" -d src > /dev/null
    cd src/mbedtls-${VERSION}/library

    banner "Building mbedtls for  ARCH: $ARCH PLATFORM: $PLATFORM SDKVERSION: $SDKVERSION"

    info "Patching Makefile..."
    sed -i.bak '4d' ${CURRENTPATH}/src/mbedtls-${VERSION}/library/Makefile

    export DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
    export BUILD_TOOLS="${DEVELOPER}"
    export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH} -Qunused-arguments"
    export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT}"
    export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I${CURRENTPATH}/src/mbedtls-${VERSION}/include"

    info "Building library"

    make

    cp libmbedcrypto.a ${CURRENTPATH}/bin/${PLATFORM}/libmbedcrypto-${ARCH}.a
    cp -R ${CURRENTPATH}/src/mbedtls-${VERSION}/include ${CURRENTPATH}
    cp ${CURRENTPATH}/src/mbedtls-${VERSION}/LICENSE ${CURRENTPATH}/include/mbedtls/LICENSE
    cd ${CURRENTPATH}

done

info "Building xcframework"

lipo -create $(find ${CURRENTPATH}/bin/iPhoneOS -name "libmbedcrypto-*.a") -output ${CURRENTPATH}/lib/iPhoneOS/libmbedcrypto.a
lipo -create $(find ${CURRENTPATH}/bin/iPhoneSimulator -name "libmbedcrypto-*.a") -output ${CURRENTPATH}/lib/iPhoneSimulator/libmbedcrypto.a

xcodebuild -create-xcframework \
    -output ${CURRENTPATH}/lib/libmbedcrypto.xcframework \
    -library ${CURRENTPATH}/lib/iPhoneOS/libmbedcrypto.a \
    -headers ${CURRENTPATH}/include \
    -library ${CURRENTPATH}/lib/iPhoneSimulator/libmbedcrypto.a \
    -headers ${CURRENTPATH}/include | xcpretty

banner "Building done."

cd ../..

mkdir -p "Frameworks"
if [ -d "Frameworks" ]; then
    rm -rf "Frameworks/libmbedcrypto.xcframework"
fi

info "Copying xcframework to Frameworks"

mv ${CURRENTPATH}"/lib/libmbedcrypto.xcframework" "Frameworks/"
