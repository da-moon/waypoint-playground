# syntax = docker/dockerfile:1.0-experimental

FROM python:buster as base

ARG GITHUB_REPOSITORY_OWNER
ENV GITHUB_REPOSITORY_OWNER $GITHUB_REPOSITORY_OWNER

ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY $GITHUB_REPOSITORY

ARG GITHUB_ACTOR
ENV GITHUB_ACTOR $GITHUB_ACTOR

ENV TERM=xterm
# [NOTE] => git token is stored at '$HOME/.git_token'
ENV PIP_USER=false
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y  make git curl wget build-essential python3 python3-pip 
SHELL ["/bin/bash", "-c"]
RUN mkdir -p "/workspace" && \
    mkdir -p "~/.local/bin" && \
    mkdir -p "~/.poetry/bin" && \
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 && \
    python3 -m pip install pex dephell[full] && \
    dephell --version && \
    pex --version
RUN git clone "https://$GITHUB_ACTOR:$(cat $HOME/.git_token)@github.com/da-moon/upstream-gen.git" "/workspace/upstream-gen"
WORKDIR /workspace/upstream-gen
RUN make python-pex && \
    dist/pex/upstream-gen version
FROM python:buster
COPY --from=base /workspace/upstream-gen/dist/pex/upstream-gen /upstream-gen
ENTRYPOINT ["/upstream-gen"]
CMD ["--log", "TRACE" ,"server"]