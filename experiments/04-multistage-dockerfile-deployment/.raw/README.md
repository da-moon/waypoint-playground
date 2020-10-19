# multistage dockerfile deployment

as you have already noticed that the docker images built with `pack` plugin are hardly minimal images. I would recommend having a multi-stage builder docker file in which in one stage , application is built and in the second stage, application runs.

to make multi-stage builds work, use a `hook` (or github actions pipeline) to build the image first and then use `docker-pull` plugin to add waypoint entrypoint to the image and push it to the artifact repository.

this approach has the benefit of seamless integration with github actions pipeline.

this approach has two stages :

- pull target git repository in docker container and run build
- move the artifact from the first stage into a second minimal stage

to make this work, the artifact must be statically linked or self contained.

in this example, we will make a simple selfcontainer django based echo webserver.

the following is the base template for our docker image

```dockerfile
FROM python:alpine as base

ARG GITHUB_REPOSITORY_OWNER
ENV GITHUB_REPOSITORY_OWNER $GITHUB_REPOSITORY_OWNER

ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY $GITHUB_REPOSITORY

ARG GITHUB_ACTOR
ENV GITHUB_ACTOR $GITHUB_ACTOR

ARG GITHUB_TOKEN
ENV GITHUB_TOKEN $GITHUB_TOKEN

ENV TERM=xterm
# [NOTE] => packages installed here are some of the most common base build dependencie for alpine
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk upgrade -U -a && \
    apk add build-base make git bash ncurses curl libressl-dev musl-dev libffi-dev
SHELL ["/bin/bash", "-c"]
# [TODO] => install and customize your image how ever you like here
RUN git clone "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/<repo_owner>/<repo_name>.git" /workspace/<repo_name>
WORKDIR /workspace/<repo_name>
# [TODO] => add build commands here
FROM python:alpine
COPY --from=base /workspace/<artifact> /<artifact>
ENTRYPOINT ["/<artifact>"]
```

the environment variables defined in this file are present in github actions exection pipeline. we will build the image with github actions before using `docker-pull` to inject waypoint entrypoint and pushing it to a docker repository. to see how building the image with github actions would look like, look into this github [`repo`](https://github.com/da-moon/upstream-gen/blob/master/.github/workflows/workflow.yml)

in this demo, we are not using github actions but a `hook` to build the image locally. 

our target repo is `da-moon/upstream-gen` I have already create a github token that can pull the repo.

first, lets setup the docker image :

```bash
mkdir -p /tmp/upstream-gen
cat << EOF | tee /tmp/upstream-gen/Dockerfile
# eg. build command
# docker build \
#        --build-arg GITHUB_REPOSITORY=\$GITHUB_REPOSITORY \
#        --build-arg GITHUB_REPOSITORY_OWNER=\$GITHUB_REPOSITORY_OWNER \
#        --build-arg GITHUB_ACTOR=\$GITHUB_ACTOR \
#        --build-arg GITHUB_TOKEN=\$GITHUB_TOKEN \
#        -t da-moon/upstream-gen:latest .

FROM python:alpine as base

ARG GITHUB_REPOSITORY_OWNER
ENV GITHUB_REPOSITORY_OWNER \$GITHUB_REPOSITORY_OWNER

ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY \$GITHUB_REPOSITORY

ARG GITHUB_ACTOR
ENV GITHUB_ACTOR \$GITHUB_ACTOR

ARG GITHUB_TOKEN
ENV GITHUB_TOKEN \$GITHUB_TOKEN
ENV TERM=xterm
ENV PIP_USER=false
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk upgrade -U -a && \
    apk add build-base make git bash ncurses curl libressl-dev musl-dev libffi-dev
SHELL ["/bin/bash", "-c"]
RUN mkdir -p "/workspace" && \
    mkdir -p "~/.local/bin" && \
    mkdir -p "~/.poetry/bin" && \ 
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 && \
    python3 -m pip install pex dephell[full] && \
    dephell --version && \
    pex --version
RUN git clone "https://\$GITHUB_ACTOR:\$GITHUB_TOKEN@github.com/da-moon/upstream-gen.git" "/workspace/upstream-gen"
WORKDIR /workspace/upstream-gen
RUN make python-pex && \
    dist/pex/upstream-gen version
FROM python:alpine
COPY --from=base /workspace/upstream-gen/dist/pex/upstream-gen /upstream-gen
ENTRYPOINT ["/upstream-gen"]
EOF
```

so, we will create a script file to have waypoint run and then we will push the image:

```bash
cat << EOF | tee /tmp/upstream-gen/build.sh
#!/usr/bin/env bash

export GITHUB_REPOSITORY=da-moon/upstream-gen
export GITHUB_REPOSITORY_OWNER=da-moon
export GITHUB_ACTOR=da-moon
docker build \
        --build-arg GITHUB_REPOSITORY=\$GITHUB_REPOSITORY \
        --build-arg GITHUB_REPOSITORY_OWNER=\$GITHUB_REPOSITORY_OWNER \
        --build-arg GITHUB_ACTOR=\$GITHUB_ACTOR \
        --build-arg GITHUB_TOKEN=\$GITHUB_TOKEN \
        -t "\$GITHUB_REPOSITORY:latest" .
EOF
chmod +x /tmp/upstream-gen/build.sh
```