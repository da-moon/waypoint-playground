# remote environment init

## overview

in this section, we are going to provision a fresh debian google compute instance, provision it and install lxd and setup nomad cluster playground on it.

## provisioning infrustructure

I am going to use google cloud sdk (`gcloud`) to create a compute engine. feel free to skip this step if you already has a remote server you can ssh into.

```bash
gcloud compute instances create "waypoint-demo" \
 --zone "us-central1-c" \
 --machine-type "n1-standard-16" \
 --subnet "default" \
 --network-tier "PREMIUM" \
 --image "debian-10-buster-v20200521" \
 --image-project "debian-cloud" \
 --boot-disk-size "400GB" \
 --boot-disk-type "pd-ssd" \
 --boot-disk-device-name "waypoint-demo"
```

now, we will create firewall rules to allow waypoint and nomad traffic. nomad ui, by default is available at port `4646` and waypoint needs port `9701` for gRPC API and `9702` for HTTP API so we need to setup a rule that allows ingress and egress traffic on these ports.

```bash
gcloud compute firewall-rules create waypoint-ingress \
  --allow tcp:4646,tcp:9701,tcp:9702 \
  --target-tags "waypoint-ingress" \
  --direction "INGRESS"
gcloud compute firewall-rules create waypoint-egress \
  --allow tcp:4646,tcp:9701,tcp:9702 \
  --destination-ranges '0.0.0.0/0' \
  --target-tags "waypoint-egress" \
  --direction "EGRESS"
```

lets add these tags to the compute instance we just created so the firewall allows port access

```bash
gcloud compute instances add-tags waypoint-demo --zone "us-central1-c" --tags=waypoint-egress,waypoint-ingress
```

let's update ssh config file to make sure we can ssh into the remote we just created:

```bash
gcloud compute config-ssh
```

## environment provisioning 

let's ssh into the remote server and install base dependancies

```bash
ssh waypoint-demo.us-central1-c.playground-259617
sudo apt update && sudo apt install -y neofetch make build-essential git snapd jq sshpass ansible
```

now, we will clone this repo and use the `make init` target to initialize lxd

```bash
git clone https://github.com/da-moon/waypoint-playground
pushd waypoint-playground 
make init
popd
```

## nomad playground environment setup

let's clone [`nomad-cluster-playbook`](https://github.com/da-moon/nomad-cluster-playbook)

```bash
git clone https://github.com/da-moon/nomad-cluster-playbook
```

before running any targets, we must setup an encryption password for `ansible-vault`. use the following snippet to generate a random password :

```bash
head -c16 < /dev/urandom| xxd -p -u | tee ~/.vault_pass.txt
```

now, lets setup nomad cluster containers 

```bash
make -j`nproc` init
```

lets provision those containers with ansible

```bash
make pre-staging
```

## optional : port forwarding

since our compute engine allows incoming connections from public internet, to allow access to nomad api through the internet, we will use ip tables to forward host's port `4646` to a sincle container's port `4646`. the following snippet will do the trick

```bash
sudo iptables -t nat -A PREROUTING -i $(ip link | awk -F: '$0 !~ "lo|vir|wl|lxd|docker|^[^0-9]"{print $2;getline}') -p tcp --dport 4646 -j DNAT --to "$(lxc list --format json | jq -r '.[] | select((.name | contains ("server")) and (.status=="Running")).state.network.eth0.addresses|.[] | select(.family=="inet").address' | head -n 1):4646"
```

let's confirm the rule has been added :

```bash
sudo iptables --table nat --list
```