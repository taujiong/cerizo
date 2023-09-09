terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~>5"
    }
  }
}

variable "oci_tenancy_ocid" {
  type = string
}

variable "oci_user_ocid" {
  type = string
}

variable "oci_private_key" {
  type      = string
  sensitive = true
}

variable "oci_private_key_password" {
  type      = string
  sensitive = true
}

variable "oci_fingerprint" {
  type      = string
  sensitive = true
}

variable "oci_region" {
  type = string
}

variable "oci_availablity_domain" {
  type = string
}

variable "oci_instance_shape" {
  type    = string
  default = "VM.Standard.E2.1.Micro"
}

variable "oci_ssh_key" {
  type      = string
  sensitive = true
}

provider "oci" {
  tenancy_ocid         = var.oci_tenancy_ocid
  user_ocid            = var.oci_user_ocid
  private_key          = var.oci_private_key
  private_key_password = var.oci_private_key_password
  fingerprint          = var.oci_fingerprint
  region               = var.oci_region
}

resource "oci_identity_compartment" "default" {
  compartment_id = var.oci_tenancy_ocid
  name           = "terraform"
  description    = "resources managed by terraform"
  enable_delete  = true
}

locals {
  compartment_id = oci_identity_compartment.default.id
}

resource "oci_core_vcn" "default" {
  compartment_id = local.compartment_id
  display_name   = "default_vcn"
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_default_security_list" "default" {
  manage_default_resource_id = oci_core_vcn.default.default_security_list_id
  ingress_security_rules {
    description = "allow ssh"
    protocol    = "6"
    source_type = "CIDR_BLOCK"
    source      = "0.0.0.0/0"
    tcp_options {
      max = 22
      min = 22
    }
  }
  ingress_security_rules {
    description = "allow icmp"
    protocol    = "1"
    source_type = "CIDR_BLOCK"
    source      = "0.0.0.0/0"
    icmp_options {
      code = 4
      type = 3
    }
  }
}

resource "oci_core_subnet" "default" {
  compartment_id = local.compartment_id
  vcn_id         = oci_core_vcn.default.id
  cidr_block     = "10.0.0.0/16"
}

data "oci_core_images" "ubuntu-latest" {
  compartment_id           = local.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.oci_instance_shape
  sort_by                  = "TIMECREATED"
}

resource "oci_core_instance" "oracle-server1" {
  compartment_id      = local.compartment_id
  display_name        = "oracle-server1"
  availability_domain = var.oci_availablity_domain
  shape               = var.oci_instance_shape
  source_details {
    boot_volume_size_in_gbs = "100"
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu-latest.images[0].id
  }
  metadata = {
    "ssh_authorized_keys" = var.oci_ssh_key
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.default.id
  }
}
