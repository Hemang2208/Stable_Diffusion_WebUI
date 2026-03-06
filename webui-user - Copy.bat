@echo off

set PYTHON=
set GIT=
set VENV_DIR=
set COMMANDLINE_ARGS=--listen --api --share
set STABLE_DIFFUSION_REPO=https://github.com/Hemang2208/Stable_Diffusion_AI.git
set STABLE_DIFFUSION_COMMIT_HASH=5dcb6fc4c1a60dfee66ffa858a96bdb164915f1e

start "" cloudflared tunnel --url http://localhost:7860

call webui.bat
