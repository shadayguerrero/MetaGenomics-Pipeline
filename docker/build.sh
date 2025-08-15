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

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Configuration
IMAGE_NAME="metagenomics-pipeline"
IMAGE_TAG="latest"
DOCKERFILE_PATH="/home_local/camda/shaday/MetaGenomics-Pipeline/docker/Dockerfile"

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
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --tag, -t TAG       Set image tag (default: latest)"
            echo "  --name, -n NAME     Set image name (default: metagenomics-pipeline)"
            echo "  --no-cache          Build without cache"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    error "Dockerfile not found at: $DOCKERFILE_PATH"
fi

# Build the Docker image
log "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
log "Dockerfile: $DOCKERFILE_PATH"

if docker build ${NO_CACHE} -t "${IMAGE_NAME}:${IMAGE_TAG}" -f "$DOCKERFILE_PATH" .; then
    log "Docker image built successfully!"
    
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
    
    info "To run the pipeline:"
    info "docker run --rm -v \$(pwd)/data:/data ${IMAGE_NAME}:${IMAGE_TAG} python3 /app/metapipeline_improved.py --help"
    
    info "To use with docker-compose:"
    info "cd docker && docker-compose up"
    
else
    error "Docker image build failed!"
fi

