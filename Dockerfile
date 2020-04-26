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
    unzip \
    sudo
    
ENV jq_version=1.6
ENV tf_version=0.12.6
ENV helm_version=v2.16.1
ENV fab_version=0.17.3
ENV bedrock_version=0.6.4

# Install jq-1.6 (beta)
RUN wget -q "https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64" \
    && chmod +x jq-linux64 \
    && mv jq-linux64 /usr/bin/jq

# Install terraform
RUN wget -q "https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip" \
    && unzip "terraform_${tf_version}_linux_amd64.zip" \
    && chmod +x terraform \
    && mv terraform /usr/local/bin/ \
    && rm "terraform_${tf_version}_linux_amd64.zip"

# Install kubectl
# RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
#     && chmod +x kubectl \
#     && mv ./kubectl /usr/local/bin/kubectl

# Install helm TODO use v2.16.1
RUN curl -LO "https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz" \
    && tar -zxvf "helm-${helm_version}-linux-amd64.tar.gz" \
    && chmod +x ./linux-amd64/helm \
    && mv ./linux-amd64/helm /usr/local/bin/helm \
    && rm "helm-${helm_version}-linux-amd64.tar.gz" \
    && rm -rf linux-amd64

# Install fab
RUN curl -LO "https://github.com/microsoft/fabrikate/releases/download/${fab_version}/fab-v${fab_version}-linux-amd64.zip" \
    && unzip "fab-v${fab_version}-linux-amd64.zip" \
    && rm "fab-v${fab_version}-linux-amd64.zip" \
    && chmod +x fab \
    && mv ./fab /usr/local/bin/fab

# Install Bedrock CLI
RUN curl -LO "https://github.com/microsoft/bedrock-cli/releases/download/v${bedrock_version}/bedrock-linux" \
    && mkdir bedrock \
    && mv bedrock-linux /usr/local/bin/bedrock \
    && chmod +x /usr/local/bin/bedrock 

# Install Bedrock Build.sh
# RUN curl -LO "https://raw.githubusercontent.com/Microsoft/bedrock/master/gitops/azure-devops/build.sh" > build.sh \
#     && mv build.sh /usr/local/bin/build.sh \
#     && chmod +x /usr/local/bin/build.sh \
#     && sudo ln -s /usr/local/bin/build.sh /usr/local/bin/bedrock_build

# Install Custom Bedrock Build.sh
COPY ./bedrock-build.sh /usr/local/bin/bedrock-build.sh
RUN sudo ln -s /usr/local/bin/bedrock-build.sh /usr/local/bin/bedrock_build
RUN chmod +x /usr/local/bin/bedrock-build.sh

# Install AZ CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN echo "AZURE_EXTENSION_DIR=/usr/local/lib/azureExtensionDir" | tee -a /etc/environment \
    && mkdir -p /usr/local/lib/azureExtensionDir

# Install az extensions
RUN az extension add --name azure-devops

# add basic git config
RUN git config --global user.email "bedrock-build-agent@microsoft.com" && \
    git config --global user.name "Bedrock Build Agent" && \
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
