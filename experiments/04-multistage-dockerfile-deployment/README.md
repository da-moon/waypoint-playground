
# multistage dockerfile deployment

[![asciicast](https://asciinema.org/a/rI8rkYTyaVl6ltRWqK4i5pEos.svg)](https://asciinema.org/a/rI8rkYTyaVl6ltRWqK4i5pEos)

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
    apk add build-base make git bash ncurses-static curl libressl-dev musl-dev libffi-dev 
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

our target repo is `da-moon/upstream-gen` I have already create a github token that can pull the repo. to securily use the token, store it in `~/.git_token` and use Docker build secrets to inject it into the image. 

first, lets setup the docker image :

```bash
mkdir -p /tmp/upstream-gen
cat << EOF | tee /tmp/upstream-gen/Dockerfile
# syntax = docker/dockerfile:1.0-experimental

FROM python:buster as base

ARG GITHUB_REPOSITORY_OWNER
ENV GITHUB_REPOSITORY_OWNER \$GITHUB_REPOSITORY_OWNER

ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY \$GITHUB_REPOSITORY

ARG GITHUB_ACTOR
ENV GITHUB_ACTOR \$GITHUB_ACTOR

ENV TERM=xterm
# [NOTE] => git token is stored at '\$HOME/.git_token'
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
RUN git clone "https://\$GITHUB_ACTOR:\$(cat \$HOME/.git_token)@github.com/da-moon/upstream-gen.git" "/workspace/upstream-gen"
WORKDIR /workspace/upstream-gen
RUN make python-pex && \
    dist/pex/upstream-gen version
FROM python:buster
COPY --from=base /workspace/upstream-gen/dist/pex/upstream-gen /upstream-gen
ENTRYPOINT ["/upstream-gen"]
CMD ["--log", "TRACE" ,"server"]
EOF
sed -i -e 's/\s\s*/ /g' -e '/^\s*$/d' /tmp/upstream-gen/Dockerfile
```

so, we will create a script file to have waypoint run in a hook to build the image.

```bash
cat << EOF | tee /tmp/upstream-gen/build.sh
#!/usr/bin/env bash

export GITHUB_REPOSITORY=upstream-gen
export GITHUB_REPOSITORY_OWNER=da-moon
export GITHUB_ACTOR=da-moon
docker system prune -f && \
DOCKER_BUILDKIT=1 docker build \
        --progress=plain \
        --secret id=github_token,src="\$HOME/.git_token" \
        --build-arg GITHUB_REPOSITORY="\$GITHUB_REPOSITORY_OWNER/\$GITHUB_REPOSITORY" \
        --build-arg GITHUB_REPOSITORY_OWNER=\$GITHUB_REPOSITORY_OWNER \
        --build-arg GITHUB_ACTOR=\$GITHUB_ACTOR \
        -t "fjolsvin/\$GITHUB_REPOSITORY:latest" . && \
docker push "fjolsvin/\$GITHUB_REPOSITORY:latest"
EOF
chmod +x /tmp/upstream-gen/build.sh && \
sed -i -e 's/\s\s*/ /g' -e '/^\s*$/d' /tmp/upstream-gen/build.sh
```
as you can see, the script reads a git token stored in `~/.git_token`  so generate a token and store it there before moving along.

we will use the following `waypoint.hcl` rebuild the image and inject waypoint 

```bash
cat << EOF | tee /tmp/upstream-gen/waypoint.hcl
project = "waypoint-http-echo-example"
app "waypoint-http-echo-example" {
  labels = {
    "service" = "waypoint-http-echo-example",
  }
  build {
    hook {
      when = "before"
      command = ["./build.sh"]
    }
    use "docker-pull" {
        image = "fjolsvin/upstream-gen"
        tag = "latest"
        encoded_auth = file("~/.docker_auth")
    }
    registry {
      use "docker" {
        image = "fjolsvin/waypoint-http-echo-example"
        tag = "latest"
        encoded_auth = file("~/.docker_auth")
      }
    }
  }
  deploy {
    use "nomad" {
      datacenter = "dc1"
      region = "global"
      replicas = 1
      service_port = 9090
    }
  }
}
EOF
pushd /tmp/upstream-gen/ && \
waypoint init && \
NOMAD_ADDR="http://10.33.235.43:4646" waypoint up
popd
rm ~/.git_token
```
