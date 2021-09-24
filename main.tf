terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"


  backend "remote" {
    organization = "ACG-Terraform-Demos-Alex"

    workspaces {
      name = "gh-actions"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

resource "aws_instance" "app_server" {
  ami                    = "ami-0d1bf5b68307103c2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_alb.id]
  user_data              = <<-EOF
                #!/bin/bash
                # Use this for your user data (script from top to bottom)
                # install httpd (Linux 2 version)
                yum update -y
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF
  tags = {
    Name = "ExampleAppServerInstance"
  }
}
resource "aws_security_group" "alb" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic for ALB"


  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_security_group" "allow_alb" {
  name        = "allow_alb"
  description = "Allow alb inbound traffic to the instance"
  
  

  ingress {
      description      = "allow http from alb"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      security_groups      = [aws_security_group.alb.id]
    }
  

  tags = {
    Name = "ExampleAppServerInstance"
  }
}


resource "aws_lb" "test" {
  name               = "exampleAppLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = ["subnet-884279c0", "subnet-84285dde"]

  enable_deletion_protection = true


  tags = {
    Name = "ExampleAppServerInstance"
  }

}
resource "aws_lb_target_group" "test" {
  name     = "ExampleAppInstanceTg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-4d659a34"
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}
resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.app_server.id
  port             = 80
}