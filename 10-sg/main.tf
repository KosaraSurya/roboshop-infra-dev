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

#bastion_sg and rules
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

# bastion accepting connections from my laptop
resource "aws_security_group_rule" "bastion_laptop" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

#backend_alb_sg and rules
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
  security_group_id = module.backend_alb.sg_id
}

#vpn_sg and rules
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
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

# mongodb_sg and rules
module "mongodb" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "mondgodb"
  sg_description = "Creating SG for mongodb"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

# mongodb accepting connections catalogue
resource "aws_security_group_rule" "mongodb_catalogue" {
  count = length(var.mondgodb_ports_vpn)
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  source_security_group_id = module.catalogue.sg_id
  security_group_id = module.mongodb.sg_id
}


# mongodb accepting connections VPN
resource "aws_security_group_rule" "mongodb_vpn" {
  count = length(var.mondgodb_ports_vpn)
  type              = "ingress"
  from_port         = var.mondgodb_ports_vpn[count.index]
  to_port           = var.mondgodb_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.mongodb.sg_id
}

#redis_sg and rules
module "redis" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "redis"
  sg_description = "Creating SG for redis"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

# redis accepting connections VPN
resource "aws_security_group_rule" "redis_vpn" {
  count = length(var.redis_ports_vpn)
  type              = "ingress"
  from_port         = var.redis_ports_vpn[count.index]
  to_port           = var.redis_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.redis.sg_id
}

#mysql_sg and rules
module "mysql" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "mysql"
  sg_description = "Creating SG for mysql"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

# mysql accepting connections VPN
resource "aws_security_group_rule" "mysql_vpn" {
  count = length(var.mysql_ports_vpn)
  type              = "ingress"
  from_port         = var.mysql_ports_vpn[count.index]
  to_port           = var.mysql_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.mysql.sg_id
}

#rabbitmq_sg and rules
module "rabbitmq" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "rabbitmq"
  sg_description = "Creating SG for rabbitmq"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

# rabbitmq accepting connections from VPN
resource "aws_security_group_rule" "rabbitmq_vpn" {
  count = length(var.rabbitmq_ports_vpn)
  type              = "ingress"
  from_port         = var.rabbitmq_ports_vpn[count.index]
  to_port           = var.rabbitmq_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.rabbitmq.sg_id
}



# Catalogue
module "catalogue" {
  #source = "../../terraform-aws-securitygroup"
  source = "git::https://github.com/KosaraSurya/terraform-aws-securitygroup.git?ref=main"
  project = var.project
  environment = var.environment

  sg_name = "catalogue"
  sg_description = "Creating SG for catalogue"
  #vpc_id = data.aws_ssm_parameter.vpc_id.value
  vpc_id = local.vpc_id

}

resource "aws_security_group_rule" "catalogue_bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.catalogue.sg_id
}

resource "aws_security_group_rule" "catalogue_vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.catalogue.sg_id
}

resource "aws_security_group_rule" "catalogue_vpn_http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.catalogue.sg_id
}

resource "aws_security_group_rule" "catalogue_backend_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.backend_alb.sg_id
  security_group_id = module.catalogue.sg_id
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

output "mongodb" {
  value = module.mongodb.sg_id
}