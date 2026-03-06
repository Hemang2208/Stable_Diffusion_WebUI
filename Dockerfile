# Base image with Python 3.10.11
FROM python:3.10.11-slim

# Set working directory
WORKDIR /app

# Configure apt to be more resilient to network issues
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::http::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries && \
    echo 'Acquire::ftp::Timeout "120";' >> /etc/apt/apt.conf.d/80-retries

# Install system dependencies with retry logic
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends --fix-missing \
    git \
    wget \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libgomp1 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install cloudflared for tunnel support
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb

# Copy requirements files
COPY requirements.txt requirements_versions.txt ./
COPY requirements-test.txt ./

# Upgrade pip and install specific build tools
RUN python -m pip install --upgrade pip && \
    pip install setuptools==68.2.2 wheel

# Install NumPy with specific version for compatibility
RUN pip install numpy==1.26.4

# Install PyTorch (CPU version for compatibility with your setup)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install CLIP manually without build isolation
RUN pip install git+https://github.com/openai/CLIP.git --no-build-isolation

# Install main requirements
RUN pip install -r requirements.txt

# Copy the entire application
COPY . .

# Initialize git repository to prevent git errors
RUN git init && \
    git config user.email "docker@localhost" && \
    git config user.name "Docker Build" && \
    git add . && \
    git commit -m "Initial commit" || true

# Create necessary directories
RUN mkdir -p models/Stable-diffusion models/VAE models/GFPGAN models/ESRGAN \
    models/BSRGAN models/RealESRGAN models/Codeformer models/LDSR models/SwinIR \
    models/ScuNET models/Lora models/hypernetworks embeddings outputs cache config_states \
    extensions repositories

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV COMMANDLINE_ARGS="--use-cpu all --precision full --no-half --skip-torch-cuda-test --listen --api --share"
ENV STABLE_DIFFUSION_REPO="https://github.com/joypaul162/Stability-AI-stablediffusion.git"
ENV STABLE_DIFFUSION_COMMIT_HASH="f16630a927e00098b524d687640719e4eb469b76"

# Expose port for web interface
EXPOSE 7860

# Verify installation
RUN python -c "import torch, clip, numpy; print('Environment OK')"

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'cloudflared tunnel --url http://localhost:7860 &' >> /app/start.sh && \
    echo 'python launch.py' >> /app/start.sh && \
    chmod +x /app/start.sh

# Run the application with cloudflared tunnel
CMD ["/bin/bash", "/app/start.sh"]
