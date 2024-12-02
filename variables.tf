variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "instance_count" {
  type = number
}

variable "instance_type" {
  type = string
}
