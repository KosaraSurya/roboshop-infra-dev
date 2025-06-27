module "vpc" {
    source = "git::https://github.com/KosaraSurya/terraform-aws-vpc.git?ref=main"
    #source = "../terraform-aws-vpc"
    /* project = "roboshop"
    environment = "dev"
    public_subnet_cidr = ["10.0.1.0/24", "10.0.2.0/24"] */

    project = var.project
    environment = var.environment
    public_subnet_cidr = var.public_subnet_cidr
    private_subnet_cidr = var.private_subnet_cidr
    database_subnet_cidr = var.database_subnet_cidr

    is_peering_required = true
}

output "vpc_id" {
    value = module.vpc.vpc_id
}