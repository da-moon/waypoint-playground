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

```bash
### terminal ###
# => lets set NOMAD_ADDR env var since 'waypoint up' comand needs it
export NOMAD_ADDR="http://10.33.235.43:4646"
# => in this demo, we will use waypoint's "pack" build plugin to build and deploy a ruby application
# => lets pull 'heroku/buildpacks:18' docker image in advance to speed up build
docker pull 'heroku/buildpacks:18'
docker images
# => the ruby app we are making is part of hashicorp's examples repo.
# => let's clone the repo
rm -rf /tmp/waypoint-examples && git clone https://github.com/hashicorp/waypoint-examples.git /tmp/waypoint-examples
# => let's go to the ruby apps main directory
pushd /tmp/waypoint-examples/docker/ruby
ls -lah
# => as you can see this repo already has a Procfile
# => procfiles are used to customize cloudnative buildpack piplines
cat Procfile
# => lets also take a look at Rakefile contents
cat Rakefile
# => to make deploying on nomad cluster work , we must modify and overwrite the already existing 'waypoint.hcl'
# => lets take a look at it before modifying it
cat waypoint.hcl
# => lets overwrite the file
rm waypoint.hcl && cp ~/waypoint-playground/experiments/03-cloud-native-buildpack-deployment/waypoint.hcl waypoint.hcl
# => lets open the file and confirm the overwrite
cat waypoint.hcl
# => keep in mind that you need a X-Registry-Auth token. The accompanying markdown file shows how to generate one. I have already generated and stored my token in ~/.docker_auth
# => lets confirm nomad allocations
nomad job status
nomad job status waypoint-server
# => initilizing project
waypoint init
# => deploying project
waypoint up
# => lets checkout nomad deployments again
nomad job status
nomad job status waypoint-server
nomad job status waypoint-ruby-example
# => lets checkout waypoint logs
waypoint logs
popd
### end ###
```

## reference

- [docker plugin](https://www.waypointproject.io/plugins/docker)
- [cloud native plugin](https://www.waypointproject.io/plugins/pack)
- [nomad plugin](https://www.waypointproject.io/plugins/nomad)
- [exec plugin](https://www.waypointproject.io/plugins/exec)
- [procfile format](https://devcenter.heroku.com/articles/procfile#procfile-format)