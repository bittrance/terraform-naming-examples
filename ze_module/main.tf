terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }

    external = {
      source = "hashicorp/external"
      version = "2.2.0"
    }
  }
}

data "external" "resource_1" {
  program = ["python", "./naming.py", jsonencode(var.naming_config)]
  query = {
    resource = "lf"
    group = "app"
    unit = "this"
  }
}

data "external" "resource_2" {
  program = ["python", "./naming.py", jsonencode(var.naming_config)]
  query = {
    resource = "lf"
    group = "app"
    unit = "that"
  }
}

resource "local_file" "resource_1" {
    filename = data.external.resource_1.result.name
    content = "this"
}

resource "local_file" "resource_2" {
    filename = data.external.resource_2.result.name
    content = "that"
}