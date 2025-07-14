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
    path = "/health" #to check health of the application we can give /health after its IP:PORT
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

# Creating Launch Template
resource "aws_launch_template" "catalogue" {
  name = "${var.project}-${var.environment}-catalogue"
  image_id = aws_ami_from_instance.catalogue.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]
  update_default_version = true # Each time you give terraform apply, new version will beacome default

  # Instance tags
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,{
      Name = "${var.project}-${var.environment}-catalogue"
    }
    )
  }

  # Volume tags
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,{
      Name = "${var.project}-${var.environment}-catalogue"
    }
    )
  }

  # Tags for launch template
  tags = merge(
      local.common_tags,{
      Name = "${var.project}-${var.environment}-catalogue"
    }
    )

}

# Auto scaling

resource "aws_autoscaling_group" "catalogue" {
  name = "${var.project}-${var.environment}-catalogue"
  desired_capacity   = 1
  max_size           = 10
  min_size           = 1
  health_check_grace_period = 90
  health_check_type         = "ELB"
  target_group_arns = [aws_lb_target_group.catalogue.arn]
  vpc_zone_identifier = local.private_subnet_ids

  launch_template {
    id      = aws_launch_template.catalogue.id
    version = aws_launch_template.catalogue.latest_version
  }

  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    } 
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }
  timeouts {
    delete = "15m"
  }
}

# Auto scaling policy
resource "aws_autoscaling_policy" "catalogue" {
  name                   = "${var.project}-${var.environment}-catalogue"
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  policy_type            = "TargetTrackingScaling"
  # cooldown = 120 # cooldown is only supported for policy type SimpleScaling
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}


# Listene rule

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = local.backend_alb_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      values = ["catalogue.backend-${var.environment}.${var.zone_name}"]
    }
  }
}

