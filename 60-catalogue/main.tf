# Creating Target Group
resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project}-${var.environment}-catalogue" #roboshop-dev-catalogue
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    healthy_threshold = 2
    interval = 5
    matcher = "200-299"
    path = "/healt" #to check health of the application we can give /health after its IP:PORT
    port = 8080
    timeout = 2
    unhealthy_threshold = 3
    
  }
}

# Creating catalogue instance
resource "aws_instance" "catalogue" {
  ami           = local.ami_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]
  subnet_id = local.private_subnet_id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.catalogue.private_ip
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment}"
    ]
  }
}

# After configuration we are stopping the instance
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = aws_instance.catalogue.id
  state = "stopped"
  depends_on = [ terraform_data.catalogue ]
}

# After instance went to stop state then we will take AMI from it
resource "aws_ami_from_instance" "catalogue" {
  name               = "${var.project}-${var.environment}-catalogue"
  source_instance_id = aws_instance.catalogue.id
  depends_on = [ aws_ec2_instance_state.catalogue ]
  tags = merge(
    local.common_tags,{
      Name ="${var.project}-${var.environment}-catalogue"
    }
  )
}

# Delete the instance after taking the AMI

resource "terraform_data" "catalogue_delete" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  
  # Make sure we have aws config in our local
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.catalogue.id}"
  }
  depends_on = [ aws_ami_from_instance.catalogue ]
}