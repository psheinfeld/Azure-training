# Azure Infrastructure Configuration
# Copy this file and customize the variables for your deployment
# Then update the corresponding variables in azure-vnet-vm-bastion-setup.sh

# ============================================================================
# Resource Group Configuration
# ============================================================================
RESOURCE_GROUP="rg-azure-training"
LOCATION="eastus"                    # Options: eastus, westus2, northeurope, etc.

# ============================================================================
# First VNet Configuration (VM VNet)
# ============================================================================
VNET1_NAME="vnet-vm"
VNET1_CIDR="10.0.0.0/16"
SUBNET1_NAME="subnet-vm"
SUBNET1_CIDR="10.0.1.0/24"

# ============================================================================
# Second VNet Configuration (Bastion VNet)
# ============================================================================
VNET2_NAME="vnet-bastion"
VNET2_CIDR="10.1.0.0/16"
SUBNET2_NAME="subnet-workload"
SUBNET2_CIDR="10.1.1.0/24"
BASTION_SUBNET_NAME="AzureBastionSubnet"  # Must be exactly this name
BASTION_SUBNET_CIDR="10.1.2.0/26"         # Minimum /26 required for Bastion

# ============================================================================
# Virtual Machine Configuration
# ============================================================================
VM_NAME="vm-training"
VM_SKU="Standard_B2s"                # VM size - see Azure VM sizes documentation
VM_IMAGE="Ubuntu2204"                # Options: Ubuntu2204, Ubuntu2004, Win2022Datacenter, etc.
VM_ADMIN_USERNAME="azureuser"

# Common VM SKU Options:
# - Standard_B1s   : 1 vCPU, 1 GB RAM (cheapest, ~$8/month)
# - Standard_B2s   : 2 vCPU, 4 GB RAM (recommended for dev/test, ~$30/month)
# - Standard_D2s_v3: 2 vCPU, 8 GB RAM (general purpose, ~$70/month)
# - Standard_D4s_v3: 4 vCPU, 16 GB RAM (more powerful, ~$140/month)

# ============================================================================
# Network Security Group
# ============================================================================
NSG_NAME="nsg-vm"

# ============================================================================
# Bastion Configuration
# ============================================================================
BASTION_NAME="bastion-training"
BASTION_PUBLIC_IP_NAME="pip-bastion"

# ============================================================================
# VNet Peering Configuration
# ============================================================================
PEERING_VNET1_TO_VNET2="peering-vm-to-bastion"
PEERING_VNET2_TO_VNET1="peering-bastion-to-vm"

# ============================================================================
# Notes:
# ============================================================================
# 1. Ensure CIDR ranges do not overlap between VNets
# 2. Bastion subnet must be named exactly "AzureBastionSubnet"
# 3. Bastion subnet must be at least /26 (64 addresses)
# 4. All resources will be created in the same resource group and location
# 5. VM will not have a public IP (access via Bastion only)
