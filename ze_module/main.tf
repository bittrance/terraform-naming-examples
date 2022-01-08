terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
  }
}

resource "local_file" "resource_1" {
    filename = "/tmp/prt-we-xen-1"
    content = "this"
}

resource "local_file" "resource_2" {
    filename = "/tmp/prt-we-xen-2"
    content = "that"
}