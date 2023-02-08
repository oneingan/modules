variable "server_port" {
    description = "Server http port"
    type        = number
    default = 8080
}

variable "db_remote_state_bucket" {
  type = string
}

variable "db_remote_state_key" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}
