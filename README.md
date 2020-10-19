# waypoint-playground

experiments with hashicorp waypoint and nomad. 
the environment for recording screencasts and experimenting with `waypoint` is based on lxd containers. 
your host must be a linux machine since we are using [`linux-containers(lxc/lxd)`](https://linuxcontainers.org) for out environment.

To learn about `lxd` and my reasoning for choosing it over other virtualization methods to experiment with nomad and waypoint, look into [lxc-readme] (contrib/lxc/README.md) document.

this playground and all associated screencasts are based on Hashicorp's tutorials.

## experiments

- initialization - [markdown](experiments/00-remote-environment-init/README.md) | [pdf](experiments/00-remote-environment-init/README.pdf) : covers setting up a remote compute instance in google cloud. we also go through provisioning and installing `lxd` on it, bootstrapping nomad cluster with 3 server and 3 clients in the remote instance's lxd containers and setting up a container for our waypoint experiments.
- waypoint client setup - [markdown](experiments/01-client-installation/README.md) | [pdf](experiments/01-client-installation/README.pdf) : covers downloading and installing waypoint client
- waypoint client setup - [markdown](experiments/02-server-installation/README.md) | [pdf](experiments/02-server-installation/README.pdf) : covers setting up waypoint server on nomad cluster
- waypoint client setup - [markdown](experiments/03-cloud-native-buildpack-deployment/README.md) | [pdf](experiments/03-cloud-native-buildpack-deployment/README.pdf) : covers setting up waypoint server on nomad cluster
- 


## references

- https://learn.hashicorp.com/tutorials/waypoint
