provider "aws" {
  region = "us-west-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.23.0"
    }
  }
  required_version = "~> 1.0"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "private-us-west-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-west-1a"
  tags = {
    "Name" = "private-us-west-1a"
  }
}

resource "aws_subnet" "private-us-west-1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-west-1c"

  tags = {
    "Name" = "private-us-west-1c"
  }
}

resource "aws_subnet" "public-us-west-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-us-west-1a"
  }
}

resource "aws_subnet" "public-us-west-1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-west-1c"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-us-west-1c"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-west-1a.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-us-west-1a" {
  subnet_id      = aws_subnet.private-us-west-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-us-west-1c" {
  subnet_id      = aws_subnet.private-us-west-1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-us-west-1a" {
  subnet_id      = aws_subnet.public-us-west-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-us-west-1c" {
  subnet_id      = aws_subnet.public-us-west-1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "my-app-example-3" {
  name        = "my-app-example-3"
  description = "Allow API Access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow Health Checks"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "my-app-example-3" {
  name                   = "my-app-example-3"
  image_id               = "ami-0f55ab974bb338801"
  key_name               = "PrivateEC2s"
  vpc_security_group_ids = [aws_security_group.my-app-example-3.id]
}

resource "aws_lb_target_group" "my-app-example-3" {
  name     = "my-app-example-3"
  port     = 8080
  protocol = "HTTP"  # Change this to "HTTPS" if your server uses HTTPS
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    protocol            = "HTTP"  # Change this to "HTTPS" if your server uses HTTPS
    port                = "8080"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "my-app-example-3" {
  name               = "my-app-example-3"
  internal           = true
  load_balancer_type = "application"  # Change this to "network" for NLB

  subnets = [
    aws_subnet.public-us-west-1a.id,
    aws_subnet.public-us-west-1c.id
  ]

  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true

  enable_http2 = true

  tags = {
    Name = "my-app-example-3"
  }
}

resource "aws_lb_listener" "my-app-example-3" {
  load_balancer_arn = aws_lb.my-app-example-3.arn
  port              = 80  # Change this to 443 if your server uses HTTPS
  protocol          = "HTTP"  # Change this to "HTTPS" if your server uses HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-app-example-3.arn
  }
}

resource "aws_autoscaling_group" "my-app-example-3" {
  name     = "my-app-example-3"
  min_size = 1
  max_size = 3

  health_check_type   = "EC2"
  vpc_zone_identifier = [aws_subnet.private-us-west-1a.id, aws_subnet.private-us-west-1c.id]
  target_group_arns   = [aws_lb_target_group.my-app-example-3.arn]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.my-app-example-3.id
      }
      override {
        instance_type = "t3.micro"
      }
    }
  }
}

resource "aws_autoscaling_policy" "my-app-example-3" {
  name                   = "my-app-example-3"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.my-app-example-3.name

  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 25.0
  }
}

