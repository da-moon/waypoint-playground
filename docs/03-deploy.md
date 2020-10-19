# deploy

A deploy takes a previously built artifact and stages it onto the target deployment platform. each plugin supports a set of builders. for our purposes, we use `nomad` for deployment which uses Docker images for building and supports `docker` and `pack` (Cloud Native Buildpacks) plugins.

all directives in `nomad` stanza are optional. the following is an example with all of them

```hcl
deploy {
    use "nomad" {
      # => default : dc1
      datacenter = "dc1"
      # => nomad enterprise feature
      namespace = "ns1"
      # => default : global
      region = "global"
      # => default : 1
      replicas = 1
      service_port = 3000
      static_environment = {
        "environment": "production",
        "LOG_LEVEL": "debug"
      }
    }
}
```

another useful plugin for deployment is `exec` which essentially Execute any command to perform a deploy.
This plugin lets you use almost any pre-existing deployment tool for the deploy step of waypoint.

for instance, `exec` can be used to run a docker image 

```hcl
deploy {
  use "exec" {
    # the following template values are always available:
    # - {{ .Env }} : environment variables that should be set on the deployed workload
    # - {{ .Workspace }} : workspace name that the waypoint deploy is running in.
    # --------------------------------------------------------------
    # => in case build steps makes a docker images, the following template variables are available
    # - {{.Input.DockerImageFull}} -> The full Docker image name and tag.
    # - {{.Input.DockerImageName}} -> The Docker image name, without the tag.
    # - {{.Input.DockerImageTag}}  -> The Docker image tag.

    command = ["docker", "run", "{{.Input.DockerImageFull}}"]

    # [OPTIONAL] => working directory to use while executing the command.

    dir="/opt/artifact/"
  }
}
```