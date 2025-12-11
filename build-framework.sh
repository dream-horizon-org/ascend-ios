#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_NAME="Ascend"
PACKAGE_NAME="Ascend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_DIR="$BUILD_DIR/archives"
OUTPUT_DIR="$PROJECT_DIR/output"
XCFRAMEWORK_PATH="$OUTPUT_DIR/${FRAMEWORK_NAME}.xcframework"

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$XCFRAMEWORK_PATH"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$OUTPUT_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required tools
if ! command_exists xcodebuild; then
    echo -e "${RED}Error: xcodebuild is not installed${NC}"
    exit 1
fi

if ! command_exists swift; then
    echo -e "${RED}Error: swift is not installed${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Verify Package.swift exists
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}Error: Package.swift not found in $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Building ${FRAMEWORK_NAME} xcframework...${NC}"
echo ""
echo -e "${YELLOW}Note: For SPM packages, ensure Package.swift can be resolved.${NC}"
echo -e "${YELLOW}If you encounter scheme errors, try opening Package.swift in Xcode first.${NC}"
echo ""

# Build for iOS Device (arm64)
echo -e "${YELLOW}Building for iOS Device (arm64)...${NC}"
set +e
xcodebuild archive \
    -scheme "$PACKAGE_NAME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    SWIFT_COMPILATION_MODE=wholemodule \
    SWIFT_ENABLE_LIBRARY_EVOLUTION=NO \
    -configuration Release \
    2>&1 | grep -v "warning:" | grep -v "note:" || true
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "${RED}Error: Failed to build for iOS device${NC}"
    echo -e "${YELLOW}Tip: Make sure Package.swift is valid and the scheme exists.${NC}"
    echo -e "${YELLOW}Try opening Package.swift in Xcode: open Package.swift${NC}"
    exit 1
fi

# SPM packages install frameworks to usr/local/lib instead of Library/Frameworks
DEVICE_FRAMEWORK="$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS.xcarchive/Products/usr/local/lib/${FRAMEWORK_NAME}.framework"

# Check if framework was created (try alternative location for non-SPM packages)
if [ ! -d "$DEVICE_FRAMEWORK" ]; then
    DEVICE_FRAMEWORK="$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
fi

if [ ! -d "$DEVICE_FRAMEWORK" ]; then
    echo -e "${RED}Error: Failed to create iOS device framework${NC}"
    echo "Checked locations:"
    echo "  - $ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS.xcarchive/Products/usr/local/lib/${FRAMEWORK_NAME}.framework"
    echo "  - $ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    exit 1
fi

echo -e "${GREEN}✓ iOS Device build completed${NC}"
echo ""

# Build for iOS Simulator (arm64 + x86_64)
echo -e "${YELLOW}Building for iOS Simulator (arm64 + x86_64)...${NC}"
set +e
xcodebuild archive \
    -scheme "$PACKAGE_NAME" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    SWIFT_COMPILATION_MODE=wholemodule \
    SWIFT_ENABLE_LIBRARY_EVOLUTION=NO \
    -configuration Release \
    2>&1 | grep -v "warning:" | grep -v "note:" || true
BUILD_STATUS=${PIPESTATUS[0]}
set -e

if [ $BUILD_STATUS -ne 0 ]; then
    echo -e "${RED}Error: Failed to build for iOS Simulator${NC}"
    echo -e "${YELLOW}Tip: Make sure Package.swift is valid and the scheme exists.${NC}"
    echo -e "${YELLOW}Try opening Package.swift in Xcode: open Package.swift${NC}"
    exit 1
fi

# SPM packages install frameworks to usr/local/lib instead of Library/Frameworks
SIMULATOR_FRAMEWORK="$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/usr/local/lib/${FRAMEWORK_NAME}.framework"

# Check if framework was created (try alternative location for non-SPM packages)
if [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
    SIMULATOR_FRAMEWORK="$ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
fi

if [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
    echo -e "${RED}Error: Failed to create iOS Simulator framework${NC}"
    echo "Checked locations:"
    echo "  - $ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/usr/local/lib/${FRAMEWORK_NAME}.framework"
    echo "  - $ARCHIVE_DIR/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"
    exit 1
fi

echo -e "${GREEN}✓ iOS Simulator build completed${NC}"
echo ""

# Create xcframework
echo -e "${YELLOW}Creating xcframework...${NC}"
xcodebuild -create-xcframework \
    -framework "$DEVICE_FRAMEWORK" \
    -framework "$SIMULATOR_FRAMEWORK" \
    -output "$XCFRAMEWORK_PATH"

if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo -e "${RED}Error: Failed to create xcframework${NC}"
    exit 1
fi

echo -e "${GREEN}✓ xcframework created successfully${NC}"
echo ""

# Verify architectures
echo -e "${YELLOW}Verifying architectures...${NC}"

# Check device framework architectures
echo -n "Device architectures: "
lipo -info "$DEVICE_FRAMEWORK/${FRAMEWORK_NAME}" 2>&1 | grep -E "(architecture|are):" | sed 's/.*is architecture: //' | sed 's/.*are: //' || echo "unknown"

# Check simulator framework architectures
echo -n "Simulator architectures: "
lipo -info "$SIMULATOR_FRAMEWORK/${FRAMEWORK_NAME}" 2>&1 | grep -E "(architecture|are):" | sed 's/.*is architecture: //' | sed 's/.*are: //' || echo "unknown"

# Verify xcframework structure
if [ -d "$XCFRAMEWORK_PATH/ios-arm64" ] && [ -d "$XCFRAMEWORK_PATH/ios-arm64_x86_64-simulator" ]; then
    echo -e "${GREEN}✓ xcframework structure is correct${NC}"
else
    echo -e "${YELLOW}Warning: xcframework structure may be incomplete${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "xcframework location: $XCFRAMEWORK_PATH"
echo ""
echo "Framework supports:"
echo "  - iOS Device (arm64)"
echo "  - iOS Simulator (arm64, x86_64)"
echo ""
echo "The xcframework can be used with:"
echo "  - Swift Package Manager (SPM)"
echo "  - CocoaPods"
echo "  - Manual integration"
echo ""

