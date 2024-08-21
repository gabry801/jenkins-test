FROM ubuntu:latest

# Set environment variables to avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools and additional packages
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    git-lfs \
    golang \
    nodejs \
    npm \
    sudo \
    vim \
    wget \
    zsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up the Developer user
ARG USER=developer
RUN useradd --groups sudo --create-home --shell /bin/zsh ${USER} \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}

# Install zsh and plugins
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
    -t https://github.com/denysdovhan/spaceship-prompt \
    -a 'SPACESHIP_PROMPT_ADD_NEWLINE="false"' \
    -a 'SPACESHIP_PROMPT_SEPARATE_LINE="false"' \
    -p git \
    -p ssh-agent \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions

# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${USER}/.zshrc \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Set up the environment for Homebrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
ENV PATH="/home/linuxbrew/.linuxbrew/sbin:$PATH"
ENV HOMEBREW_NO_AUTO_UPDATE=1

# Install additional tools using Homebrew
RUN brew install yq jq mise direnv

# Add mise to shell profile
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/mise activate zsh)"' >> /home/${USER}/.zshrc

# Add direnv to shell profile
RUN echo 'eval "$(direnv hook zsh)"' >> /home/${USER}/.zshrc

# Activate mise for direnv
RUN mkdir -p /home/${USER}/.config/direnv/lib \
    && mise direnv activate > /home/${USER}/.config/direnv/lib/use_mise.sh

# Install IJ
RUN sudo mkdir /ide
COPY unzip-ide.sh /ide/
RUN sudo wget -O /ide/ide.tar.gz https://download.jetbrains.com/idea/ideaIU-2022.1.4.tar.gz && \
    sudo /ide/unzip_ide.sh && \
    sudo chown -R developer:developer /ide/bin

# Verify installations
RUN node --version && \
    npm --version && \
    brew --version && \
    go version

# Set the default command to start zsh
CMD ["zsh"]
