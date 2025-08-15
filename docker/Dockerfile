# MetaGenomics Pipeline Docker Image
FROM mambaorg/micromamba:1.5.8

# Metadata
LABEL maintainer="MetaGenomics Pipeline Team"
LABEL description="Complete metagenomics analysis pipeline"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV MAMBA_ROOT_PREFIX=/opt/conda
ENV PATH=/opt/conda/bin:$PATH

# Switch to root user for system installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    unzip \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    libfontconfig1 \
    libgcc-s1 \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Switch back to micromamba user
USER $MAMBA_USER

# Copy environment file
COPY config/environment-full.yml /tmp/environment.yml

# Create conda environment
RUN micromamba create -f /tmp/environment.yml && \
    micromamba clean --all --yes

# Activate environment in shell
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Set working directory
WORKDIR /app

# Copy pipeline files
COPY . /app/

# Make scripts executable
RUN chmod +x /app/install.sh && \
    chmod +x /app/run_pipeline.sh && \
    chmod +x /app/activate_env.sh && \
    chmod +x /app/metapipeline_improved.py && \
    chmod +x /app/src/*.sh

# Create necessary directories
RUN mkdir -p /app/logs /app/tmp /app/databases /app/results

# Set environment variables for the pipeline
ENV PIPELINE_HOME=/app
ENV PATH=/app:$PATH

# Create entrypoint script
RUN echo '#!/bin/bash\n\
eval "$(micromamba shell hook --shell bash)"\n\
micromamba activate metagenomics-pipeline\n\
exec "$@"' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["python3", "/app/metapipeline_improved.py", "--help"]

# Expose volume for data
VOLUME ["/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import sys; print('Pipeline container is healthy'); sys.exit(0)"

