/* resource "aws_key_pair" "openvpn" {
  key_name   = "openvpn"
  public_key = "file(C:\\devops\\openvpn.pub)"
} */

resource "aws_instance" "vpn" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.vpn_sg_id]
  subnet_id = local.public_subnet_id
  key_name = "dws84" # Make sure this is exists in AWS account
  #key_name = aws_key_pair.openvpn.key_name # If key no there in aws, Create resource in terraform and importr like this
  user_data = file("openvpn.sh") # for headless mode
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-VPN"
    }
  )
}

# R53 record for mongodb

resource "aws_route53_record" "vpn" {
  zone_id = var.zone_id
  name    = "vpn-${var.environment}.${var.zone_name}"
  type    = "A"
  ttl     = 1
  records = [aws_instance.vpn.public_ip]
  allow_overwrite = true
}

output "vpnEc2" {
  value = aws_instance.vpn.id
}