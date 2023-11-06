ARG CUDA_VERSION=11.8.0
ARG OS_VERSION=22.04
# Define base image.
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION}

# Variables used at build time.
## CUDA architectures, required by Colmap and tiny-cuda-nn.
## NOTE: All commonly used GPU architectures are included and supported here. To speedup the image build process remove all architectures but the one of your explicit GPU. Find details here: https://developer.nvidia.com/cuda-gpus (8.6 translates to 86 in the line below) or in the docs.
ARG CUDA_ARCHITECTURES=90

# Set environment variables.
## Set non-interactive to prevent asking for user inputs blocking image creation.
ENV DEBIAN_FRONTEND=noninteractive
## Set timezone as it is required by some packages.
ENV TZ=Europe/Berlin
## CUDA Home, required to find CUDA in some packages.
ENV CUDA_HOME="/usr/local/cuda"


#ENV PYTHONDONTWRITEBYTECODE 1
#ENV PYTHONUNBUFFERED 1

# Install nessesary packages
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python-is-python3 \
    python3-pip \
    sudo && \
    apt-get clean

RUN pip install --no-cache-dir --upgrade pip

# CUDA 11.8
RUN pip install torch==2.0.0+cu118 torchvision==0.15.1+cu118 torchaudio==2.0.1 --index-url https://download.pytorch.org/whl/cu118

# Clone the repository
#WORKDIR /workspace/audiocraft
RUN cd home && git clone -b v1.0 https://github.com/oobabooga/text-generation-webui.git

RUN python3 --version

RUN rm -rf /home/text-generation-webui/requirements.txt

# move requirements.txt to the docker image
COPY requirements.txt /home/text-generation-webui/requirements.txt

# # Install Python dependencies from requirements.txt
RUN pip3 install -r /home/text-generation-webui/requirements.txt

# Expose the Gradio server port
EXPOSE 7862

# Set the environment variable for Gradio
ENV GRADIO_SERVER_NAME 0.0.0.0
ENV NVIDIA_VISIBLE_DEVICES=all

# copy the models to the docker image /home/text-generation-webui/models/
#COPY models /home/text-generation-webui/models/
RUN apt-get update && apt-get install -y wget
# Download vicuna-13b-free model
RUN wget -c https://huggingface.co/reeducator/vicuna-13b-free/resolve/main/ggml-vicuna-13b-free-v230502-q5_0.bin -O /home/text-generation-webui/models/ggml-vicuna-13b-free-v230502-q5_0.bin

# Set the command to run the app
CMD cd /home/text-generation-webui && python3 -u server.py
