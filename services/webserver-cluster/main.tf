locals {
  http_port = 80
  any_port = 0
  tcp_protocol = "tcp"
  any_protocol = "-1"
  all_ips = "0.0.0.0/0"
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key = var.db_remote_state_key
    region = "us-east-1"
  }
}

resource "aws_launch_configuration" "servidor-de-juanjo" {
  image_id      = "ami-00874d747dde814fa" # us-west-1
  instance_type = var.instance_type
  name_prefix   = "juanjo-"

  user_data = <<-EOF
    #!/bin/bash
    echo "Hala Celta" >> index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [aws_security_group.SGterraform.id]
}

resource "aws_autoscaling_group" "servidor-de-juanjo" {
  name                 = "web-de-juanjo"
  launch_configuration = aws_launch_configuration.servidor-de-juanjo.name
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.servidor-de-juanjo.arn]

  tag {
    key   = "Name"
    value = "Nicolas-Server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "SGterraform" {
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-lb-juanjo" {

}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  from_port   = local.any_port #0
  to_port     = local.any_port #0
  protocol    = local.any_protocol #"-1"
  cidr_blocks = [local.all_ips] #"0.0.0.0/0"
  security_group_id = aws_security_group.sg-lb-juanjo.id
}

resource "aws_security_group_rule" "allow_http_inboud" {
  type = "ingress"
  from_port   = local.http_port #80
  to_port     = local.http_port #80
  protocol    = local.tcp_protocol #"tcp"
  cidr_blocks = [local.all_ips]
  security_group_id = aws_security_group.sg-lb-juanjo.id
}

resource "aws_lb" "servidor-de-juanjo" {
  name               = "alb-juanjo"
  internal           = false
  load_balancer_type = "application"

  security_groups    = [aws_security_group.sg-lb-juanjo.id]
  subnets            = data.aws_subnets.default.ids
  }

resource "aws_lb_target_group" "servidor-de-juanjo" {
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "servidor-de-juanjo" {

  load_balancer_arn = aws_lb.servidor-de-juanjo.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.servidor-de-juanjo.arn
  }
}
