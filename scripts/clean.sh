#!/bin/bash

# Flutter Project Deep Clean Script
# Reference: https://stackoverflow.com/questions/76530849/pod-install-getting-stuck-grpc-core-1-50-1
# Purpose: Resolve iOS pod install errors and comprehensive project cleanup

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validation functions
validate_flutter_project() {
    if [ ! -f "pubspec.yaml" ]; then
        log_error "Not a Flutter project directory. pubspec.yaml not found."
        exit 1
    fi
}

validate_directory() {
    local dir="$1"
    local desc="$2"
    
    if [ ! -d "$dir" ]; then
        log_warning "$desc directory not found: $dir"
        return 1
    fi
    return 0
}

# Main cleanup functions
clean_flutter_cache() {
    log_info "Cleaning Flutter cache..."
    fvm flutter clean || flutter clean
    log_success "Flutter cache cleaned"
}

clean_ios_dependencies() {
    log_info "Starting iOS dependencies cleanup..."
    
    if ! validate_directory "ios" "iOS"; then
        log_warning "Skipping iOS cleanup - directory not found"
        return 0
    fi
    
    # Navigate to iOS directory
    cd ios
    
    # Clean CocoaPods cache
    log_info "Cleaning CocoaPods cache..."
    pod cache clean --all 2>/dev/null || log_warning "CocoaPods cache clean failed"
    
    # Remove system caches
    log_info "Removing system caches..."
    rm -rf ~/Library/Caches/CocoaPods 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
    
    # Remove local iOS build artifacts
    log_info "Removing iOS build artifacts..."
    rm -rf .symlinks 2>/dev/null || true
    rm -rf Pods 2>/dev/null || true
    rm -rf Podfile.lock 2>/dev/null || true
    
    # Update CocoaPods
    log_info "Updating CocoaPods..."
    if command -v gem >/dev/null 2>&1; then
        sudo gem install cocoapods 2>/dev/null || log_warning "CocoaPods update failed"
    else
        log_warning "gem command not found, skipping CocoaPods update"
    fi
    
    # Return to project root
    cd ..
    log_success "iOS dependencies cleaned"
}

clean_android_dependencies() {
    log_info "Starting Android dependencies cleanup..."
    
    if ! validate_directory "android" "Android"; then
        log_warning "Skipping Android cleanup - directory not found"
        return 0
    fi
    
    # Navigate to Android directory
    cd android
    
    # Clean and stop Gradle daemon
    log_info "Cleaning Android Gradle cache..."
    if [ -x "./gradlew" ]; then
        ./gradlew clean 2>/dev/null || log_warning "Gradle clean failed"
        ./gradlew --stop 2>/dev/null || log_warning "Gradle daemon stop failed"
    else
        log_warning "gradlew not found or not executable"
    fi
    
    # Return to project root
    cd ..
    log_success "Android dependencies cleaned"
}

clean_build_artifacts() {
    log_info "Cleaning build artifacts..."
    
    # Remove various build directories
    rm -rf build/make 2>/dev/null || true
    rm -rf build 2>/dev/null || true
    rm -rf .dart_tool 2>/dev/null || true
    
    log_success "Build artifacts cleaned"
}

reinstall_dependencies() {
    log_info "Reinstalling Flutter dependencies..."
    
    # Get Flutter dependencies
    fvm flutter pub get || flutter pub get
    
    # Reinstall iOS dependencies if iOS directory exists
    if validate_directory "ios" "iOS"; then
        cd ios
        log_info "Deintegrating and reinstalling iOS pods..."
        pod deintegrate 2>/dev/null || log_warning "Pod deintegrate failed"
        pod install --repo-update 2>/dev/null || log_warning "Pod install failed"
        cd ..
    fi
    
    log_success "Dependencies reinstalled"
}

# Main execution
main() {
    log_info "Starting Flutter project deep clean..."
    
    # Validate environment
    validate_flutter_project
    
    # Execute cleanup sequence
    clean_flutter_cache
    clean_ios_dependencies
    clean_android_dependencies
    clean_build_artifacts
    reinstall_dependencies
    
    log_success "Flutter project deep clean completed successfully!"
}

# Execute main function
main "$@"