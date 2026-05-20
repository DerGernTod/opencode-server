# Uses Ubuntu 24.04 LTS with Playwright pre-installed
FROM mcr.microsoft.com/playwright:v1.59.1-noble

USER root

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install remaining system utilities you need (removed curl, git, etc. as they are built-in)
RUN apt-get update && apt-get install -y \
    openssh-client \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (Node.js is already installed)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Install GitHub CLI (gh)
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y

# Install OpenCode Web
RUN npm install -g opencode-ai@1.15.4

# Prepare SSH directory and trust GitHub's host key
RUN mkdir -p -m 0700 /root/.ssh && ssh-keyscan github.com >> /root/.ssh/known_hosts

# Persist SSH config/keys via a mounted volume at runtime
VOLUME ["/root/.ssh"]

# Expose the port
EXPOSE 3001