terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "spark_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "spark_subnet_1" {
  vpc_id            = aws_vpc.spark_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "spark_subnet_2" {
  vpc_id            = aws_vpc.spark_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_security_group" "spark_sg" {
  name_prefix = "spark_sg_"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "spark_elb" {
  name = "spark-elb"
  #  subnets = [aws_subnet.spark_subnet_1.id, aws_subnet.spark_subnet_2.id]
  availability_zones = ["ap-south-1a", "ap-south-1b"]
  listener {
    instance_port     = 8080
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }
}

resource "aws_launch_configuration" "spark_lc" {
  image_id = "ami-0f8ca728008ff5af4"
  # image_id = "ami-0b4b6149de57aa853"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.spark_sg.id]
}

resource "aws_autoscaling_group" "spark_asg" {
  name                      = "spark_asg"
  launch_configuration      = aws_launch_configuration.spark_lc.id
  min_size                  = 1
  max_size                  = 2
  availability_zones = ["ap-south-1a"]
  # vpc_zone_identifier       = [aws_subnet.spark_subnet_1.id, aws_subnet.spark_subnet_2.id]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  tag {
    key                 = "Name"
    value               = "spark_node"
    propagate_at_launch = true
  }
}
  
