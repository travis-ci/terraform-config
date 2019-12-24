
resource "ibm_is_vpc" "vpc" {
    name           = "${var.basename}-vpc"
    resource_group = "cdcff1f7d63b4dfcb6b5ca5306b7c7c2"
}

resource "ibm_is_public_gateway" "gw" {
    name = "${var.basename}-gw"
    vpc = "${ibm_is_vpc.vpc.id}"
    zone = "${var.ibmcloud_zone}"

    timeouts {
        create = "90m"
    }
}

resource "ibm_is_subnet" "subnet" {
    name            = "${var.basename}-subnet"
    vpc             = "${ibm_is_vpc.vpc.id}"
    zone            = "${var.ibmcloud_zone}"
    ip_version      = "ipv4"
    ipv4_cidr_block = "${var.ipv4_cidr_block}"
    public_gateway  = "${ibm_is_public_gateway.gw.id}"
}

resource "ibm_is_security_group_rule" "sg1-tcp-rule" {
    #depends_on = ["ibm_is_floating_ip.worker"]
    group      = "${ibm_is_vpc.vpc.default_security_group}"
    direction  = "inbound"
    remote     = "${var.allowed_ips}"

    tcp = {
        port_min = 22
        port_max = 22
    }
}

resource "ibm_is_security_group_rule" "sg2-tcp-rule" {
    #depends_on = ["ibm_is_floating_ip.worker"]
    group      = "${ibm_is_vpc.vpc.default_security_group}"
    direction  = "inbound"
    remote     = "140.211.169.0/24"

    tcp = {
        port_min = 4505
        port_max = 4506
    }
}
