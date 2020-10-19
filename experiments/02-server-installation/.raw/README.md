# deploying-to-nomad-cluster

## overview

in this section , we are going to deploy a sample application to nomad cluster. we are assuming that you have already setup a local nomad cluster by following readme file in [`nomad-cluster-playbook`](https://github.com/da-moon/nomad-cluster-playbook).

## server installation

to get started with waypoint server , you need to set `NOMAD_ADDR` environment variable so that waypoint knows how to comminucate with nomad.
To select a single nomad server's IP address. you can either use `lxc ls` to find the ip address or use the following snippet :

```bash
lxc list --format json | jq -r '.[] | select((.name | contains ("server")) and (.status=="Running")).state.network.eth0.addresses|.[] | select(.family=="inet").address' | head -n 1
```

assuming our nomad server's internal IP address (the one assigned by lxd ) is `10.33.235.43`, the following will install waypoint server : 

```bash
NOMAD_ADDR="http://10.33.235.43:9701" waypoint install -platform=nomad --nomad-dc=dc1 -accept-tos
```

```bash
### terminal ###
neofetch
# => lets set NOMAD_ADDR env var since 'waypoint install' comand needs it
export NOMAD_ADDR="http://10.33.235.43:9701"
# => lets store NOMAD_ADDR in '/etc/profile.d/waypoint.sh' so that we won't have to set it in the following ssh logins
echo NOMAD_ADDR="http://10.33.235.43:9701" | sudo tee /etc/profile.d/waypoint.sh
# => let's install waypoint server 
waypoint install -platform=nomad --nomad-dc=dc1 -accept-tos
# => let's install nomad so that we can use it to check out deployment
curl -sL https://releases.hashicorp.com/nomad/index.json | \
jq -r '.versions[].version' | \
sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
grep -E -v 'ent|rc|beta' | \
tail -1 | xargs -n 1 -I {} \
sudo wget -q -O /usr/local/bin/nomad.zip "https://releases.hashicorp.com/nomad/{}/nomad_{}_linux_amd64.zip" && \
sudo unzip -q -d /usr/local/bin /usr/local/bin/nomad.zip && \
sudo rm /usr/local/bin/nomad.zip && \
nomad version
nomad job status
nomad job status waypoint-server
```

