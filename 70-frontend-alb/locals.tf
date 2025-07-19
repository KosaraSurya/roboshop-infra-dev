locals {
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    frontend_alb_sg_id = data.aws_ssm_parameter.frontend_alb_sg_id.value
    public_subnet_ids = split(",",data.aws_ssm_parameter.public_subnet_ids.value)
    acm_certificate_arn = data.aws_ssm_parameter.acm_certificate_arn.value

    common_tags = {
        project = var.project
        environment = var.environment
        terraform = "true"
    }
}