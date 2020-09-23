variable "subnets" {
  description = "Map from availability zone to the number that should be used for each availability zone's subnet"
  default = {
    "eu-west-2a" = 1
    "eu-west-2b" = 2
    "eu-west-3c" = 3
  }
}

variable "newbits" {
  description = ""
  default     = 4
}

variable "nats" {
    description = ""
    default = {
        "eu-west-2a" = 1
    }
}
