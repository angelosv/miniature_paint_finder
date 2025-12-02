#!/bin/bash

# Miniature Paint Finder - E2E Test Runner
# This script runs all integration tests with proper setup and cleanup

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEVICE_ID="iPhone 15 Pro"
TEST_TIMEOUT=300  # 5 minutes per test
RETRY_COUNT=2

echo -e "${BLUE}🚀 Starting Miniature Paint Finder E2E Tests${NC}"
echo "=================================================="

# Verificar configuración de fuentes primero
echo -e "${YELLOW}🔤 Verificando configuración de fuentes...${NC}"
flutter test test/theme_test.dart
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Tests unitarios de fuentes fallaron${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Configuración de fuentes verificada${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if simulator is available
check_simulator() {
    print_info "Checking iOS Simulator availability..."
    
    if ! xcrun simctl list devices | grep -q "$DEVICE_ID"; then
        print_error "Device '$DEVICE_ID' not found"
        print_info "Available devices:"
        xcrun simctl list devices | grep iPhone
        exit 1
    fi
    
    print_status "iOS Simulator '$DEVICE_ID' is available"
}

# Function to start simulator
start_simulator() {
    print_info "Starting iOS Simulator..."
    
    # Boot the simulator
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    
    # Wait for simulator to be ready
    print_info "Waiting for simulator to boot..."
    sleep 10
    
    # Check if simulator is running
    if xcrun simctl list devices | grep "$DEVICE_ID" | grep -q "Booted"; then
        print_status "iOS Simulator is running"
    else
        print_error "Failed to start iOS Simulator"
        exit 1
    fi
}

# Function to clean up
cleanup() {
    print_info "Cleaning up..."
    
    # Kill any running Flutter processes
    pkill -f "flutter" || true
    
    # Clear Flutter cache
    flutter clean > /dev/null 2>&1 || true
    
    print_status "Cleanup completed"
}

# Function to setup test environment
setup_environment() {
    print_info "Setting up test environment..."
    
    # Install dependencies
    print_info "Installing Flutter dependencies..."
    flutter pub get
    
    # Generate any necessary files
    if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
        print_info "Running code generation..."
        flutter packages pub run build_runner build --delete-conflicting-outputs
    fi
    
    # Setup test environment variables
    export FLUTTER_TEST=true
    export INTEGRATION_TEST=true
    
    print_status "Test environment setup completed"
}

# Function to run specific test suite
run_test_suite() {
    local test_file=$1
    local test_name=$2
    local attempt=1
    
    print_info "Running $test_name tests..."
    
    while [ $attempt -le $RETRY_COUNT ]; do
        if [ $attempt -gt 1 ]; then
            print_warning "Retry attempt $attempt for $test_name"
            sleep 5
        fi
        
        if timeout $TEST_TIMEOUT flutter test "$test_file" --verbose; then
            print_status "$test_name tests passed"
            return 0
        else
            print_error "$test_name tests failed (attempt $attempt)"
            ((attempt++))
        fi
    done
    
    print_error "$test_name tests failed after $RETRY_COUNT attempts"
    return 1
}

# Function to generate test report
generate_report() {
    local total_tests=$1
    local passed_tests=$2
    local failed_tests=$3
    
    print_info "Generating test report..."
    
    cat > test_report.md << EOF
# E2E Test Report

**Date:** $(date)
**Device:** $DEVICE_ID
**Total Tests:** $total_tests
**Passed:** $passed_tests
**Failed:** $failed_tests
**Success Rate:** $(( passed_tests * 100 / total_tests ))%

## Test Results

EOF
    
    print_status "Test report generated: test_report.md"
}

# Main execution
main() {
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Trap cleanup on exit
    trap cleanup EXIT
    
    # Pre-flight checks
    print_info "Running pre-flight checks..."
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Flutter doctor
    print_info "Checking Flutter setup..."
    flutter doctor --verbose
    
    # Check simulator (iOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        check_simulator
        start_simulator
    fi
    
    # Setup environment
    setup_environment
    
    # Run test suites
    print_info "Starting test execution..."
    
    # Test suites to run
    declare -A test_suites=(
        ["integration_test/flows/auth_flow_test.dart"]="Authentication"
        ["integration_test/flows/navigation_flow_test.dart"]="Navigation"
        ["integration_test/flows/project_flow_test.dart"]="Project Management"
        ["integration_test/flows/palette_flow_test.dart"]="Palette Management"
        ["integration_test/flows/inventory_flow_test.dart"]="Inventory Management"
        ["integration_test/flows/wishlist_flow_test.dart"]="Wishlist Management"
        ["integration_test/flows/offline_flow_test.dart"]="Offline Functionality"
    )
    
    # Run each test suite
    for test_file in "${!test_suites[@]}"; do
        test_name="${test_suites[$test_file]}"
        ((total_tests++))
        
        if [ -f "$test_file" ]; then
            if run_test_suite "$test_file" "$test_name"; then
                ((passed_tests++))
            else
                ((failed_tests++))
            fi
        else
            print_warning "Test file not found: $test_file"
            ((failed_tests++))
        fi
        
        # Small delay between test suites
        sleep 2
    done
    
    # Generate report
    generate_report $total_tests $passed_tests $failed_tests
    
    # Final summary
    echo "=================================================="
    print_info "E2E Test Execution Summary"
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    
    if [ $failed_tests -eq 0 ]; then
        print_status "All tests passed! 🎉"
        exit 0
    else
        print_error "Some tests failed. Check the logs above."
        exit 1
    fi
}

# Run main function
main "$@"
