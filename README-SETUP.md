# vLLM Server Setup on AWS EC2 (Ubuntu)

## Overview
This guide covers:
- Docker installation
- NVIDIA Driver installation
- NVIDIA Container Toolkit configuration
- GPU validation
- Building and running vLLM containers
- Pushing images to Docker Hub and AWS ECR

## Verify EC2 Instance Type
```bash
ec2-metadata --instance-type
```

Examples of NVIDIA GPU instances:
- g4dn.xlarge (Tesla T4)
- g5.xlarge (A10G)
- g6.xlarge (L4)

## Verify GPU Visibility
```bash
lspci | grep -i nvidia
```

## Install Docker
```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
```

## Run Docker Without sudo
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## Install NVIDIA Drivers
```bash
sudo apt update
sudo apt install -y ubuntu-drivers-common
ubuntu-drivers devices
sudo ubuntu-drivers install
sudo reboot
```

## Verify Driver
```bash
nvidia-smi
lsmod | grep nvidia
```

## Install NVIDIA Container Toolkit
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Verify GPU in Docker
```bash
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
```

## Build Image
```bash
cd ~/vllm-inference-server
docker build -t vllm-server .
```

## Run Container
```bash
docker run --gpus all -d -p 8000:8000 --name llm-api vllm-server
```

## Docker Hub Push
```bash
docker login

docker tag vllm-server <dockerhub-user>/vllm-server:latest

docker push <dockerhub-user>/vllm-server:latest
```

## AWS ECR Push
Create repository:
```bash
aws ecr create-repository --repository-name vllm-server --region us-east-1
```

Login:
```bash
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

Tag:
```bash
docker tag vllm-server:latest \
<account-id>.dkr.ecr.us-east-1.amazonaws.com/vllm-server:latest
```

Push:
```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/vllm-server:latest
```

## Useful Commands
```bash
docker ps
docker images
docker logs -f llm-api
docker system df
nvidia-smi
```

## Troubleshooting
### Permission denied docker.sock
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Container name already exists
```bash
docker rm -f llm-api
```

### GPU not detected
```bash
lspci | grep -i nvidia
nvidia-smi
```

### Verify Docker Runtime
```bash
docker info | grep -A5 Runtimes
```
