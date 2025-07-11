terraform {
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
      version = ">= 1.11.0" # Recommended to specify version
    }
  }
}

provider "fortios" {
  hostname = "192.168.29.215"
  token    = "m85387nprg7cf71m11kwbm0x7zky0d"
  insecure = "true" # Only for lab environments
}

resource "fortios_vpnipsec_phase1interface" "FG-to-PanOS-PH1" {

  add_route                 = "enable"
  authmethod                = "psk"
  auto_negotiate            = "enable"
  dhgrp                     = "2"
  dpd                       = "on-demand"
  dpd_retrycount            = 3
  dpd_retryinterval         = "20"
  ike_version               = "1"
  interface                 = "port2"
  keepalive                 = 10
  keylife                   = 86400
  mode                      = "main"
  name                      = "FG-PanOS-PH1"
  nattraversal              = "disable"
  negotiate_timeout         = 30
  proposal                  = "des-sha1"
  psksecret                 = "Aryan@15"
  remote_gw                 = "192.168.29.110"
  type                      = "static"
  wizard_type               = "custom"
  xauthtype                 = "disable"
}

resource "fortios_vpnipsec_phase2interface" "FG-to-PanOS-PH2" {

  auto_negotiate           = "enable"
  dhgrp                    = "2"
  dst_addr_type            = "subnet"
  dst_subnet               = "30.30.30.0 255.255.255.0"
  name                     = "FG-to-PanOS"
  pfs                      = "enable"
  phase1name               = fortios_vpnipsec_phase1interface.FG-to-PanOS-PH1.name
  proposal                 = "des-sha1"
  src_addr_type            = "subnet"
  src_subnet               = "10.10.10.0 255.255.255.0"
}

resource "fortios_router_static" "Default-route" {

  dst = "192.168.29.0 255.255.255.0"
  dynamic_gateway = "enable"
  status = "enable"
  device = "port2"
  comment = "Default Gateway for VPN"

}

resource "fortios_router_static" "VPN-route_PanOS" {

  dst = "30.30.30.0 255.255.255.0"
  dynamic_gateway = "disable"
  status = "enable"
  device = "FG-PanOS-PH1"
  comment = "Host Route towards PaloAlto"

}

resource "fortios_firewall_policy" "VPN-OUT" {

  name               = "VPN_Inside-PaloAlto"
  action             = "accept"
  logtraffic         = "all"
  schedule           = "always"

  dstaddr {
    name = "all"
  }

  dstintf {
    name = "FG-PanOS-PH1"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "VM-NET-1"
  }

  srcintf {
    name = "port3"
  }
}



resource "fortios_firewall_policy" "VPN-IN" {

  name               = "VPN_PaloAlto-Inside"
  action             = "accept"
  logtraffic         = "all"
  schedule           = "always"

  dstaddr {
    name = "VM-NET-1"
  }

  dstintf {
    name = "port3"
  }

  service {
    name = "ALL"
  }

  srcaddr {
    name = "all"
  }

  srcintf {
    name = "FG-PanOS-PH1"
  }
}
