# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started

Before you start do the following:

1. Clone this repository
2. Login to Azure
3. Update Terraform configuration

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Create a ressource group via the Azure Portal or via CLI
3. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
4. Install [Packer](https://www.packer.io/downloads)
5. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions

#### Prerequisites
Before we start deploying our components we have to login to Azure via the CLI

az login

#### Policy
First step is to deploy the policy, that any deployed component has to have minimum one tag.

1. az policy definition create -n tagging-policy --rules azurepolicy.tagging-policy.json
2. az policy assignment create -n tagging-policy --policy tagging-policy -g udacity

#### Packer
To built a Packer image we need the following informations.

* client_id
* client_secret
* subscription_id

The informations are collected from the environment after a successful login to azure via the CLI. The only variable you have to enter is the ressource group, where the Packer image will be stored.

* managed_image_resource_group_name

Now build the image

`packer build server.json`

#### Terraform

First, please update the vars.tf file. Minimum required values:

* resource_group_name (already created Ressource group for all ressources)
* env (the deployment environment, e.g. dev, test, prod)

Plan and apply the infrastructure.

`terraform plan`
`terraform apply`

### Output

    Internet ---- Load Balancer ---- +------------------------------------+
                                     :--- Virtual Network              ---:
                                     :---- Subnet                     ----:
                                     :----- Network Security Group    ----:
                                     : Availability Set --- Webserver VMs :
                                     +------------------------------------+
                                 