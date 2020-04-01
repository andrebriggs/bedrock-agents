FROM ubuntu:16.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    openssl \
    apt-utils \
    apt-transport-https \
    git \
    iputils-ping \
    libcurl3 \
    libicu55 \
    libunwind8 \
    gnupg2 \
    netcat \
    wget \
    unzip

# Install jq-1.6 (beta)
RUN wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
    && chmod +x jq-linux64 \
    && mv jq-linux64 /usr/bin/jq

# Install terraform
# RUN wget -q https://releases.hashicorp.com/terraform/0.12.6/terraform_0.12.6_linux_amd64.zip \
#     && unzip terraform_0.12.6_linux_amd64.zip \
#     && chmod +x terraform \
#     && mv terraform /usr/local/bin/ \
#     && rm terraform_0.12.6_linux_amd64.zip

# Install kubectl
# RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
#     && chmod +x kubectl \
#     && mv ./kubectl /usr/local/bin/kubectl

# Install helm TODO use v2.16.1
RUN curl -LO https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz \
    && tar -zxvf helm-v2.14.3-linux-amd64.tar.gz \
    && chmod +x ./linux-amd64/helm \
    && mv ./linux-amd64/helm /usr/local/bin/helm \
    && rm helm-v2.14.3-linux-amd64.tar.gz \
    && rm -rf linux-amd64

# Install fab
RUN curl -LO 'https://github.com/microsoft/fabrikate/releases/download/0.15.0/fab-v0.15.0-linux-amd64.zip' \
    && unzip fab-v0.15.0-linux-amd64.zip \
    && rm fab-v0.15.0-linux-amd64.zip \
    && chmod +x fab \
    && mv ./fab /usr/local/bin/fab

# Install AZ CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN echo "AZURE_EXTENSION_DIR=/usr/local/lib/azureExtensionDir" | tee -a /etc/environment \
    && mkdir -p /usr/local/lib/azureExtensionDir

# Install az extensions
RUN az extension add --name application-insights
RUN az extension add --name azure-devops

# Install powershell core
# RUN wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb \
#     && dpkg -i packages-microsoft-prod.deb \
#     && apt-get update \
#     && apt-get install -y powershell

# Install dotnet core sdk, this fix powershell core handling of cert trust chain problem
# RUN apt-get install -y dotnet-sdk-3.0

# add basic git config
RUN git config --global user.email "build-agent@microsoft.com" && \
    git config --global user.name "Build Agent" && \
    git config --global push.default matching

# Install build agent service
WORKDIR /azp

RUN mkdir ./patches
COPY ./patches/AgentService.js ./patches/
COPY ./start.sh .
COPY ./start-once.sh .
RUN chmod +x start.sh
RUN chmod +x start-once.sh

CMD ["./start-once.sh"]