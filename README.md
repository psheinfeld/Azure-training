# Azure-training

This repository contains Azure CLI scripts for setting up a complete network infrastructure with Virtual Networks, Virtual Machines, VNet Peering, and Azure Bastion service.

## 📋 Overview

The main script (`azure-vnet-vm-bastion-setup.sh`) automates the deployment of:

1. **First VNet** - Contains a VM subnet with a Linux virtual machine
2. **Second VNet** - Contains a workload subnet and Azure Bastion subnet
3. **VNet Peering** - Bidirectional peering between both VNets
4. **Azure Bastion** - Secure RDP/SSH connectivity without public IPs
5. **Network Security Group** - Controls inbound/outbound traffic to the VM

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Resource Group                          │
│                                                                   │
│  ┌──────────────────────┐         ┌──────────────────────────┐ │
│  │   VNet 1 (VM VNet)   │◄───────►│  VNet 2 (Bastion VNet)   │ │
│  │   10.0.0.0/16        │ Peering │   10.1.0.0/16            │ │
│  │                      │         │                          │ │
│  │  ┌────────────────┐  │         │  ┌────────────────────┐ │ │
│  │  │ VM Subnet      │  │         │  │ Workload Subnet    │ │ │
│  │  │ 10.0.1.0/24    │  │         │  │ 10.1.1.0/24        │ │ │
│  │  │                │  │         │  └────────────────────┘ │ │
│  │  │  ┌──────────┐  │  │         │                          │ │
│  │  │  │   VM     │  │  │         │  ┌────────────────────┐ │ │
│  │  │  └──────────┘  │  │         │  │ AzureBastionSubnet │ │ │
│  │  └────────────────┘  │         │  │ 10.1.2.0/26        │ │ │
│  │                      │         │  │                    │ │ │
│  └──────────────────────┘         │  │  ┌──────────────┐ │ │ │
│                                    │  │  │   Bastion    │ │ │ │
│                                    │  │  │   Service    │ │ │ │
│                                    │  │  └──────────────┘ │ │ │
│                                    │  └────────────────────┘ │ │
│                                    └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - Install from [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription** - Active Azure subscription
3. **Bash Shell** - Linux, macOS, or WSL on Windows

### Installation

```bash
# Clone the repository
git clone https://github.com/psheinfeld/Azure-training.git
cd Azure-training

# Make scripts executable
chmod +x *.sh
```

### Login to Azure

```bash
az login
```

### Deploy Infrastructure

```bash
./azure-vnet-vm-bastion-setup.sh
```

The deployment takes approximately **10-15 minutes** (most time is spent creating the Bastion service).

### Cleanup Resources

```bash
./azure-cleanup.sh
```

## ⚙️ Configuration Variables

All configuration is managed through variables at the top of `azure-vnet-vm-bastion-setup.sh`:

### Resource Group
```bash
RESOURCE_GROUP="rg-azure-training"
LOCATION="eastus"
```

### First VNet (VM VNet)
```bash
VNET1_NAME="vnet-vm"
VNET1_CIDR="10.0.0.0/16"
SUBNET1_NAME="subnet-vm"
SUBNET1_CIDR="10.0.1.0/24"
```

### Second VNet (Bastion VNet)
```bash
VNET2_NAME="vnet-bastion"
VNET2_CIDR="10.1.0.0/16"
SUBNET2_NAME="subnet-workload"
SUBNET2_CIDR="10.1.1.0/24"
BASTION_SUBNET_CIDR="10.1.2.0/26"  # Minimum /26 required
```

### Virtual Machine
```bash
VM_NAME="vm-training"
VM_SKU="Standard_B2s"              # Change to desired VM size
VM_IMAGE="Ubuntu2204"              # Ubuntu 22.04 LTS
VM_ADMIN_USERNAME="azureuser"
```

### Bastion
```bash
BASTION_NAME="bastion-training"
BASTION_PUBLIC_IP_NAME="pip-bastion"
```

## 📝 Customization

To customize the deployment, edit the variables section in `azure-vnet-vm-bastion-setup.sh`:

### Change VM Size
```bash
VM_SKU="Standard_B1s"    # Smaller, cheaper
VM_SKU="Standard_D2s_v3" # Larger, more powerful
```

### Change Location
```bash
LOCATION="westus2"       # West US 2
LOCATION="northeurope"   # North Europe
```

### Change CIDR Ranges
```bash
VNET1_CIDR="172.16.0.0/16"
SUBNET1_CIDR="172.16.1.0/24"
VNET2_CIDR="172.17.0.0/16"
SUBNET2_CIDR="172.17.1.0/24"
BASTION_SUBNET_CIDR="172.17.2.0/26"
```

### Change VM Image
```bash
VM_IMAGE="Ubuntu2204"         # Ubuntu 22.04 LTS
VM_IMAGE="Ubuntu2004"         # Ubuntu 20.04 LTS
VM_IMAGE="Win2022Datacenter"  # Windows Server 2022
VM_IMAGE="Win2019Datacenter"  # Windows Server 2019
```

## 🔐 Accessing the VM

After deployment, access the VM securely through Azure Bastion:

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your VM resource (`vm-training`)
3. Click **Connect** → **Bastion**
4. Enter credentials:
   - **Username**: `azureuser` (or your configured username)
   - **Authentication Type**: SSH Private Key
   - **Private Key**: Use the key from `~/.ssh/id_rsa`

Alternatively, use the Azure CLI:
```bash
az network bastion ssh \
    --name bastion-training \
    --resource-group rg-azure-training \
    --target-resource-id $(az vm show -g rg-azure-training -n vm-training --query id -o tsv) \
    --auth-type ssh-key \
    --username azureuser \
    --ssh-key ~/.ssh/id_rsa
```

## 📊 Resources Created

| Resource Type | Name | Purpose |
|--------------|------|---------|
| Resource Group | rg-azure-training | Container for all resources |
| Virtual Network | vnet-vm | VM network (10.0.0.0/16) |
| Subnet | subnet-vm | VM subnet (10.0.1.0/24) |
| Virtual Machine | vm-training | Ubuntu VM (Standard_B2s) |
| Network Security Group | nsg-vm | VM firewall rules |
| Virtual Network | vnet-bastion | Bastion network (10.1.0.0/16) |
| Subnet | subnet-workload | Workload subnet (10.1.1.0/24) |
| Subnet | AzureBastionSubnet | Bastion subnet (10.1.2.0/26) |
| VNet Peering | peering-vm-to-bastion | VM→Bastion peering |
| VNet Peering | peering-bastion-to-vm | Bastion→VM peering |
| Public IP | pip-bastion | Bastion public IP (Standard) |
| Azure Bastion | bastion-training | Secure VM access |

## 💰 Cost Considerations

Approximate monthly costs (East US region):

- **Standard_B2s VM**: ~$30/month
- **Azure Bastion (Basic)**: ~$140/month
- **Storage (128 GB SSD)**: ~$10/month
- **VNets & Peering**: ~$5/month

**Total**: ~$185/month

💡 **Tip**: Delete resources when not in use to save costs!

## 🧹 Cleanup

To delete all resources:

```bash
./azure-cleanup.sh
```

Or manually:
```bash
az group delete --name rg-azure-training --yes --no-wait
```

## 🔍 Verification

Check deployment status:

```bash
# List all resources
az resource list --resource-group rg-azure-training --output table

# Check VNet peering status
az network vnet peering list \
    --resource-group rg-azure-training \
    --vnet-name vnet-vm \
    --output table

# Check VM status
az vm show -d \
    --resource-group rg-azure-training \
    --name vm-training \
    --output table
```

## 🛠️ Troubleshooting

### Script fails with "not logged in"
```bash
az login
```

### Bastion creation takes too long
This is normal. Bastion deployment typically takes 5-10 minutes.

### Quota exceeded error
Check your subscription quotas:
```bash
az vm list-usage --location eastus --output table
```

### NSG rules not working
Verify NSG associations:
```bash
az network nsg show \
    --resource-group rg-azure-training \
    --name nsg-vm
```

## 📚 Additional Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Virtual Networks](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Bastion Documentation](https://docs.microsoft.com/en-us/azure/bastion/)
- [VNet Peering](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For issues or questions, please open an issue in this repository.