

# lxc

## overview

[`LXC`](https://linuxcontainers.org) or `Linux Containers`, managed , developed and maintained by [`Canonical`](https://canonical.com), refers to a suite of tools ( command line utilities ) focused on creating and orchestrating `system containers` , whether they are running in standalone environment or a cluster.

`system containers` or `OS containers` refer to containerization technologies which offer an environment as close as possible as the one you'd get from a `Virtual Machine`, such as `Libvirt`, `QEMU` or `Oracle Virtualbox` but without the overhead that comes with running a resource hungry hypervisor and a separate kernel which simulating all the hardware.

In practice, I find `system containers` to offer more freedom and interactivity compared with `application containers` such as Docker.

The following is a non-exhaustive list of why I choose to use `LXC` to provide and setup development environments for repositories:

- system init : LXC is a better choice when experimenting with tools that need their own systemd unit (such as `nomad`) since it has indipendant system init for each container
- ease of use : Personally speaking, I find `LXC` to be much simpler to use compared with Docker.
- interactivity : `LXC` offers a larger degree of freedom to install and run software within it's containers since it was meant to be a replacement, for mostcases to virtual machines. It is quite easy to get a shell and run commands the same way you would run them in your native OS shell.
- high-priviledge : it is quite easy to setup `LXC` ro run application that need higher priviledge, such as access to certain Linux kernel API or CPU execution ring 2/1 in `LXC`. You can also run nested containers within `LXC`, for instance run a Docker container inside `LXC` contaienr.
- architecture emulation : it is rather easy to emulate foreign CPU architecture inside `LXC` containers. For instance, you host machine may have `x86_64` architecture but you are developing for `AARCH64`. You can have the container emulate `AARCH64` cpu architecture.
- simple clustering : I find setting up and managing a distributed cluster with `LXC` to be exteremely easy, compared with alternative.

To sum up, I believe `LXC` is a great tool for setting up development and staging environment since it is much simpler to use and much less resource hungry when compared with alternatives.

## LXC ecosystem

Primarily speaking, installing `LXC` add two main executables (command line interfaces) to your system :

- `lxd`: `lxd` is the 'brain' of the ecosyste. It is a `daemon` ( long-running process ) that provides main containerization functionality, such as container runtime and agent.
It exposes a `RESTful` API to control behavior and interact with it, such as launching a new container.
- `lxc` : `lxc` is nothing but a 'client' to `lxd`. Essentially, it provides an easy to use interface to send requests to `lxd` API and interact with it. 
`lxc` is the software that end-users use most often.

the biggest issue with `LXC` is that `lxd` is only available on Linux machines, since at it's core , `lxd` uses some linux libraries such as `libvirt` and needs access to some features unique to Linux Kernel.
on the other hand, `lxc` is available on every platform so as long as you have `lxd` running on some remote linux machine, you can use `lxc` to interact with it and use it.

## user setup

this step is optional. If you haven't created a user on your debian machine and only available user is `root`, which is the case for most debian buster images, then you must install some base software and create a new user.

- install `sudo` and `apt-utils` packages

```bash
apt update && apt install -y sudo apt-utils
```

- we will create a default user . lets call it 'damoon' and set it's password to damoon.

```bash
export username="damoon"; \
useradd -l -G sudo -md "/home/${username}" -s /bin/bash -p password "${username}" && \
echo "${username}:${username}" | chpasswd && \
sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers && \
unset "${username}"
```

## installation

While it is most certainly possible to compile LXC from source, it can be quite cumbersome. The official, most updaed LXC release is available only through [`Snap`](https://snapcraft.io/) package manager. From my experience , `Debian` and `Ubuntu` derivative distros offer the most frictionless experience with `Snap` package manager.

after installing snap, run the following in terminal to install [`LXC`](https://snapcraft.io/lxd) :

```bash
sudo apt install -y snapd && \
sudo snap install core && \
sudo snap install lxd && \
sudo usermod -aG lxd "$USER" && \
newgrp lxd
```

## initialization

After installing, you must initilize `lxd`.

run the following in terminal and __accept defaults for all prompts__ :

```bash
sudo lxd init
```

## barebone container setup

I have prepared a instructions so that you can quickly launch a new `Debian Buster` container, called `lex_dee` and install base dependancies and configure the system. 
These instructure were written with assumption that you are using a Debian/Ubuntu derivative distro on your Host OS

- confirm install/confirm existance of dependancies on Host OS: open terminal in your Host OS and run the following snippet  
  - `jq` is used for creating and parsing json payload. we will use 'lxd' to get a reply from 'lxd' with all the containers and use 'jq' to parse the response and find out container's IP 'dynamically' so that we can ssh into it later on.
  - `sshpass` is used to ssh into the lxc container with password non-interactively, i.e no need to manually type password of the user we are ssh'ing into

```bash
sudo apt-get update &&
sudo apt-get install -yq \
                      jq \
                      sshpass
```

- Create a new `Debian Buster` LXC container and name it `lex_dee` .create a new user called 'lex_dee' in 'lex_dee' container, install ssh server and configure ssh login with password

```bash
container_name="lex_dee"; \
username="lex_dee"; \
lxc launch images:debian/buster "${container_name}" || lxc start "${container_name}" ; \
cat << EOF | lxc exec "${container_name}" -- bash
apt-get update && apt-get install -yq openssh-server
sed -i "/.*PasswordAuthentication.*/d" /etc/ssh/sshd_config
echo "PasswordAuthentication yes" | tee -a /etc/ssh/sshd_config
systemctl restart ssh sshd
useradd -l -G sudo -md /home/${username} -s /bin/bash /home/${username}
echo '${username}:${username}' | chpasswd
sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
EOF
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')" && \
echo "${username}" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -f "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
```

if you followed along, at this point your container should be ready.
all steps after this point are for optimizing your experience.

## provisioning common software

- install base dependancies

```bash
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
apt-get update && apt-get install -y curl && \
curl -fsSL \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/fast-apt | bash -s -- \
    --init
EOF
```

- install `Docker` and `docker-compose` for `lex_dee` user

```bash
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
curl -fsSL \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/get-docker | bash -s -- --user \
    ${username}
EOF
```

- install python and it's dependancies and setting it up for user 'lex_dee'
 
```bash
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
apt-get update && apt-get install -yq python python3 python3-pip python-pip && \
mkdir -p /home/${username}/.local/bin && \
echo 'export PATH=\$PATH:~/.local/bin' >> /home/${username}/.profile && \
chown "${username}:${username}" /home/${username}/ -R
EOF
```

## provisioning software needed for recording environment

- install ruby and configuring it for use by user 'lex_dee'

```bash
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
apt-get update && apt-get install -yq ruby ruby-dev gcc && \
mkdir -p /home/${username}/.gem/bin && \
echo 'export PATH=\$PATH:~/.gem/bin' >> /home/${username}/.profile && \
echo 'export GEM_HOME=\$HOME/.gem' >> /home/${username}/.profile && \
chown "${username}:${username}" /home/${username}/ -R
EOF
```

- install base packages for 'asciinema' and 'spielbash'

```bash
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
apt-get update && apt-get install -yq tmux xterm procps
EOF
```

- install `asciinema`

```bash
cat << EOF | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')" --
python3 -m pip install asciinema
asciinema --version
EOF
```

- build and install `spielbash`

```bash
cat << EOF | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')" --
gem install spielbash
spielbash --help
EOF
```

## common commands

- create a new debian 10 machine called `lex_dee`

```bash
lxc launch images:debian/buster lex_dee
```

- get root shell into `lex_dee`

```bash
lxc exec lex_dee bash
```

- list all containers

```bash
lxc list
```

- Get `ssh` access to `lex_dee` container as `lex_dee` user

```bash
ssh "lex_dee@$(lxc list --format json | jq -r ".[] | select((.name==\"lex_dee\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
```

- take a file out of running `lex_dee` container with `scp`

```bash
scp "lex_dee@$(lxc list --format json | jq -r ".[] | select((.name==\"lex_dee\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')":/path/to/source/file/on/container /path/to/store/on/host
```

## references

- https://linuxcontainers.org/
