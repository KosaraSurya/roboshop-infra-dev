locals {
    ami_id = data.aws_ami.openvpn.id
    vpn_sg_id = data.aws_ssm_parameter.vpn_sg_id.value
    public_subnet_id = split(",",data.aws_ssm_parameter.public_subnet_ids.value)[0]

    common_tags = {
        project = var.project
        environment = var.environment
        terraform = "true"
    }
}