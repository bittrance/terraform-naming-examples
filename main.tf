module "caller_1" {
    source = "./ze_module"
    naming_config = {
        template = "%(region)s-%(resource)s-%(group)s-%(unit)s"
        query = {
            region = "we"
        }
    }
}

module "caller_2" {
    source = "./ze_module"
    naming_config = {
        template = "%(group)s-%(resource)s-%(unit)s"
        query = {}
    }
}