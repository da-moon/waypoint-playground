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
  registry {
    use "docker" {
      image = "hashicorp/http-echo"
      tag   = gitrefpretty()
      # => builds the image locally ( on the machine that has waypoint client running) without pushing it to remote registry
      local = true
    }
  }
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