#!/bin/bash

# Azure VNet, VM, Peering, and Bastion Setup Script
# This script creates:
# - First VNet with a subnet and VM
# - Second VNet with Bastion service
# - VNet peering between both VNets

set -e  # Exit on error

# ============================================================================
# VARIABLES - Customize these according to your requirements
# ============================================================================

# Resource Group Configuration
RESOURCE_GROUP="rg-azure-training"
LOCATION="eastus"

# First VNet Configuration (VM VNet)
VNET1_NAME="vnet-vm"
VNET1_CIDR="10.0.0.0/16"
SUBNET1_NAME="subnet-vm"
SUBNET1_CIDR="10.0.1.0/24"

# Second VNet Configuration (Bastion VNet)
VNET2_NAME="vnet-bastion"
VNET2_CIDR="10.1.0.0/16"
SUBNET2_NAME="subnet-workload"
SUBNET2_CIDR="10.1.1.0/24"
BASTION_SUBNET_NAME="AzureBastionSubnet"  # Must be exactly this name
BASTION_SUBNET_CIDR="10.1.2.0/26"  # Minimum /26 required

# VM Configuration
VM_NAME="vm-training"
VM_SKU="Standard_B2s"
VM_IMAGE="Ubuntu2204"
VM_ADMIN_USERNAME="azureuser"

# Network Security Group
NSG_NAME="nsg-vm"

# Bastion Configuration
BASTION_NAME="bastion-training"
BASTION_PUBLIC_IP_NAME="pip-bastion"

# VNet Peering Names
PEERING_VNET1_TO_VNET2="peering-vm-to-bastion"
PEERING_VNET2_TO_VNET1="peering-bastion-to-vm"

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

echo "============================================"
echo "Azure Infrastructure Deployment Script"
echo "============================================"
echo ""

# Check if logged in to Azure
echo "Checking Azure login status..."
az account show > /dev/null 2>&1 || {
    echo "Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
}

echo "Logged in to Azure successfully."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION_ID"
echo ""

# ============================================================================
# Create Resource Group
# ============================================================================

echo "[1/9] Creating Resource Group: $RESOURCE_GROUP in $LOCATION..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

echo ""

# ============================================================================
# Create First VNet and Subnet (VM VNet)
# ============================================================================

echo "[2/9] Creating First VNet: $VNET1_NAME with CIDR $VNET1_CIDR..."
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET1_NAME" \
    --address-prefix "$VNET1_CIDR" \
    --subnet-name "$SUBNET1_NAME" \
    --subnet-prefix "$SUBNET1_CIDR" \
    --output table

echo ""

# ============================================================================
# Create Network Security Group
# ============================================================================

echo "[3/9] Creating Network Security Group: $NSG_NAME..."
az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NSG_NAME" \
    --output table

# Add NSG rules (SSH from Bastion VNet)
echo "Adding NSG rule to allow SSH from Bastion VNet..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowSSHFromBastion" \
    --priority 1000 \
    --source-address-prefixes "$VNET2_CIDR" \
    --destination-port-ranges 22 \
    --protocol Tcp \
    --access Allow \
    --output table

# Associate NSG with subnet
echo "Associating NSG with subnet..."
az network vnet subnet update \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET1_NAME" \
    --name "$SUBNET1_NAME" \
    --network-security-group "$NSG_NAME" \
    --output table

echo ""

# ============================================================================
# Create Virtual Machine
# ============================================================================

echo "[4/9] Creating Virtual Machine: $VM_NAME with SKU $VM_SKU..."
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --vnet-name "$VNET1_NAME" \
    --subnet "$SUBNET1_NAME" \
    --image "$VM_IMAGE" \
    --size "$VM_SKU" \
    --admin-username "$VM_ADMIN_USERNAME" \
    --generate-ssh-keys \
    --public-ip-address "" \
    --nsg "" \
    --output table

# Note: --public-ip-address "" disables public IP creation (access via Bastion only)
# Note: --nsg "" prevents automatic NSG creation (we manually created and associated NSG)

echo ""

# ============================================================================
# Create Second VNet with Subnets (Bastion VNet)
# ============================================================================

echo "[5/9] Creating Second VNet: $VNET2_NAME with CIDR $VNET2_CIDR..."
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET2_NAME" \
    --address-prefix "$VNET2_CIDR" \
    --subnet-name "$SUBNET2_NAME" \
    --subnet-prefix "$SUBNET2_CIDR" \
    --output table

# Create AzureBastionSubnet
echo "Creating Azure Bastion Subnet..."
az network vnet subnet create \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET2_NAME" \
    --name "$BASTION_SUBNET_NAME" \
    --address-prefix "$BASTION_SUBNET_CIDR" \
    --output table

echo ""

# ============================================================================
# Create VNet Peering (Bidirectional)
# ============================================================================

echo "[6/9] Creating VNet Peering from $VNET1_NAME to $VNET2_NAME..."
az network vnet peering create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PEERING_VNET1_TO_VNET2" \
    --vnet-name "$VNET1_NAME" \
    --remote-vnet "$VNET2_NAME" \
    --allow-vnet-access \
    --output table

echo "Creating VNet Peering from $VNET2_NAME to $VNET1_NAME..."
az network vnet peering create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PEERING_VNET2_TO_VNET1" \
    --vnet-name "$VNET2_NAME" \
    --remote-vnet "$VNET1_NAME" \
    --allow-vnet-access \
    --output table

echo ""

# ============================================================================
# Create Public IP for Bastion
# ============================================================================

echo "[7/9] Creating Public IP for Bastion: $BASTION_PUBLIC_IP_NAME..."
az network public-ip create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BASTION_PUBLIC_IP_NAME" \
    --location "$LOCATION" \
    --sku Standard \
    --allocation-method Static \
    --output table

echo ""

# ============================================================================
# Create Azure Bastion
# ============================================================================

echo "[8/9] Creating Azure Bastion: $BASTION_NAME..."
echo "Note: This may take 5-10 minutes to complete..."
az network bastion create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BASTION_NAME" \
    --public-ip-address "$BASTION_PUBLIC_IP_NAME" \
    --vnet-name "$VNET2_NAME" \
    --location "$LOCATION" \
    --output table

echo ""

# ============================================================================
# Display Summary
# ============================================================================

echo "[9/9] Deployment Summary"
echo "============================================"
echo "Resource Group: $RESOURCE_GROUP"
echo ""
echo "First VNet (VM VNet):"
echo "  - VNet Name: $VNET1_NAME"
echo "  - VNet CIDR: $VNET1_CIDR"
echo "  - Subnet Name: $SUBNET1_NAME"
echo "  - Subnet CIDR: $SUBNET1_CIDR"
echo ""

# Retrieve VM private IP
VM_PRIVATE_IP=$(az vm show -d -g "$RESOURCE_GROUP" -n "$VM_NAME" --query privateIps -o tsv 2>/dev/null || echo "N/A")

echo "Virtual Machine:"
echo "  - VM Name: $VM_NAME"
echo "  - VM SKU: $VM_SKU"
echo "  - Admin Username: $VM_ADMIN_USERNAME"
echo "  - Private IP: $VM_PRIVATE_IP"
echo ""
echo "Second VNet (Bastion VNet):"
echo "  - VNet Name: $VNET2_NAME"
echo "  - VNet CIDR: $VNET2_CIDR"
echo "  - Workload Subnet: $SUBNET2_NAME ($SUBNET2_CIDR)"
echo "  - Bastion Subnet: $BASTION_SUBNET_NAME ($BASTION_SUBNET_CIDR)"
echo ""
echo "VNet Peering:"
echo "  - $VNET1_NAME <-> $VNET2_NAME (Connected)"
echo ""

# Retrieve Bastion public IP
BASTION_PUBLIC_IP=$(az network public-ip show -g "$RESOURCE_GROUP" -n "$BASTION_PUBLIC_IP_NAME" --query ipAddress -o tsv 2>/dev/null || echo "N/A")

echo "Azure Bastion:"
echo "  - Bastion Name: $BASTION_NAME"
echo "  - Bastion Public IP: $BASTION_PUBLIC_IP"
echo ""
echo "============================================"
echo "Deployment completed successfully!"
echo "============================================"
echo ""
echo "Next Steps:"
echo "1. Access the VM via Azure Bastion from the Azure Portal"
echo "2. Navigate to the VM resource and click 'Connect' -> 'Bastion'"
echo "3. Enter credentials: Username: $VM_ADMIN_USERNAME"
echo ""
