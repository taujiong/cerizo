terraform {
  required_providers {
    oci = {
        source = "oracle/oci"
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
  type = string
  sensitive = true
}

variable "oci_private_key_password" {
  type = string
  sensitive = true
}

variable "oci_fingerprint" {
  type = string
  sensitive = true
}

variable "oci_region" {
  type = string
}

provider "oci" {
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid = var.oci_user_ocid
  private_key = var.oci_private_key
  private_key_password = var.oci_private_key_password
  fingerprint = var.oci_fingerprint
  region = var.oci_region
}

resource "oci_identity_compartment" "terraform" {
  compartment_id = var.oci_tenancy_ocid
  name = "terraform"
  description = "resources managed by terraform"
  enable_delete = true
}
