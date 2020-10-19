# waypoint-playground

experiments with hashicorp waypoint and nomad. 
the environment for recording screencasts and experimenting with `waypoint` is based on lxd containers. 
your host must be a linux machine since we are using [`linux-containers(lxc/lxd)`](https://linuxcontainers.org) for out environment.

To learn about `lxd` and my reasoning for choosing it over other virtualization methods to experiment with nomad and waypoint, look into [lxc-readme] (contrib/lxc/README.md) document.

this playground and all associated screencasts are based on Hashicorp's tutorials.

## directory structure

- `contrib` : supporting files and artifacts.
- `docs` : a summary of different waypoint concepts. can be used as quick start guide.
- `experiments` : collection of documents with accompanying screencasts, showcasing how to use waypoint.
- `fixtures` : static files , like mermaid.js graphs
- `scenes` : yaml files passed to `spielbash` for recording screen casts.
- in case you just want to watch screencasts, you can find their links at [`experiments/screen-casts.txt`](experiments/screen-casts.txt) 

## experiments

- initialization - [markdown](experiments/00-remote-environment-init/README.md) | [pdf](experiments/00-remote-environment-init/README.pdf) : covers setting up a remote compute instance in google cloud. we also go through provisioning and installing `lxd` on it, bootstrapping nomad cluster with 3 server and 3 clients in the remote instance's lxd containers and setting up a container for our waypoint experiments.
- waypoint client setup - [markdown](experiments/01-client-installation/README.md) | [pdf](experiments/01-client-installation/README.pdf) : covers downloading and installing waypoint client
- waypoint server setup - [markdown](experiments/02-server-installation/README.md) | [pdf](experiments/02-server-installation/README.pdf) : covers setting up waypoint server on nomad cluster
- `pack` build plugin and nomad deploy plugin - [markdown](experiments/03-cloud-native-buildpack-deployment/README.md) | [pdf](experiments/03-cloud-native-buildpack-deployment/README.pdf) : covers building a rails application with cloudnative buildpacks and deployment of the image on nomad cluster
- multistage docker builder - [markdown](experiments/04-multistage-dockerfile-deploymentt/README.md) | [pdf](experiments/04-multistage-dockerfile-deployment/README.pdf) : covers using hook to build the image and retagging it with `docker-pull`. this experiment has a tight synergy with github actions.

## references

- https://learn.hashicorp.com/tutorials/waypoint
