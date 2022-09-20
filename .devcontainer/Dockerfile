# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.2/containers/ubuntu/.devcontainer/base.Dockerfile
FROM mcr.microsoft.com/vscode/devcontainers/miniconda:0-3

RUN conda install -y python=3.10 \
    && python3.10 -m pip install --upgrade pip \
    && python3.10 -m pip install \
        az-partner-center-cli
