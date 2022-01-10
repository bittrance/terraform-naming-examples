variable "naming_config" {
    type = object({
        template: map(any)
        query: map(any)
    })
}