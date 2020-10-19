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