FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

RUN apt-get update -y && apt-get install -y \
    curl wget git unzip zip tar \
    ca-certificates gnupg dirmngr lsb-release \
    build-essential \
    software-properties-common \
    jq nano vim htop \
    sqlite3 \
    ffmpeg imagemagick \
    openssh-client \
    cron \
    supervisor \
    python3-dev \
    libvips-dev \
    libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev \
    postgresql-client default-mysql-client redis-tools \
    git-lfs \
    && rm -rf /var/lib/apt/lists/*

ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl --retry 3 --retry-delay 2 -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
RUN . $NVM_DIR/nvm.sh && \
    nvm install 22 && \
    nvm install 24 && \
    nvm install 26 && \
    nvm alias default 24 && \
    npm install -g pnpm yarn && \
    ln -s "$NVM_DIR/versions/node/$(nvm version default)" /usr/local/node-current
ENV PATH="/usr/local/node-current/bin:$PATH"

ENV BUN_INSTALL=/usr/local/bun
RUN curl --retry 3 --retry-delay 2 -fsSL https://bun.sh/install | bash
ENV PATH="${BUN_INSTALL}/bin:${PATH}"

RUN for i in 1 2 3 4 5; do add-apt-repository -y ppa:deadsnakes/ppa && break || sleep 5; done && \
    apt-get update -y && \
    apt-get install -y \
      python3.12 python3.12-venv \
      python3.13 python3.13-venv \
      python3.14 python3.14-venv \
      python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN for i in 1 2 3 4 5; do add-apt-repository -y ppa:ondrej/php && break || sleep 5; done && \
    apt-get update -y && \
    for v in 8.2 8.3 8.4 8.5; do \
      apt-get install -y \
        php$v php$v-cli php$v-fpm php$v-common \
        php$v-mysql php$v-pgsql php$v-sqlite3 \
        php$v-curl php$v-gd php$v-mbstring \
        php$v-xml php$v-zip php$v-bcmath php$v-intl; \
    done && \
    apt-get install -y composer && \
    rm -rf /var/lib/apt/lists/*
RUN update-alternatives --install /usr/bin/php php /usr/bin/php8.2 82 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.3 83 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.4 84 && \
    update-alternatives --install /usr/bin/php php /usr/bin/php8.5 85 && \
    update-alternatives --set php /usr/bin/php8.4

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1

ENV GO_VERSION=1.27.1
RUN ARCH=$(dpkg --print-architecture) && \
    curl --retry 3 --retry-delay 2 -Lo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/home/container/go"
ENV GOCACHE="/home/container/.cache/go-build"

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
RUN curl --retry 3 --retry-delay 2 --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable --profile minimal && \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME
ENV PATH="${CARGO_HOME}/bin:${PATH}"

RUN apt-get update -y && apt-get install -y \
    cmake ninja-build gdb valgrind clang clang-format \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && apt-get install -y \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2t64 \
    libpango-1.0-0 libcairo2 fonts-liberation \
    libx11-6 libxext6 libxcb1 libxrender1 libxi6 \
    libgtk-3-0 libvulkan1 libdbus-glib-1-2 libx11-xcb1 \
    xvfb x11-utils xauth \
    libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
    libwoff1 libopus0 libwebpdemux2 libharfbuzz-icu0 \
    libenchant-2-2 libsecret-1-0 libhyphen0 libmanette-0.2-0 \
    libgles2 libx264-dev \
    fonts-noto fonts-noto-color-emoji fonts-noto-cjk fonts-dejavu-core \
    locales tzdata \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Jakarta

ENV PLAYWRIGHT_BROWSERS_PATH=/opt/browsers
RUN pip install --break-system-packages playwright && \
    python3 -m playwright install chromium firefox webkit --with-deps

ENV XDG_CACHE_HOME=/opt/camoufox-cache
RUN pip install --break-system-packages "camoufox[geoip]" && \
    for i in 1 2 3 4 5; do \
      python3 -m camoufox fetch && break || { echo "camoufox fetch failed, retry $i/5..."; sleep 10; }; \
    done && \
    find /opt/camoufox-cache -maxdepth 3

RUN . $NVM_DIR/nvm.sh && \
    npm install -g playwright puppeteer puppeteer-real-browser puppeteer-extra puppeteer-extra-plugin-stealth pm2 && \
    npx --yes playwright install chromium firefox webkit --with-deps
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN ARCH=$(dpkg --print-architecture) && \
    curl --retry 3 --retry-delay 2 -Lo /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.${ARCH}" && \
    chmod +x /usr/local/bin/ttyd

RUN ARCH=$(dpkg --print-architecture) && \
    curl --retry 3 --retry-delay 2 -Lo /usr/local/bin/cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" && \
    chmod +x /usr/local/bin/cloudflared

WORKDIR /home/container
ENV HOME=/home/container
ENV USER=container
RUN echo '' >> /etc/bash.bashrc && \
    echo 'if [ -n "$CODEX_PS1" ]; then' >> /etc/bash.bashrc && \
    echo '  PS1="$CODEX_PS1"' >> /etc/bash.bashrc && \
    echo 'fi' >> /etc/bash.bashrc

COPY entrypoint.sh /entrypoint.sh
COPY scripts/ /scripts/

RUN apt-get update -y && apt-get install -y --no-install-recommends dos2unix && \
    dos2unix /entrypoint.sh /scripts/*.sh && \
    sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh /scripts/*.sh && \
    chmod +x /entrypoint.sh /scripts/*.sh && \
    apt-get purge -y dos2unix && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash", "/entrypoint.sh"]
