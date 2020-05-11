#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
WORK_DIR="${SRCROOT}/build"
XCFRAMEWORK_DIR="${WORK_DIR}/xcframework"
MACOS_DIR="macos"

# Work dir will be the final output to the framework.
XC_FRAMEWORK_PATH="${XCFRAMEWORK_DIR}/Output/${PROJECT_NAME}.xcframework"

# Additionally copy macos files.
cp -R "${BUILD_DIR}/${CONFIGURATION}-${MACOSX_DIR}/" "${XCFRAMEWORK_DIR}/"${CONFIGURATION}"-${MACOS_DIR}"

# Clean previus XCFramework build.
rm -rf ${PROJECT_NAME}.xcframework/

# Build XCFramework.
function SetXcBuildCommandFramework() {
    FRAMEWORK_PATH="$XCFRAMEWORK_DIR/"${CONFIGURATION}"-$1/${PROJECT_NAME}.framework"
    echo $FRAMEWORK_PATH
    [ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH";
}

# Create a cycle instead next lines
SetXcBuildCommandFramework "iphoneos"
SetXcBuildCommandFramework "iphonesimulator"
SetXcBuildCommandFramework "appletvos"
SetXcBuildCommandFramework "appletvsimulator"
SetXcBuildCommandFramework "$MACOS_DIR"

XC_BUILD_COMMAND="xcodebuild -create-xcframework $XC_BUILD_COMMAND -output $XC_FRAMEWORK_PATH"
eval "$XC_BUILD_COMMAND"
