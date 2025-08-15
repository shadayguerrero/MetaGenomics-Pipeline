#!/bin/bash

#####################################################################
#                    PACKAGE SCRIPT                                #
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
PACKAGE_NAME="MetaGenomics-Pipeline"
VERSION="1.0.0"
DATE=$(date +"%Y%m%d")
PACKAGE_FILE="${PACKAGE_NAME}-v${VERSION}-${DATE}.tar.gz"

log "Packaging MetaGenomics Pipeline v${VERSION}"

# Create package directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="${TEMP_DIR}/${PACKAGE_NAME}"

log "Creating package directory: $PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy files
log "Copying pipeline files..."

# Main files
cp README.md LICENSE "$PACKAGE_DIR/"
cp install.sh run_pipeline.sh activate_env.sh "$PACKAGE_DIR/"
cp metapipeline.py metapipeline_improved.py "$PACKAGE_DIR/"
cp package.sh "$PACKAGE_DIR/"

# Directories
cp -r src/ "$PACKAGE_DIR/"
cp -r config/ "$PACKAGE_DIR/"
cp -r docs/ "$PACKAGE_DIR/"
cp -r docker/ "$PACKAGE_DIR/"

# Create empty directories for user data
mkdir -p "$PACKAGE_DIR"/{logs,tmp,databases,results,examples,tests}

# Create version file
echo "MetaGenomics Pipeline v${VERSION}" > "$PACKAGE_DIR/VERSION"
echo "Build date: $(date)" >> "$PACKAGE_DIR/VERSION"
echo "Git commit: $(git rev-parse HEAD 2>/dev/null || echo 'N/A')" >> "$PACKAGE_DIR/VERSION"

# Create checksums
log "Generating checksums..."
cd "$PACKAGE_DIR"
find . -type f -exec sha256sum {} \; > CHECKSUMS.sha256
cd - > /dev/null

# Create package
log "Creating package archive..."
cd "$TEMP_DIR"
tar -czf "$PACKAGE_FILE" "$PACKAGE_NAME"
cd - > /dev/null

# Move package to current directory
mv "${TEMP_DIR}/${PACKAGE_FILE}" .

# Clean up
rm -rf "$TEMP_DIR"

# Package information
PACKAGE_SIZE=$(du -h "$PACKAGE_FILE" | cut -f1)
log "Package created successfully!"
info "Package: $PACKAGE_FILE"
info "Size: $PACKAGE_SIZE"

# Create installation instructions
cat > "${PACKAGE_NAME}-INSTALL.txt" << EOF
MetaGenomics Pipeline v${VERSION} - Installation Instructions

1. Extract the package:
   tar -xzf ${PACKAGE_FILE}
   cd ${PACKAGE_NAME}

2. Run automatic installation:
   ./install.sh

3. Activate environment:
   source activate_env.sh

4. Test installation:
   ./run_pipeline.sh --help

5. Read documentation:
   - README.md: Overview and quick start
   - docs/installation.md: Detailed installation guide
   - docs/usage.md: Usage instructions

For support: https://github.com/your-username/MetaGenomics-Pipeline

EOF

log "Installation instructions created: ${PACKAGE_NAME}-INSTALL.txt"

# Verify package
log "Verifying package contents..."
if tar -tzf "$PACKAGE_FILE" | head -10; then
    log "Package verification successful!"
else
    error "Package verification failed!"
fi

log "Packaging completed successfully!"
info "Files created:"
info "  - $PACKAGE_FILE (main package)"
info "  - ${PACKAGE_NAME}-INSTALL.txt (installation instructions)"

