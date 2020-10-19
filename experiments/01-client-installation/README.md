
# installing Waypoint

Hashicorp [`Waypoint`](https://www.waypointproject.io/downloads) is a statically compiled go application and it can be installed whether through package managers or through downloading and unpacking the binary.

For the sake of universality, we will download and extract the binary rather than using package managers.

- the following snippet extracts the latest version of waypoint

```bash
curl -sL https://releases.hashicorp.com/waypoint/index.json | \
jq -r '.versions[].version' | \
sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
grep -E -v 'ent|rc|beta' | \
tail -1
```

we will combine the previous snippet with `xargs` and `wget` to download latest version of `waypoint` and store it under `/usr/local/bin`, in users `PATH`.

```bash
curl -sL https://releases.hashicorp.com/waypoint/index.json | \
jq -r '.versions[].version' | \
sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
grep -E -v 'ent|rc|beta' | \
tail -1 | xargs -n 1 -I {} \
sudo wget -q -O /usr/local/bin/waypoint.zip "https://releases.hashicorp.com/waypoint/{}/waypoint_{}_linux_amd64.zip" && \
sudo unzip -q -d /usr/local/bin /usr/local/bin/waypoint.zip && \
sudo rm /usr/local/bin/waypoint.zip && \
waypoint version
```

keep in mind the above snippet can also be embedded in a single `RUN` statement of a dockerfile.
