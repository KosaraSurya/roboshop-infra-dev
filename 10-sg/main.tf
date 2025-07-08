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

module "backend_alb" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "backend_alb"
  sg_description = "Creating SG for application load balancer"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

module "vpn" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "VPN_SG"
  sg_description = "Creating SG for VPN"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

# VPN ports 22, 443, 1194, 943
resource "aws_security_group_rule" "vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

resource "aws_security_group_rule" "vpn_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}



# bastion accepting connections from my laptop
resource "aws_security_group_rule" "bastion_laptop" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

# backend_alb accepting connections bastion on port 80
resource "aws_security_group_rule" "backend_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.backend_alb.sg_id
}

# backend_alb accepting connections VPN
resource "aws_security_group_rule" "backend_alb_VPN" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.vpn.sg_id
}

output "frontend_sg_id" {
  value = module.frontend.sg_id
}

output "bastion_sg_id" {
  value = module.bastion.sg_id 
}

output "backendLB" {
  value = module.backend_alb.sg_id
}

output "VPN" {
  value = module.vpn.sg_id
}