# configuration

## overview

waypoint configuration file is a single `waypoint.hcl` file in project's root.

`project` directive is used to set project name and every deployable application has it's own  `app` stanza.

every `app` stanza has a required `build` and `deploy` level-1 sub-stanzas and an optional level-1 `release` sub-stanza.

`hook` level-2 substanza can be used to run a command before or after any operation in `build`, `registry`, `deploy`, and `release` sub-stanzas.

```
app -> build -> hook
app -> build -> registry -> hook
app -> deploy -> hook
app -> release -> hook
```

## build

takes application source and converts it to an artifact. 

while they are many different build plugins, `docker` and CloudNative `Buildpacks` are most common.

in case there are artifacts that you want to store, you can use optional `registry` sub-stanza in `build` and store the artifact in a registry so that it is available for the deployment platform. as an example, there is `docker` registry which would push the image to a docker compatible registry.


```hcl
build {
  use "docker" {
  # buildkit    = false
  # disable_entrypoint = false
  }
  # [NOTE] => docker-pull can use an existing image
  # and inject waypoint entrypoint init
  # use "docker-pull" {
  #   image = "gcr.io/my-project/my-image"
  #   tag   = "abcd1234"
  # }
  # registry {
  #   use "docker" {
  #     image = "hashicorp/http-echo"
  #     tag   = gitrefpretty()
  #   }
  # }
  hook {
    when = "before"
    command = ["./audit-log.sh", "build starting"]
    on_failure = "continue"
  }
  hook {
    when = "after"
    command = ["./audit-log.sh", "build finished"]
  }

}
```

## deploy

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

## release

an optional stanza that activates a previously staged deployment and opens it to general traffic.
most release plugins at this point are specific to cloud providers. at this point there is only kubernetes release plugin available.

## example ruby app deployment

for our example, we will use hashicorp's example ruby app for deployment.

```bash
git clone https://github.com/hashicorp/waypoint-examples.git /tmp/waypoint-examples && \
pushd /tmp/waypoint-examples/docker/ruby && \
cat << EOF | tee waypoint.hcl
project = "example-ruby"
app "example-ruby" {
  labels = {
    "service" = "example-ruby",
    "env" = "dev"
  }
  build {
    use "pack" {}
    registry {
      use "docker" {
        image = "example-ruby"
        tag = "1"
        local = true
      }
    }
  }
  deploy {
    use "nomad" {
      datacenter = "dc1"
    }
  }
}
EOF
waypoint init && \
waypoint up
```

## reference

- [docker plugin](https://www.waypointproject.io/plugins/docker)
- [cloud native plugin](https://www.waypointproject.io/plugins/pack)
- [nomad plugin](https://www.waypointproject.io/plugins/nomad)
- [exec plugin](https://www.waypointproject.io/plugins/exec)