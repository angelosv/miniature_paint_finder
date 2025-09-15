#!/bin/bash

# Build script for Miniature Paint Finder
# Usage: ./scripts/build.sh [environment] [platform]
# Examples:
#   ./scripts/build.sh development ios
#   ./scripts/build.sh staging android
#   ./scripts/build.sh production ios

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-development}
PLATFORM=${2:-ios}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Valid environments: development, staging, production"
    exit 1
fi

# Validate platform
if [[ ! "$PLATFORM" =~ ^(ios|android|web)$ ]]; then
    echo -e "${RED}❌ Invalid platform: $PLATFORM${NC}"
    echo "Valid platforms: ios, android, web"
    exit 1
fi

echo -e "${BLUE}🔧 Building Miniature Paint Finder${NC}"
echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "${BLUE}Platform: ${YELLOW}$PLATFORM${NC}"
echo ""

# Set environment-specific variables
case $ENVIRONMENT in
    development)
        API_BASE_URL="https://paints-api.reachu.io/api"
        DEBUG_MODE="true"
        SESSION_REPLAY_ENABLED="true"
        SESSION_REPLAY_SAMPLING_RATE="100"
        ;;
    staging)
        API_BASE_URL="https://staging-paints-api.reachu.io/api"
        DEBUG_MODE="true"
        SESSION_REPLAY_ENABLED="true"
        SESSION_REPLAY_SAMPLING_RATE="50"
        ;;
    production)
        API_BASE_URL="https://paints-api.reachu.io/api"
        DEBUG_MODE="false"
        SESSION_REPLAY_ENABLED="false"
        SESSION_REPLAY_SAMPLING_RATE="10"
        ;;
esac

# Build command
echo -e "${BLUE}📦 Running Flutter build...${NC}"

case $PLATFORM in
    ios)
        flutter build ios \
            --dart-define=ENVIRONMENT=$ENVIRONMENT \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --dart-define=DEBUG_MODE=$DEBUG_MODE \
            --dart-define=SESSION_REPLAY_ENABLED=$SESSION_REPLAY_ENABLED \
            --dart-define=SESSION_REPLAY_SAMPLING_RATE=$SESSION_REPLAY_SAMPLING_RATE \
            --release
        ;;
    android)
        flutter build apk \
            --dart-define=ENVIRONMENT=$ENVIRONMENT \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --dart-define=DEBUG_MODE=$DEBUG_MODE \
            --dart-define=SESSION_REPLAY_ENABLED=$SESSION_REPLAY_ENABLED \
            --dart-define=SESSION_REPLAY_SAMPLING_RATE=$SESSION_REPLAY_SAMPLING_RATE \
            --release
        ;;
    web)
        flutter build web \
            --dart-define=ENVIRONMENT=$ENVIRONMENT \
            --dart-define=API_BASE_URL=$API_BASE_URL \
            --dart-define=DEBUG_MODE=$DEBUG_MODE \
            --dart-define=SESSION_REPLAY_ENABLED=$SESSION_REPLAY_ENABLED \
            --dart-define=SESSION_REPLAY_SAMPLING_RATE=$SESSION_REPLAY_SAMPLING_RATE \
            --release
        ;;
esac

echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo -e "${BLUE}📁 Build artifacts are in: ${YELLOW}build/$PLATFORM${NC}"
