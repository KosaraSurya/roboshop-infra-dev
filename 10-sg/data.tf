data "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project}/${var.environment}/vpc_id"
}

# name is taken form parameters.tf in 00-vpc
