#!/bin/bash

#####################################################################
#                    DOCKER BUILD SCRIPT                           #
#                   MetaGenomics Pipeline                          #
#####################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Configuration
IMAGE_NAME="metagenomics-pipeline"
IMAGE_TAG="latest"
DOCKERFILE_PATH="Dockerfile"
BUILD_CONTEXT="."

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag|-t)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --name|-n)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --dockerfile|-f)
            DOCKERFILE_PATH="$2"
            shift 2
            ;;
        --context|-c)
            BUILD_CONTEXT="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --pull)
            PULL="--pull"
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
  --tag, -t TAG           Set image tag (default: latest)
  --name, -n NAME         Set image name (default: metagenomics-pipeline)
  --dockerfile, -f FILE   Dockerfile path (default: Dockerfile)
  --context, -c PATH      Build context path (default: .)
  --no-cache              Build without cache
  --pull                  Always pull base image
  --help, -h              Show this help message

Examples:
  $0                                    # Basic build
  $0 --tag v1.0 --name my-pipeline     # Custom tag and name
  $0 --no-cache --pull                 # Fresh build

EOF
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Pre-build checks
log "Starting Docker build process"
log "Configuration:"
info "  Image name: ${IMAGE_NAME}:${IMAGE_TAG}"
info "  Dockerfile: $DOCKERFILE_PATH"
info "  Build context: $BUILD_CONTEXT"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    error "Docker daemon is not running. Please start Docker."
fi

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    error "Dockerfile not found at: $DOCKERFILE_PATH"
fi

# Check if build context exists
if [[ ! -d "$BUILD_CONTEXT" ]]; then
    error "Build context directory not found: $BUILD_CONTEXT"
fi

# Show disk space
info "Available disk space:"
df -h | grep -E "(Filesystem|/dev/)"

# Build the Docker image
log "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
log "This may take 10-20 minutes depending on your internet connection..."

BUILD_START_TIME=$(date +%s)

if docker build ${NO_CACHE} ${PULL} \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "$DOCKERFILE_PATH" \
    "$BUILD_CONTEXT"; then
    
    BUILD_END_TIME=$(date +%s)
    BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
    
    log "Docker image built successfully in ${BUILD_DURATION} seconds!"
    
    # Show image information
    info "Image details:"
    docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}\t{{.Size}}"
    
    # Test the image
    log "Testing the Docker image..."
    if docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" python3 -c "print('Docker image test successful!')"; then
        log "Docker image test passed!"
    else
        warn "Docker image test failed, but image was built successfully"
    fi
    
    # Show usage examples
    info "Usage examples:"
    info "  # Run with help"
    info "  docker run --rm ${IMAGE_NAME}:${IMAGE_TAG}"
    info ""
    info "  # Run with data"
    info "  docker run --rm -v \$(pwd)/data:/data ${IMAGE_NAME}:${IMAGE_TAG} python3 /app/metapipeline_improved.py --help"
    info ""
    info "  # Use with docker-compose"
    info "  docker-compose up"
    info ""
    info "  # Interactive shell"
    info "  docker run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} bash"
    
    # Optional: Tag additional versions
    if [[ "$IMAGE_TAG" != "latest" ]]; then
        log "Tagging as latest..."
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:latest"
    fi
    
else
    error "Docker image build failed!"
fi

log "Build process completed successfully!"
log "Next steps:"
info "1. Test the image: docker run --rm ${IMAGE_NAME}:${IMAGE_TAG}"
info "2. Create data directories: mkdir -p {data,results,databases,logs}"
info "3. Run pipeline: docker run --rm -v \$(pwd)/data:/data ${IMAGE_NAME}:${IMAGE_TAG} python3 /app/metapipeline_improved.py --help"

