# Stable Diffusion WebUI - Docker Setup

This Docker setup allows you to run Stable Diffusion WebUI in a containerized environment.

## Prerequisites

- Docker Desktop installed on your system
- At least 8GB of RAM available
- Sufficient disk space for models and outputs

## Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

### Option 2: Using Docker CLI

```bash
# Build the image
docker build -t stable-diffusion-webui .

# Run the container
docker run -d \
  --name stable-diffusion-webui \
  -p 7860:7860 \
  -v ${PWD}/models:/app/models \
  -v ${PWD}/outputs:/app/outputs \
  -v ${PWD}/embeddings:/app/embeddings \
  -v ${PWD}/extensions:/app/extensions \
  stable-diffusion-webui
```

## Accessing the WebUI

Once the container is running, you can access the WebUI in multiple ways:

- **Local**: http://localhost:7860
- **Network**: http://YOUR_IP:7860
- **Public Share Link**: A gradio.live URL will be automatically generated and displayed in the container logs

### Getting the Public Share Link

To view the public shareable link:

```bash
# View logs to see the gradio.live URL
docker-compose logs -f

# Or using Docker CLI
docker logs stable-diffusion-webui
```

Look for a line like:

```
Running on public URL: https://xxxxxxxxxxxxxxxx.gradio.live
```

**Note**: The public share link:

- Is temporary and expires after 72 hours
- Requires the container to keep running
- May have rate limiting applied by Gradio
- Can be shared with anyone for remote access
- Is secured with HTTPS automatically

## Configuration

### Command Line Arguments

Modify the `COMMANDLINE_ARGS` in `docker-compose.yml` or Dockerfile to customize behavior:

```yaml
environment:
  - COMMANDLINE_ARGS=--use-cpu all --precision full --no-half --skip-torch-cuda-test --listen --api --share
```

Common arguments:

- `--listen`: Allow remote connections
- `--api`: Enable API endpoints
- `--share`: Generate a public shareable gradio.live URL (enabled by default)
- `--xformers`: Use xformers for memory efficiency (GPU version)
- `--medvram`: Optimize for medium VRAM (GPU version)
- `--lowvram`: Optimize for low VRAM (GPU version)
- `--no-half`: Disable half-precision (CPU version)
- `--use-cpu all`: Use CPU for all operations
- `--gradio-auth username:password`: Add authentication to the WebUI

### Disabling Public Share Link

If you don't want the public share link, remove `--share` from COMMANDLINE_ARGS:

```yaml
environment:
  - COMMANDLINE_ARGS=--use-cpu all --precision full --no-half --skip-torch-cuda-test --listen --api
```

### Volumes

The following directories are mounted as volumes for persistent storage:

- `./models`: Model files (checkpoints, VAE, LoRA, etc.)
- `./outputs`: Generated images
- `./embeddings`: Textual inversion embeddings
- `./extensions`: WebUI extensions
- `./config.json`: Configuration file
- `./ui-config.json`: UI configuration

## Installing Models

1. Place your model files in the appropriate directories:
   - Stable Diffusion models: `./models/Stable-diffusion/`
   - VAE models: `./models/VAE/`
   - LoRA models: `./models/Lora/`
   - Embeddings: `./embeddings/`

2. Restart the container:
   ```bash
   docker-compose restart
   ```

## GPU Support

For GPU support (NVIDIA only), you need:

1. NVIDIA Docker runtime installed
2. Uncomment the GPU service in `docker-compose.yml`
3. Create a `Dockerfile.gpu` with CUDA support

Example Dockerfile.gpu:

```dockerfile
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Install Python 3.10.11
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y python3.10 python3.10-distutils python3-pip

# ... rest of the Dockerfile with GPU-specific torch installation
```

## Troubleshooting

### Build failures due to network timeouts

If you encounter "Connection timed out" or "Failed to fetch" errors during build:

**Option 1: Retry the build**

```bash
# Docker will use cached layers from the previous attempt
docker-compose build --no-cache
docker-compose up -d
```

**Option 2: Use the alternative Dockerfile**

```bash
# Edit docker-compose.yml and change:
# dockerfile: Dockerfile
# to:
# dockerfile: Dockerfile.alt

# Then build
docker-compose build
docker-compose up -d
```

**Option 3: Build with increased timeouts**

```bash
docker build --network=host --build-arg BUILDKIT_PROGRESS=plain -t stable-diffusion-webui -f Dockerfile .
```

**Option 4: Manual build with Docker Buildkit**

```bash
# Enable BuildKit for better caching and retry logic
$env:DOCKER_BUILDKIT=1
docker build -t stable-diffusion-webui .
docker-compose up -d
```

**Option 5: Use a different network or VPN**
Sometimes the issue is with your ISP or network. Try:

- Switching to a different network
- Using a VPN
- Building during off-peak hours

### Container won't start

```bash
# Check logs
docker-compose logs

# Check container status
docker ps -a
```

### Out of memory errors

- Increase Docker memory limit in Docker Desktop settings
- Use `--lowvram` or `--medvram` flags if using GPU

### Port already in use

Change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8080:7860" # Access at http://localhost:8080
```

### Models not showing up

- Ensure models are in the correct directory
- Restart the container after adding models
- Check file permissions on mounted volumes

## Development

To rebuild after code changes:

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Stopping and Removing

```bash
# Stop the container
docker-compose down

# Stop and remove volumes (WARNING: deletes generated images)
docker-compose down -v

# Remove the image
docker rmi stable-diffusion-webui
```

## Environment Variables

Available environment variables:

| Variable             | Description                  | Default                                                                                  |
| -------------------- | ---------------------------- | ---------------------------------------------------------------------------------------- |
| `COMMANDLINE_ARGS`   | WebUI command line arguments | `--use-cpu all --precision full --no-half --skip-torch-cuda-test --listen --api --share` |
| `GRADIO_SERVER_NAME` | Server bind address          | `0.0.0.0`                                                                                |
| `PYTHONUNBUFFERED`   | Python output buffering      | `1`                                                                                      |

## Performance Notes

- **CPU Mode**: This setup runs in CPU mode which is slower but more compatible
- **Memory**: Requires significant RAM (8GB+ recommended)
- **Generation Time**: CPU generation can take several minutes per image
- **GPU**: For faster performance, consider the GPU version with proper CUDA setup

## Security Considerations

- The `--share` flag creates a public URL accessible by anyone with the link
- The `--listen` flag allows external connections - use with caution on public networks
- **Strongly recommended**: Use `--gradio-auth username:password` for authentication when using `--share`
  ```yaml
  environment:
    - COMMANDLINE_ARGS=--use-cpu all --listen --api --share --gradio-auth myuser:mypassword
  ```
- The public share link is temporary but can be accessed by anyone who has it
- Use a reverse proxy (nginx) for production deployments
- Keep your Docker images updated
- Consider disabling `--share` if you only need local/network access

## Support

For issues specific to the Docker setup, check the logs first:

```bash
docker-compose logs -f
```

For general Stable Diffusion WebUI issues, refer to the main repository documentation.
