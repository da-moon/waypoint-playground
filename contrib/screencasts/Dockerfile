From alpine:latest
# dockerfile used for recording screencasts
ARG USER="screencasts"
ENV USER "${USER}"
USER root
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --no-cache  ca-certificates curl wget git build-base make ncurses ncurses-dev \
    bash sudo jq bzip2 openssl-dev musl-dev libffi-dev upx python3-dev dropbear yarn nodejs \
    htop py3-pip coreutils findutils grep shadow neofetch alpine-sdk gcc perl tar tmux \
	screen xterm procps readline-dev neofetch && \
    wget -q -O /usr/local/bin/ack https://beyondgrep.com/ack-v3.3.1 && \
    chmod 0755 /usr/local/bin/ack
SHELL ["bash", "-c"]
RUN getent group sudo > /dev/null || sudo addgroup sudo
RUN getent group ${USER} > /dev/null || sudo addgroup ${USER}
RUN getent passwd ${USER} > /dev/null || sudo adduser \
    -G sudo \
    -h "/home/${USER}" \
    -s /bin/bash \
    -u 33333 \
    -D \
    "${USER}" "${USER}" && \
    echo "${USER}:${USER}" | chpasswd && \ 
    sed -i \
    -e '/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/d' \
    -e '/%sudo.*NOPASSWD:ALL/d' \
    /etc/sudoers && \
    echo '%sudo ALL=(ALL) ALL' >> /etc/sudoers && \
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
# custom Bash prompt
   { echo && echo "PS1='\[\e]0;\u \w\a\]\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" &&  echo 'export PATH="$PATH:~/.local/bin"';} >> .bashrc && \
    chown "${USER}:${USER}" /home/${USER} -R

ENV HOME "/home/${USER}"
WORKDIR ${HOME}
#testing user has sudo priviledge
USER ${USER}
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for ${USER} : success"
USER ${USER}
