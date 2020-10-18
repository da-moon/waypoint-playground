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

```bash
### terminal ###
# => lets confirm we are actually logged in as 'root'
whoami
# => updating apt sources and installing 'sudo' and 'apt-utils'
apt update && apt install -y sudo apt-utils
# => creating new user called 'damoon'
useradd -l -G sudo -md /home/damoon -s /bin/bash damoon
# => setting 'damoon' password to 'damoon
echo "damoon:damoon" | chpasswd
# => setting password-less sudo for ell users in all users in sudo user group
sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers 
# => logging in as damoon
su damoon
# => use sudo on a trivial command so that user does not get sudo usage info on (the first) login
sudo echo "running sudo for user '$USER' was a success"
### end ###
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

```bash
### terminal ###
# => lets check our which user we are logging in as
whoami
# => install snap package manager
sudo apt update && sudo apt install -y snap
# => install 'core' snap package
sudo snap install core
# => install 'lxd' snap package
sudo snap install core
# => make symlinks for 'lxc' so that it is available in path
sudo ln -s /snap/bin/lxc /usr/local/bin/lxc
# => make symlinks for 'lxd' so that it is available in path
sudo ln -s /snap/bin/lxd /usr/local/bin/lxd
# => adding user to 'lxd' group so that 'lxc' operations can be invoked without 'sudo'
sudo usermod -aG lxd "$USER" && newgrp lxd
### end ###
```

## initialization

After installing, you must initilize `lxd`.

run the following in terminal and __accept defaults for all prompts__ :

```bash
sudo lxd init
```

```bash
### terminal ###
# => we need to initialize lxd. lets accept all defaults
# => we will use cat to pipe in some defaults into 'lxd' at initilization
sudo usermod -aG lxd $USER && newgrp lxd
cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
storage_pools:
- config:
    size: 30GB
  description: ""
  name: default
  driver: btrfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF
### end ###
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

```bash
### terminal ### 
# => lets check host os specs
cat /etc/os-release
# => installing dependancies on Host Os
sudo apt-get update &&
sudo apt-get install -yq \
                      jq \
                      sshpass
# => setting environment variables
export container_name="lex_dee";
export username="lex_dee";
# => either creating a new container called 'lex_dee' or starting it up
lxc launch images:debian/buster "${container_name}" || lxc start "${container_name}"
# => creating installing 'sudo', 'apt-utils' and 'openssh-server' in 'lex_dee' container
lxc exec "${container_name}" -- bash -c 'apt-get update && apt-get install -yq sudo apt-utils openssh-server'
# => enabling ssh login with password
lxc exec "${container_name}" -- bash -c 'sed -i "/.*PasswordAuthentication.*/d" /etc/ssh/sshd_config' ; && \
lxc exec "${container_name}" -- bash -c 'echo "PasswordAuthentication yes" | tee -a /etc/ssh/sshd_config' ;
# => restarting 'ssh' and 'sshd' service for changes to reflect in current environment
lxc exec "${container_name}" -- bash -c 'systemctl restart ssh sshd'
# => creating user 'lex_dee' and adding it to 'sudo' group inside 'lex_dee' container
lxc exec "${container_name}" -- bash -c "useradd -l -G sudo -md /home/${username} -s /bin/bash /home/${username}"
# => setting 'lex_dee' user password to 'lex_dee'
lxc exec "${container_name}" -- bash -c "echo \"${username}:${username}\" | chpasswd"
# => setting passwordless sudo for ell users in all users in sudo user group
lxc exec "${container_name}" -- bash -c "sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers"
# => [optional] in case you haven't generated an ssh-key, generate it now
ssh-keygen -q -f ~/.ssh/id_rsa -N empty
# => removing 'lex_dee' container from known ssh hosts
ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
# => copying the created key into container for password-less ssh
echo "${username}" | sshpass ssh-copy-id -o StrictHostKeyChecking=no -f "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
### end ###
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

```bash
### terminal ###
# => we would user my fast-apt script to initilize the container.
# => we will pipe in the commands into the container
export DEBIAN_FRONTEND=noninteractive; \
cat << EOF | lxc exec "${container_name}" -- bash
apt-get update && apt install -y curl && \
curl -fsSL \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/fast-apt | bash -s -- \
    --init
EOF
### end ###
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

```bash
### terminal ###
# => installing and setting up docker and docker-compose with my get-docker script
cat << EOF | lxc exec "${container_name}" -- bash
export DEBIAN_FRONTEND=noninteractive; \
curl -fsSL \
    https://raw.githubusercontent.com/da-moon/core-utils/master/bin/get-docker | bash -s -- --user \
    ${username}
EOF
### end ###
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

```bash
### terminal ###
# => installing python and pip
lxc exec "${container_name}" -- bash -c 'apt-get update && apt-get install -yq python python3 python3-pip python-pip'
# => creating ~/.local/bin directory so that python installs packages locally for 'lex_dee' user
lxc exec "${container_name}" -- bash -c "mkdir -p /home/${username}/.local/bin"
# => adding ~/.local/bin to 'lex_dee' user path so that installed packages are detected by shell
lxc exec "${container_name}" -- bash -c "echo 'export PATH=$PATH:~/.local/bin' >> /home/${username}/.profile"
# => making sure all directories under /home/lex_dee are owned by 'lex_dee' user
lxc exec "${container_name}" -- bash -c "chown '${username}:${username}' /home/${username}/ -R"
### end ###
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

```bash
### terminal ###
# => installing 'asciinema' with pip3 for 'lex_dee' user through ssh
echo 'python3 -m pip install asciinema' | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
# => confirming installation was successful by ssh'ing into 'lex_dee' container as user 'lex_dee' and running asciinema --version
echo 'asciinema --version' | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
# => keep in mind that the long string after ssh -t is essentially an inline script that dynamically find IP address of lex_dee container
# => lets check our containers with lxc
lxc ls
# => now lets use my script to find IP address
echo ">> IP address of '$container_name' is : $(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
# => as you can see, the inline script extracts 'lex_dee' container IP
### end ###
```

- build and install `spielbash`

```bash
cat << EOF | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')" --
gem install spielbash
spielbash --help
EOF
```

```bash
### terminal ###
# => we will build and install spielbash now.
echo 'gem install spielbash' | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
# => confirming spielbash install was successful
echo 'spielbash --help' | ssh -t "${username}@$(lxc list --format json | jq -r ".[] | select((.name==\"${container_name}\") and (.status==\"Running\"))" | jq -r '.state.network.eth0.addresses' | jq -r '.[] | select(.family=="inet").address')"
### end ###
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
