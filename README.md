# How to generalize resource naming in shared modules

WIP.

## Scenario

Several parties share a module, and they have conflicting requirements on how the resources are named. The module is maintained in cooperation (or even by a third-party) so requiring the caller to provide explicit names for each resource is not maintainable. The caller will want to provide a set of rules (templates?) for how resources should be named without having to know exactly what resources will be named.

Consider a module for a bastion host which wants to create an AWS security group:

```
resource "aws_security_group" "sg" {
  name = "bastion"
  # ...
}
```

Consider a user of the module which wants to have more than one bastion in the same region; the user might want to prefix the name with something saying what domain or system the bastion serves, or it may just want a numerical prefix.

## Analysis

Looking at the https://github.com/XenitAB/terraform-modules, here is a list of naming patterns that are used:

| Resource        | pattern                                                                           |
| --------------- | --------------------------------------------------------------------------------- |
| AKS cluster     | "aks-${environment}-${location_short}-${name}${aks_name_suffix}"                  |
| Azure metric    | "uai-${environment}-${location_short}-${name}-azure-metrics"                      |
| RG              | "rg-${environment}-${location_short}-${name}"                                     |
| Subnet          | "sn-${environment}-${location_short}-${core_name}-${name}${aks_name_suffix}"      |
| SSH private key | "ssh-priv-${environment}-${location_short}-${name}"                               |
| VMSS            | "vmss-${environment}-${location_short}-${name}"                                   |
| nsg             | "nsg-${environment}-${location_short}-${name}-${each.value.subnet_short_name}"    |
| AD app          | "${service_principal_name_prefix}-sub-${subscription_name}-${environment}-reader" |
| AD Group        | "${azure_ad_group_prefix}-sub-${subscription_name}-${environment}-join"           |

Module knows:

- resource type (e.g. security group)
- template type (e.g. Azure resource, Storage account, et.c.)
- some components

Caller knows:

- template definition(s)
- some components

## Proof-of-concept

This repo uses Hashicorp's [external](https://registry.terraform.io/providers/hashicorp/external/latest) provider and write a small tool that templates the name. The tool would read the "shared" parts of the configuration from an external configuration (presumably a `jsonencode`d string) and would read the resource-specifc parts from the data source's `query` block.

```hcl
data "external" "sgname" {
  program = ["./naming-templater", "--template", "standard", "--config", jsonencode(var.naming_config)]
  query = {
    group = "bastion"
    resource = "sg"
  }
}

resource "aws_security_group" "sg" {
  name = data.external.sgname.result.name
  # ...
}
```

When invoking the module, you would pass a `naming_config` in the `module` invocation:

```hcl
module "caller_2" {
  source = "./ze_module"
  naming_config = {
    # Each resource picks a template to use
    templates = {
      standard = "%(region)s-%(group)s-%(resource)s-%(unit)s"
      bucketname = "%(group)s%(resource)s%(unit)s"
    }
    query = {
      # The invocation can add (and override) parameters
      region = "we"
    }
  }
}
```

The above example keeps things simple. In practice, the caller may want to maintain a centralizes `naming_config` and the module may want to provide defaults for it so that the caller only needs to add parameters when they differ from the default.

Cons:

- assumes there is a limited number of naming schemes
- annoying extra `result` in property
- program is not run as a shell, so needs either to be prefixed by e.g. `bash` or to be a compiled (platform-dependent) binary; it might be desirable to use a variable and construct the list in one place for the module.

## Full solution

The proof-of-concept should be properly implemented as a provider, but the actual HCL is essentially the same:

```hcl
data "naming_provider" "sgname" {
  template_name = "standard"
  query = {
    group = "bastion"
    resource = "sg"
  }
}

resource "aws_security_group" "sg" {
  name = data.naming_provider.name
  # ...
}
```

Invocation:

```hcl
provider "naming_provider" {
  templates = {
    standard = "%(region)s-%(group)s-%(resource)s-%(unit)s"
    bucketname = "%(group)s%(resource)s%(unit)s"
  }
  query = {
    region = "we"
  }
}

module "caller_1" {
  source = "./ze_module"
}
```

In order to have multiple naming provider configurations, you can use the [providers meta-argument](https://www.terraform.io/language/meta-arguments/module-provider.)
