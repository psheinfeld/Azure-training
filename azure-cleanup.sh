#!/bin/bash

# Azure Infrastructure Cleanup Script
# This script removes all resources created by azure-vnet-vm-bastion-setup.sh

set -e  # Exit on error

# ============================================================================
# VARIABLES - Must match the setup script
# ============================================================================

# Resource Group Configuration
RESOURCE_GROUP="rg-azure-training"

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

echo "============================================"
echo "Azure Infrastructure Cleanup Script"
echo "============================================"
echo ""

# Check if logged in to Azure
echo "Checking Azure login status..."
az account show > /dev/null 2>&1 || {
    echo "Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
}

echo "Logged in to Azure successfully."
echo ""

# Confirm deletion
echo "WARNING: This will delete the entire resource group: $RESOURCE_GROUP"
echo "This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# ============================================================================
# Delete Resource Group
# ============================================================================

echo "Deleting Resource Group: $RESOURCE_GROUP..."
echo "Note: This may take several minutes..."
echo ""

az group delete \
    --name "$RESOURCE_GROUP" \
    --yes \
    --no-wait

echo "Deletion initiated. The resource group will be removed in the background."
echo ""
echo "To check the status, run:"
echo "  az group show --name $RESOURCE_GROUP"
echo ""
echo "When the resource group no longer exists, the deletion is complete."
echo ""
