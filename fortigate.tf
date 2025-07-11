# Configure the FortiOS Provider for FortiGate
terraform {
  required_providers {
    fortios = {
      source  = "fortinetdev/fortios"
    }
  }
}

provider "fortios" {
  hostname     = "192.168.29.215"
  token        = "m85387nprg7cf71m11kwbm0x7zky0d"
  insecure     = "true"
}





resource "fortios_system_interface" "Management" {
  algorithm    = "L4"
  defaultgw    = "enable"
  distance     = 5
  mtu          = 1500
  mtu_override = "disable"
  name         = "port1"
  type         = "physical"
  vdom         = "root"
  mode         = "dhcp"
  snmp_index   = 3
  description  = "Management"
  allowaccess  = "https ssh ping"
  status       = "up" 
  ipv6 {
    nd_mode = "basic"
  }
}


resource "fortios_system_interface" "Internet-wan" {
  algorithm    = "L4"
  defaultgw    = "enable"
  distance     = 5
  mtu          = 1500
  mtu_override = "disable"
  name         = "port2"
  type         = "physical"
  vdom         = "root"
  mode         = "dhcp"
  snmp_index   = 3
  description  = "Internet"
  role         = "wan"
  allowaccess  = "https ssh ping"
  status       = "up" 
  ipv6 {
    nd_mode = "basic"
  }
}


resource "fortios_system_interface" "Inside-LAN" {
  algorithm    = "L4"
  defaultgw    = "enable"
  distance     = 5
  ip           = "10.10.10.100 255.255.255.0"
  mtu          = 1500
  mtu_override = "disable"
  name         = "port3"
  type         = "physical"
  vdom         = "root"
  mode         = "static"
  snmp_index   = 3
  description  = "Created by Terraform Provider for FortiOS"
  role         = "lan"
  allowaccess  = "https ssh ping"
  status       = "up" 
  ipv6 {
    nd_mode = "basic"
  }
}




resource "fortios_firewall_address" "LAN-Address" {
  allow_routing        = "disable"
  associated_interface = "port3"
  color                = "3"
  end_ip               = "255.255.255.0"
  name                 = "LAN VM-NET-1"
  start_ip             = "10.10.10.100"
  subnet               = "10.10.10.0 255.255.255.0"
  type                 = "ipmask"
  visibility           = "enable"
}


resource "fortios_router_static" "Default-Route" {
  dst                 = "0.0.0.0 0.0.0.0"
  dynamic_gateway     = "enable"
  device              = "port2"
  status              = "enable"
  comment             = "Default Route"
}



resource "fortios_firewallservice_group" "Internet-services" {
  color = 5
  name  = "Internet-services"
  proxy = "disable"

  member {
    name = "HTTPS"
  }
  member {
    name = "HTTP"
  }
  member {
    name = "DNS"
  }
  member {
    name = "ALL_ICMP"
  }
  member {
    name = "PING"
  }
  member {
    name = "SSH"
  }
}


 resource "fortios_vpn_ipsec_phase1interface" "FG-PanOS-PH1" {
  name        = "FG-to-PanOS"
  type        = "static"
  remote_gw   = "192.168.29.110"
  interface   = "port2"
  authmethod  = "psk"
  psksecret   = "Aryan@15"
  proposal    = "des-sha1"
  wizard_type = "custom"

}

resource "fortios_vpn_ipsec_phase2interface" "FG-to-PanOS-PH2" {
  name          = "FG-PanOS"
  phase1name    = fortios_vpn_ipsec_phase1interface.FG-PanOS-PH1.name
  proposal      = "des-sha1"
  src_addr_type = "subnet"
  src_subnet    = "10.10.10.0 255.255.255.0"
  dst_addr_type = "subnet"
  dst_subnet    = "30.30.30.0 255.255.255.0"
}


resource "fortios_firewall_policy" "VPN-Outside" {
  name       = "LAN to VPN"
  policyid   = 2
  action     = "accept"
  logtraffic = "all"
  logtraffic_start = "enable"
  schedule   = "always"

  srcaddr {
    name = "LAN VM-NET-1"
  }
  srcintf {
    name = "port3"
  }
  dstaddr {
    name = "Remote LAN VPN"
  }
  dstintf {
    name = "FG-to-PanOS"  
  }
  
  service {
    name = "ALL_ICMP"
  }
  service {
    name = "RDP"
  }

  nat = "disable"
}

resource "fortios_firewall_policy" "VPN-Inside" {
  name       = "VPN to LAN"
  policyid   = 3
  action     = "accept"
  logtraffic = "all"
  logtraffic_start = "enable"
  schedule   = "always"

  srcaddr {
    name = "Remote LAN VPN"
  }
  srcintf {
    name = "FG-to-PanOS"
  }
  dstaddr {
    name = "LAN VM-NET-1"
  }
  dstintf {
    name = "port3"  
  }
  
  service {
    name = "ALL_ICMP"
  }
  service {
    name = "RDP"
  }

  nat = "disable"
}


resource "fortios_firewall_vip" "Virtual-IP_for_D-NAT" {
  name      = "D-NAT to Inside"
  color     = "7"
  arp_reply = "enable"
  extintf   = "port2"
  extip     = "192.168.29.216"

  mappedip {
    range = "10.10.10.10"
  }
}

resource "fortios_firewall_policy" "Internet-rule" {
  name       = "Internet Policy"
  policyid   = 1
  action     = "accept"
  logtraffic = "all"
  logtraffic_start = "enable"
  schedule   = "always"

  srcaddr {
    name = "LAN VM-NET-1"
  }
  srcintf {
    name = "port3"
  }
  dstaddr {
    name = "all"
  }
  dstintf {
    name = "port2"  
  }

  service {
    name = "Internet-services"
  }
  nat = "enable"
}

resource "fortios_router_static" "VPN-Route" {
  dst                 = "30.30.30.0 255.255.255.0"
  device              = "FG-to-PanOS"
  status              = "enable"
  comment             = "Route to VPN Remote LAN"
}


resource "fortios_firewall_address" "Remote-LAN" {
  allow_routing        = "disable"
  associated_interface = "FG-to-PanOS"
  color                = "4"
  end_ip               = "255.255.255.0"
  name                 = "Remote LAN VPN"
  start_ip             = "30.30.30.0"
  subnet_name          = "30.30.30.0 255.255.255.0"  
  type                 = "ipmask" 
  visibility           = "enable" 
}