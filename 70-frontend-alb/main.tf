module "frontend_alb" {
  source = "terraform-aws-modules/alb/aws"
  internal = false # it means its a public LB
  version = "9.16.0"
  name    = "${var.project}-${var.environment}-frontend-alb" #roboshop-dev-backend-alb
  vpc_id  = local.vpc_id
  subnets = local.public_subnet_ids
  create_security_group = false # we arleady creating on our own
  security_groups = [local.frontend_alb_sg_id]
  enable_deletion_protection = false

  tags = merge(
    local.common_tags,
    {
    Name = "${var.project}-${var.environment}-frontend-alb"
    }
  )
}
resource "aws_lb_listener" "frontend_alb" {
    load_balancer_arn = module.frontend_alb.arn
    port = "443"
    protocol = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = local.acm_certificate_arn

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/html"
        message_body = "<h1>hello i am from frontend alb using HTTPS</h1>"
        status_code = "200"
      }
    }

}

resource "aws_route53_record" "frontend_alb" {
  zone_id = var.zone_id
  name    = "*.${var.zone_name}" # .devsecopstrainee.site
  type    = "A"
  allow_overwrite = true

  alias {
    name                   = module.frontend_alb.dns_name
    zone_id                = module.frontend_alb.zone_id # Here as we are using open module we have to mention ALB zone_id. we have to check their properties they are exposing zoneid as zone_id
    evaluate_target_health = true
  }
  
}
  

  