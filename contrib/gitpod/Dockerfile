FROM gitpod/workspace-full
ARG SHELLCHECK_VERSION="stable"
ARG BROWSH_VERSION="1.6.4"
ENV USER=gitpod
USER root
# -> #gitpod/workspace-full-vnc:branch-jx-python-tk is based on ubuntu disco.
#and it's default source have moved to http://old-releases.ubuntu.com so we must update main sources
#https://serverfault.com/questions/622735/how-do-i-upgrade-an-end-of-life-ubuntu-distribution
# -> upgrading packages and installing some misc tools
RUN export DEBIAN_FRONTEND=noninteractive; \
    sed -i -e 's/\/\/.*ubuntu.com/\/\/old-releases.ubuntu.com/g' /etc/apt/sources.list && \
    touch /etc/apt/sources-fast.list && \
    apt-get update -q  && apt-get install -yq curl aspell && curl -fsSL \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/fast-apt | bash -s -- \
    --init || true;
LABEL dazzle/layer=misc-install
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && apt-get install -yq neofetch xclip wamerican lynx elinks && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/*
# browsh is a terminal browser built on top of firefox-esr 
LABEL dazzle/layer=browsh-install
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    wget -q -O \
    "/tmp/browsh_${BROWSH_VERSION}_linux_amd64.deb" \
    "https://github.com/browsh-org/browsh/releases/download/v${BROWSH_VERSION}/browsh_${BROWSH_VERSION}_linux_amd64.deb" && \
    apt-get install -yq "/tmp/browsh_${BROWSH_VERSION}_linux_amd64.deb" && \
    rm "/tmp/browsh_${BROWSH_VERSION}_linux_amd64.deb" && \
    browsh --version && \
    lynx --version && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/* 
# pandoc is a tool with support for converting a wide range of different documents
LABEL dazzle/layer=pandoc-install
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && \
    apt-get install -yq \
    pandoc \
    texlive-latex-extra && \
    pandoc --version && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/* 
# bbcp is a tool that uses multiple concurrent connection to transfer files from/to server.
# it's a faster alternative to scp
LABEL dazzle/layer=bbcp-install
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && apt-get install -yq libssl-dev build-essential zlib1g-dev aria2 && \
    aria2c --check-certificate=false --dir=/tmp/ http://www.slac.stanford.edu/~abh/bbcp/bbcp.tgz && \
    cd /tmp && \
    tar xvfz bbcp.tgz && \
    cd /tmp/bbcp/src && \
    sed -i.bak 's/\-i/\-m/g' Makefile && \
    make && \
    mv ../bin/*/bbcp /usr/local/bin/ && \
    chmod +x /usr/local/bin/bbcp && \
    bbcp --version && \
    cd /tmp && \
    rm bbcp.tgz && \
    rm -r bbcp && \
    cd ~
#shellcheck is a tool used for linitng bash shell scripts
LABEL dazzle/layer=shellcheck
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    wget -q -O \
    "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
    "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" && \
    tar -C /tmp -xvf "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" && \
    cp "/tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/ && \
    rm -rf "/tmp/shellcheck-${SHELLCHECK_VERSION}"* && \
    shellcheck --version

#customizing python install
LABEL dazzle/layer=python-custom
USER ${USER}
#setting up PATH and other env vars
RUN export DEBIAN_FRONTEND=noninteractive; \
    rm -rf "/home/${USER}/.poetry" && \
    rm -rf "/home/${USER}/.local" && \
    mkdir -p "/home/${USER}/.local/bin" && \
    echo 'export PATH="$PATH:/home/${USER}/.poetry/bin"' >> "/home/${USER}/.bashrc" && \
    echo 'alias poetry="python3 /home/${USER}/.poetry/bin/poetry"' >> "/home/${USER}/.bash_aliases" 

ENV PATH="$PATH:/home/${USER}/.local/bin:/home/${USER}/.poetry/bin"
# installing poetry. poetry is a python dependancy management software
RUN export DEBIAN_FRONTEND=noninteractive; \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python && \
    python3 "/home/${USER}/.poetry/bin/poetry" --version
# installing updating pip and installing pip packages 
RUN export DEBIAN_FRONTEND=noninteractive; \
    pip3 install asciinema dephell[full] && \
    asciinema --version && \
    dephell --version
LABEL dazzle/layer=ruby-custom
USER root
#installing and configure ruby
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && apt-get install -yq ruby ruby-dev gcc && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/* 
#spielbash is a tool that controls terminal and sends comands 
#and keypresses to tmux based on a YAML file while recoding with asciinema
USER root
# installing spielbash base dependancies 
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && apt-get install -yq tmux xterm procps && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/* 
USER ${USER}
#setting up PATH and other env vars
RUN export DEBIAN_FRONTEND=noninteractive; \
    rm -rf "/home/${USER}/.gem/bin" && \
    mkdir -p "/home/${USER}/.gem/bin" && \
    echo 'export PATH="$PATH:/home/${USER}/.gem/bin"' >> "/home/${USER}/.bashrc" && \
    echo 'export GEM_HOME="/home/${USER}/.gem"' >> "/home/${USER}/.bashrc"  
ENV PATH="$PATH:/home/${USER}/.gem/bin"
ENV GEM_HOME="/home/${USER}/.gem"
RUN export DEBIAN_FRONTEND=noninteractive; \
    gem install spielbash && \
    spielbash --help
# installing puppeteer and it's dependancies and adding packages dependant on puppeteer
LABEL dazzle/layer=puppeteer-setup
USER root
#installing chrome with headless support
RUN export DEBIAN_FRONTEND=noninteractive; \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    apt-get update -q && \
    apt-get install -yq libgconf-2-4 google-chrome-stable && \
    google-chrome --version && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/cache/apt/archives/* 
#removing nvm and reinstalling all packages with native debian sources
RUN export DEBIAN_FRONTEND=noninteractive; \
    rm -rf "/home/${USER}/.nvm/" && \
    rm -rf "/home/${USER}/.npm/" && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -fsSL https://deb.nodesource.com/setup_12.x | sudo bash -  && \
    apt-get update -q && apt-get install -yq nodejs yarn && \
    node --version && \
    yarn --version 
#installing typescript
RUN export DEBIAN_FRONTEND=noninteractive; \
    yarn global add typescript --prefix /usr/local
#installing puppeteer
RUN export DEBIAN_FRONTEND=noninteractive; \
    yarn global add puppeteer
#carbon-now is a tool for taking screenshots of code
RUN export DEBIAN_FRONTEND=noninteractive; \
    yarn global add carbon-now-cli --prefix /usr/local
#setting mermaid conf file
RUN export DEBIAN_FRONTEND=noninteractive; \
    rm -rf "/etc/mmdc/" && \
    mkdir -p "/etc/mmdc/" && \
    jq -n --arg arg_one "--no-sandbox" '{"args":[$arg_one]}' > /etc/mmdc/puppeteer-config.json
#installing and setting up mermaid cli
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -q && \
    apt-get install -yq gconf-service libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxss1 libxtst6 libappindicator1 libnss3 libasound2 libatk1.0-0 libc6 ca-certificates fonts-liberation lsb-release xdg-utils wget && \
    yarn global add @mermaid-js/mermaid-cli --prefix /usr/local
USER ${USER}
# setting up bash alias amd making sure our installation has no issues
RUN export DEBIAN_FRONTEND=noninteractive; \
    carbon-now --version && \
    mmdc -p /etc/mmdc/puppeteer-config.json --version  && \
    tsc --version && \
    echo "alias mmdc='mmdc -p /etc/mmdc/puppeteer-config.json'" >> "/home/${USER}/.bash_aliases" && \
    sed -i '/nvm/d' "/home/${USER}/.bashrc"
LABEL dazzle/layer=custom-scripts
USER root
RUN export DEBIAN_FRONTEND=noninteractive; \
    wget -q -O \
    /usr/local/bin/run-sc \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/run-sc && \
    chmod +x "/usr/local/bin/run-sc"
RUN export DEBIAN_FRONTEND=noninteractive; \
    wget -q -O \
    /usr/local/bin/gitt \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/gitt && \
    chmod +x "/usr/local/bin/gitt"
USER ${USER}
CMD ["bash"]