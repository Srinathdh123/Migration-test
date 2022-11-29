data "aws_availability_zones" "available_zones" {
  state = "available"
}

# Create VPC 

resource "aws_vpc" "sg-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-sg"
  }
}

# Create Public subnet
resource "aws_subnet" "public" {
  count                   = var.num_count
  vpc_id                  = aws_vpc.sg-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.sg-vpc.cidr_block, 8, 3 + count.index)
  availability_zone       = data.aws_availability_zones.available_zones.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Create Private subnet 
resource "aws_subnet" "private" {
  count             = var.num_count
  vpc_id            = aws_vpc.sg-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.sg-vpc.cidr_block, 8, 6 + count.index)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]
  tags = {
    Name = "private-subnet"
  }

}

# Create security group for EC2 and ALB

resource "aws_security_group" "lb" {
  name   = "ec2-alb-security-group"
  vpc_id = aws_vpc.sg-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name    = "ec2_alb_sg"
    Project = "sg-assignment"
  }
}

# Create security group for webserver

resource "aws_security_group" "webserver_sg" {
  name   = "webserver_sg"
  vpc_id = aws_vpc.sg-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["10.0.0.0/16"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "webserver_sg"
    Project = "sg-assignment"
  }
}


# Create gateway

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.sg-vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.sg-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_eip" "gateway" {
  count      = var.num_count
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  count         = var.num_count
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.gateway.*.id, count.index)
}

resource "aws_route_table" "private" {
  count  = var.num_count
  vpc_id = aws_vpc.sg-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.gateway.*.id, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count          = var.num_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

#Create Launch config

resource "aws_launch_template" "webserver-launch-config" {
  name_prefix            = "webserver-launch-config"
  image_id               = var.ami
  instance_type          = "t2.micro"
  
  vpc_security_group_ids = ["${aws_security_group.webserver_sg.id}"]

  

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 10
      volume_type           = "gp2"
      encrypted             = true
      delete_on_termination = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  user_data = filebase64("${path.module}/init.sh")

}

resource "aws_lb" "ALB-tf" {
  name               = "sg-ALG-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public.*.id
  security_groups    = [aws_security_group.lb.id]

  tags = {
    name    = "sg-AppLoadBalancer-tf"
    Project = "sg-assignment"
  }
}




# Create Auto Scaling Group

resource "aws_autoscaling_group" "sg-ASG-tf" {
  name                = "sg-ASG-tf"
  desired_capacity    = 3
  max_size            = 6
  min_size            = 3
  force_delete        = true
  depends_on          = [aws_lb.ALB-tf]
  target_group_arns   = ["${aws_lb_target_group.TG-tf.arn}"]
  health_check_type   = "EC2"
  vpc_zone_identifier = aws_subnet.private.*.id

  launch_template {
    id      = aws_launch_template.webserver-launch-config.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "sg-ASG-tf"
    propagate_at_launch = true
  }
}

# Create Target group

resource "aws_lb_target_group" "TG-tf" {
  name       = "sg-TargetGroup-tf"
  depends_on = [aws_vpc.sg-vpc]
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.sg-vpc.id
  health_check {
    interval            = 70
    path                = "/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
  tags = {
    name    = "sg-TargetGroup-tf"
    Project = "sg-assignment"
  }

}


# Create ALB Listener 

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ALB-tf.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-tf.arn
  }
  tags = {
    name    = "sg-lister-front_end"
    Project = "sg-assignment"
  }
}


