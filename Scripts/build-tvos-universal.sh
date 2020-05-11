#!/bin/sh
set -e

# Helper variables
WORK_DIR=build
DEVICE_SDK="appletvos"
SIMULATOR_SDK="appletvsimulator"
TARGET_NAME="${PROJECT_NAME} tvOS Framework"
DEVICE_DIR="${BUILD_DIR}/${CONFIGURATION}-${DEVICE_SDK}"
SIMULATOR_DIR="${BUILD_DIR}/${CONFIGURATION}-${SIMULATOR_SDK}"
LIBRARY_BINARY="lib${PRODUCT_NAME}.a"
FRAMEWORK_BINARY="${PRODUCT_NAME}.framework/${PRODUCT_NAME}"

# The directory to gather all frameworks and build it into xcframework.
XCFRAMEWORK_DIR="${WORK_DIR}/xcframework"

# Building both SDKs
build() {
    # Print only target name and issues. Mimic Xcode output to make prettify tools happy.
    echo "=== BUILD TARGET $1 OF PROJECT ${PROJECT_NAME} WITH CONFIGURATION ${CONFIGURATION} ==="
    # OBJROOT must be customized to avoid conflicts with the current process.
    xcodebuild -quiet \
    PROJECT_TEMP_DIR="${PROJECT_TEMP_DIR}" \
        ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS="-fembed-bitcode" \
        -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -target "$1" -sdk "$2"
}
echo "Building the library for ${DEVICE_SDK} and ${SIMULATOR_SDK}..."
build "${TARGET_NAME}" "${DEVICE_SDK}"
build "${TARGET_NAME}" "${SIMULATOR_SDK}"

# Copy all framework files to use them for xcframework file creation.
mkdir -p "${XCFRAMEWORK_DIR}"
cp -R "${WORK_DIR}/Release-${DEVICE_SDK}/" "${XCFRAMEWORK_DIR}/Release-${DEVICE_SDK}"
cp -R "${WORK_DIR}/Release-${SIMULATOR_SDK}/" "${XCFRAMEWORK_DIR}/Release-${SIMULATOR_SDK}"

# Clean output folder
rm -rf "${BUILT_PRODUCTS_DIR}"
mkdir -p "${BUILT_PRODUCTS_DIR}"

# Combine libraries and frameworks
echo "Combining libraries..."
lipo \
    "${DEVICE_DIR}/${LIBRARY_BINARY}" \
    "${SIMULATOR_DIR}/${LIBRARY_BINARY}" \
    -create -output "${BUILT_PRODUCTS_DIR}/${LIBRARY_BINARY}"
echo "Final library architectures: $(lipo -archs "${BUILT_PRODUCTS_DIR}/${LIBRARY_BINARY}")"

# Frameworks contains additional linker data and should be processed separately.
echo "Combining frameworks..."
cp -R "${DEVICE_DIR}/${PRODUCT_NAME}.framework" "${BUILT_PRODUCTS_DIR}"
lipo \
    "${BUILT_PRODUCTS_DIR}/${FRAMEWORK_BINARY}" \
    "${SIMULATOR_DIR}/${FRAMEWORK_BINARY}" \
    -create -output "${BUILT_PRODUCTS_DIR}/${FRAMEWORK_BINARY}"
echo "Final framework architectures: $(lipo -archs "${BUILT_PRODUCTS_DIR}/${FRAMEWORK_BINARY}")"

echo "Appending simulator to Info.plist"
plutil -insert CFBundleSupportedPlatforms.1 -string "AppleTVSimulator" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/Info.plist"
