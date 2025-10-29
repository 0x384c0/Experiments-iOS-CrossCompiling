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
set -e
SCHEME_NAME="TestSDK"
FRAMEWORK_NAME="TestSDK"

BUILD_DIR="./build"
	
SIMULATOR_ARCHIVE_PATH="${BUILD_DIR}/${FRAMEWORK_NAME}-iphonesimulator.xcarchive"
DEVICE_ARCHIVE_PATH="${BUILD_DIR}/${FRAMEWORK_NAME}-iphoneos.xcarchive"
	
OUTPUT_DIR="./archive/"

info "Print Xcode Environment"

xcodebuild -version
xcodebuild -showsdks
	
info "Simulator xcarchive (arm64 + x86_64)"

xcodebuild archive \
	-scheme ${SCHEME_NAME} \
	-project "${SCHEME_NAME}.xcodeproj" \
	-archivePath ${SIMULATOR_ARCHIVE_PATH} \
	-destination "generic/platform=iOS Simulator" \
	-sdk iphonesimulator \
	ARCHS="arm64 x86_64" \
	VALID_ARCHS="arm64 x86_64" \
	CODE_SIGNING_ALLOWED=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	SKIP_INSTALL=NO | xcpretty

	
info "Device xcarchive (arm64)"

xcodebuild archive \
	-scheme ${SCHEME_NAME} \
	-project "${SCHEME_NAME}.xcodeproj" \
	-archivePath ${DEVICE_ARCHIVE_PATH} \
	-destination "generic/platform=iOS" \
	-sdk iphoneos \
	CODE_SIGNING_ALLOWED=NO \
	BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
	SKIP_INSTALL=NO | xcpretty
	
info "Clean-up existing xcframework from the ${OUTPUT_DIR} directory"
rm -rf "${OUTPUT_DIR}${SCHEME_NAME}.xcframework"
	
info "Create final xcframework"
xcodebuild -create-xcframework \
	-framework ${DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
	-framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework \
	-output ${OUTPUT_DIR}${FRAMEWORK_NAME}.xcframework | xcpretty

banner "Framework created at ${OUTPUT_DIR}${FRAMEWORK_NAME}.xcframework"
