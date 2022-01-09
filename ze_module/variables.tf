variable "naming_config" {
    type = object({
        template: string
        query: map(any)
    })
}