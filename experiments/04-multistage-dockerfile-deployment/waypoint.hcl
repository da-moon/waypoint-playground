project = "waypoint-http-echo-example"
app "waypoint-http-echo-example" {
  labels = {
    "service" = "waypoint-http-echo-example",
  }
  build {
    hook {
      when = "before"
      command = ["./build.sh"]
    }
    use "docker-pull" {
        image = "fjolsvin/upstream-gen"
        tag = "latest"
        encoded_auth = file("~/.docker_auth")
    }
    registry {
      use "docker" {
        image = "fjolsvin/waypoint-http-echo-example"
        tag = "latest"
        encoded_auth = file("~/.docker_auth")
      }
    }
  }
  deploy {
    use "nomad" {
      datacenter = "dc1"
      region = "global"
      replicas = 1
      service_port = 9090
    }
  }
}