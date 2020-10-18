# waypoint-playground

experiments with hashicorp waypoint and nomad. 
the environment for recording screencasts and experimenting with `waypoint` is based on lxd containers. 
your host must be a linux machine since we are using [`linux-containers(lxc/lxd)`](https://linuxcontainers.org) for out environment.

To learn about `lxd` and my reasoning for choosing it over other virtualization methods to experiment with nomad and waypoint, look into [lxc-readme] (contrib/lxc/README.md) document.

this playground and all associated screencasts are based on Hashicorp's tutorials.

## initialization

Run `make init` to install lxd and initilize container used for our experiments. 
make sure that `snap` package manager, `sshpass` and `jq` are installed on host machine before running `make init`. make usre that an ssh key is also present on your host before running the target. you can generate ssh key pair by running `ssh-keygen`.

`make init` target uses `contrib/scripts/env-init` for bootstraping and installing needed tools. run `contrib/scripts/env-init --help` to learn more about how the command line interface works.

## bootstrapping nomad cluster

- clone [`nomad-cluster-playbook`](https://github.com/da-moon/nomad-cluster-playbook) and go to it's directory by running `git clone https://github.com/da-moon/nomad-cluster-playbook && pushd nomad-cluster-playbook` 
- follow the guide in README.md to prepare for deploying and bootstrapping nomad cluster. just to reiterate, make sure `ansible` is installed on your host and you have already generated a password for `ansible-vault` and stored it at `~/.vault_pass.txt`. 
- initilize nomad server and client containers by running `make -j$(nproc) init`
- bootstrap nomad client/server with ansible by running `make pre-staging`
- in case you are running these commands on a remote server, forward all incomming connection at port `4646` to a single nomad server container by running `iptables -t nat -A PREROUTING -i $(ip link | awk -F: '$0 !~ "lo|vir|wl|lxd|docker|^[^0-9]"{print $2;getline}') -p tcp --dport 4646 -j DNAT --to "$(lxc list --format json | jq -r '.[] | select((.name | contains ("server")) and (.status=="Running")).state.network.eth0.addresses|.[] | select(.family=="inet").address' | head -n 1):4646"`. make sure port 4646 is not blocked by cloud providers firewall or any other firewall running on your host.

## references

- https://learn.hashicorp.com/tutorials/waypoint

.PHONY:init
.SILENT:init
init:	
# ifndef LXD
	# - $(info "'lxd' is not available. installing lxd through snap and configuring the daemon.")
	- chmod +x contrib/scripts/env-init && contrib/scripts/env-init --lxd-init
# endif