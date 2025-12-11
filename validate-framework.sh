#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
TESTAPP_DIR="$(cd "$PROJECT_DIR/.." && pwd)/TestApp"
XCFRAMEWORK_PATH="$PROJECT_DIR/output/Ascend.xcframework"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ascend Framework Validation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if xcframework exists
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo -e "${RED}❌ xcframework not found at:${NC}"
    echo "   $XCFRAMEWORK_PATH"
    echo ""
    echo -e "${YELLOW}Please run ./build-framework.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✓ xcframework found${NC}"
echo "   Location: $XCFRAMEWORK_PATH"
echo ""

# Verify xcframework structure
echo -e "${YELLOW}Verifying xcframework structure...${NC}"
if [ -d "$XCFRAMEWORK_PATH/ios-arm64" ] && [ -d "$XCFRAMEWORK_PATH/ios-arm64_x86_64-simulator" ]; then
    echo -e "${GREEN}✓ xcframework structure is valid${NC}"
    echo "   - iOS Device (arm64): ✓"
    echo "   - iOS Simulator (arm64 + x86_64): ✓"
else
    echo -e "${RED}❌ xcframework structure is invalid${NC}"
    exit 1
fi
echo ""

# Check if TestApp files exist
echo -e "${YELLOW}Checking test app files...${NC}"
if [ -f "$TESTAPP_DIR/TestApp/TestApp.swift" ] && \
   [ -f "$TESTAPP_DIR/TestApp/ContentView.swift" ] && \
   [ -f "$TESTAPP_DIR/TestApp/TestViewModel.swift" ]; then
    echo -e "${GREEN}✓ Test app files found${NC}"
else
    echo -e "${RED}❌ Test app files not found${NC}"
    exit 1
fi
echo ""

# Verify the framework binary
echo -e "${YELLOW}Verifying framework binaries...${NC}"

# Check device framework
DEVICE_FRAMEWORK="$XCFRAMEWORK_PATH/ios-arm64/Ascend.framework/Ascend"
if [ -f "$DEVICE_FRAMEWORK" ]; then
    DEVICE_ARCHS=$(lipo -info "$DEVICE_FRAMEWORK" 2>&1 | grep -E "(architecture|are):" | sed 's/.*is architecture: //' | sed 's/.*are: //' || echo "unknown")
    echo -e "${GREEN}✓ Device framework: $DEVICE_ARCHS${NC}"
else
    echo -e "${RED}❌ Device framework binary not found${NC}"
    exit 1
fi

# Check simulator framework
SIMULATOR_FRAMEWORK="$XCFRAMEWORK_PATH/ios-arm64_x86_64-simulator/Ascend.framework/Ascend"
if [ -f "$SIMULATOR_FRAMEWORK" ]; then
    SIMULATOR_ARCHS=$(lipo -info "$SIMULATOR_FRAMEWORK" 2>&1 | grep -E "(architecture|are):" | sed 's/.*is architecture: //' | sed 's/.*are: //' || echo "unknown")
    echo -e "${GREEN}✓ Simulator framework: $SIMULATOR_ARCHS${NC}"
else
    echo -e "${RED}❌ Simulator framework binary not found${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Framework Validation Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Create an Xcode project:"
echo "   - Open Xcode"
echo "   - File → New → Project"
echo "   - iOS → App"
echo "   - Product Name: TestApp"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo ""
echo "2. Add the xcframework:"
echo "   - Select TestApp target"
echo "   - General → Frameworks, Libraries, and Embedded Content"
echo "   - Click '+' → Add Other... → Add Files..."
echo "   - Select: $XCFRAMEWORK_PATH"
echo "   - Ensure 'Embed & Sign' is selected"
echo ""
echo "3. Copy test app files:"
echo "   - Copy $(basename "$TESTAPP_DIR")/TestApp/*.swift files to your Xcode project"
echo "   - Replace default App.swift and ContentView.swift"
echo ""
echo "4. Build and Run:"
echo "   - Select iOS Simulator (iPhone 15)"
echo "   - Press ⌘R to build and run"
echo "   - Verify SDK initializes and tests pass"
echo ""
echo -e "${GREEN}Framework is ready to use!${NC}"
echo ""
