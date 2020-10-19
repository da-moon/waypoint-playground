
# cloud native buildpack deployment

one way to build project for deploying to nomad with docker builder plugin is to use CloudNative Buildpacks through `pack` builder plugin . by default , nomad uses `heroku/buildpacks:18` image which is based on `ubuntu bionic`. 

the main advantage of using cloudnative buildpacks is that these images have withstood the test of time and we know their build pipelines are stable. to customize builds, one must define a [`procfile`](https://devcenter.heroku.com/articles/procfile#procfile-format) and put it in repo's root.

for our example, we will use hashicorp's example ruby app for deployment which already has a procfile.

the only con that I can think of is that the created images are hardly minimal. as you would see in our example, the sample ruby app image is around `~850MB`.

to make sure the nomad client running the apllication container has access to image, you must use a remote docker image repository and push the created image in build step before deploy step. to have waypoint push the image to repository, you must use `encoded_auth` directive in `registry/docker` stanza which is the value stored in `X-Registry-Auth` header when pushing image to docker repostitory. for the sake of security, do not store raw value there and load it from a file.
to generate the encoded auth token and store it in `~/.docker_auth` running the following snippet : 

```bash
echo "{ \"username\": \"your-username\", \"password\": \"your-password\", \"email\": \"your-email@example.org\" }" | base64 --wrap=0 | tee ~/.docker_auth > /dev/null
```

you can now use the following snippet to clone the repo and build and deploy the image to your cluster

```bash
git clone https://github.com/hashicorp/waypoint-examples.git /tmp/waypoint-examples && \
pushd /tmp/waypoint-examples/docker/ruby && \
cat << EOF | sed -e '/^\s\s*$/d' -e "s/\(^.*$\)/echo '\1' | tee -a waypoint.hcl/g"
project = "waypoint-ruby-example"
app "waypoint-ruby-example" {
  labels = {
    "service" = "waypoint-ruby-example",
    "env" = "dev"
  }
  build {
    use "pack" {}
    registry {
      use "docker" {
        image = "fjolsvin/waypoint-ruby-example"
        tag = "latest"
        encoded_auth = file("~/.docker_auth")
      }
    }
  }
  deploy {
    use "nomad" {
      datacenter = "dc1"
      region = "global"
      replicas = 3
    }
  }
}
EOF
waypoint init && \
NOMAD_ADDR="http://10.33.235.43:4646" waypoint up && \
popd
```

## reference

- [docker plugin](https://www.waypointproject.io/plugins/docker)
- [cloud native plugin](https://www.waypointproject.io/plugins/pack)
- [nomad plugin](https://www.waypointproject.io/plugins/nomad)
- [exec plugin](https://www.waypointproject.io/plugins/exec)
- [procfile format](https://devcenter.heroku.com/articles/procfile#procfile-format)