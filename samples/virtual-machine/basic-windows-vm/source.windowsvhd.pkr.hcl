# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
source "azure-arm" "windowsvhd" {
  azure_tags = {
    sample = "basic-win-sample-vm"
  }
  os_type        = "Windows"
  communicator   = "winrm"
  winrm_username = "packer"
  winrm_timeout  = "10m"
  winrm_insecure = true
  winrm_use_ssl  = true

  # Input Image
  image_offer     = "${var.image.offer}"
  image_publisher = "${var.image.publisher}"
  image_sku       = "${var.image.sku}"
  image_version   = "${var.image.version}"

  # Build VM
  location                 = "${var.region}"
  temp_resource_group_name = "${var.temp_resource_group_name}"
  temp_compute_name        = "${var.temp_compute_name}"
  vm_size                  = "${var.vm_size}"

  # Output VHD, required by Marketplace
  use_azure_cli_auth     = true
  resource_group_name    = "${var.resource_group_name}"
  storage_account        = "${var.artifact_storage_account}"
  capture_container_name = "${var.artifact_storage_account_container}"
  capture_name_prefix    = "${var.image_vhd_name}"
}
