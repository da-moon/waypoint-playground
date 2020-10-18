# deploying-to-nomad-cluster

in this section , we are going to deploy a sample application to nomad cluster. we are assuming that you have already setup a local nomad cluster by following readme file in [`nomad-cluster-playbook`](https://github.com/da-moon/nomad-cluster-playbook).

to get started with waypoint server , you need to set `NOMAD_ADDR` environment variable so that waypoint knows how to comminucate with nomad.
To select a single nomad server's IP address. you can either use `lxc ls` to find the ip address or use the following snippet :

```bash
lxc list --format json | jq -r '.[] | select((.name | contains ("server")) and (.status=="Running")).state.network.eth0.addresses|.[] | select(.family=="inet").address' | head -n 1
```

assuming our nomad server's internal IP address (the one assigned by lxd ) is `10.33.235.43`, the following will install waypoint server : 

```bash
NOMAD_ADDR="http://10.33.235.43:4646" waypoint install -platform=nomad --nomad-dc=dc1 -accept-tos
```


