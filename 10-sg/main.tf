module "frontend" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = var.frontend_sg_name
  sg_description = var.frontend_sg_description
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

module "bastion" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = var.bastion_sg_name
  sg_description = var.bastion_sg_description
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}


output "frontend_sg_id" {
  value = module.frontend.sg_id
}

output "bastino_sg_id" {
  value = module.bastion.sg_id 
}