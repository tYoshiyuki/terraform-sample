FROM ubuntu:22.04

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    curl \
    git \
    jq \
    libicu70 \
    unzip \
    zip

# install dotnet sdk
RUN apt-get install -y dotnet-sdk-6.0

# install buildah
RUN apt-get install -y buildah \
   && echo "unqualified-search-registries = [\"docker.io\"]" | tee -a /etc/containers/registries.conf \
   && ln -s /usr/bin/buildah /usr/bin/docker

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# install python
ARG PYTHON_VERSION="3.10"
RUN apt-get install -y \
    python${PYTHON_VERSION} \
    python3-pip \
    && ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python

# install mono
RUN apt-get install ca-certificates gnupg \
    && gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt update \
    && apt install -y mono-devel

ENV TARGETARCH="linux-x64"

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh

ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT ./start.sh