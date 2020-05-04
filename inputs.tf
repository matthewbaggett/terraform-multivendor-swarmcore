variable "open_tcp_ports" {
  type    = list(number)
  default = []
}

variable "open_udp_ports" {
  type    = list(number)
  default = []
}

locals {
  mandatory_tcp_ports = [
    2377,
    7946,
    22
  ]
  mandatory_udp_ports = [
    7946,
    4789,
  ]
  tcp_ports = concat(local.mandatory_tcp_ports, var.open_tcp_ports)
  udp_ports = concat(local.mandatory_udp_ports, var.open_udp_ports)
}
