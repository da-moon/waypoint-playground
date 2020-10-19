#!/usr/bin/env bash

export GITHUB_REPOSITORY=upstream-gen
export GITHUB_REPOSITORY_OWNER=da-moon
export GITHUB_ACTOR=da-moon
docker system prune -f && \
DOCKER_BUILDKIT=1 docker build \
        --progress=plain \
        --secret id=github_token,src="$HOME/.git_token" \
        --build-arg GITHUB_REPOSITORY="$GITHUB_REPOSITORY_OWNER/$GITHUB_REPOSITORY" \
        --build-arg GITHUB_REPOSITORY_OWNER=$GITHUB_REPOSITORY_OWNER \
        --build-arg GITHUB_ACTOR=$GITHUB_ACTOR \
        -t "fjolsvin/$GITHUB_REPOSITORY:latest" . && \
docker push "fjolsvin/$GITHUB_REPOSITORY:latest"