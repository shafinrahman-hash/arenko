resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

}

resource "aws_ecs_cluster" "nginx_cluster" {
  name = "${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu           = "256"
  memory        = "512"
  task_role_arn = aws_iam_role.ecs_task_role.arn

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "nginx-container"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
    }]
  }])
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_ecs_service" "nginx_service" {
  name            = "${var.environment}-${var.service}"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.web_1.id, aws_subnet.web_2.id]
    security_groups = [aws_security_group.ecs_sgrp.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx-container"
    container_port   = 80
  }

  depends_on = [aws_ecs_task_definition.nginx_task]
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

}

resource "aws_subnet" "web_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

}

resource "aws_subnet" "web_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

}

resource "aws_subnet" "database_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

}

resource "aws_subnet" "database_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "rt_aza" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_az_a.id
  }


}

resource "aws_route_table_association" "web_aza" {
  subnet_id      = aws_subnet.web_1.id
  route_table_id = aws_route_table.rt_aza.id
}

resource "aws_route_table_association" "web_azb" {
  subnet_id      = aws_subnet.web_2.id
  route_table_id = aws_route_table.rt_aza.id
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-${var.service}-alb-sg"
  description = "ALB SG: allow HTTP from internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ecs_sgrp" {
  name        = "sgrp-web-server"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "outbound traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

}

resource "aws_nat_gateway" "nat_az_a" {
  subnet_id     = aws_subnet.public_1.id
  allocation_id = aws_eip.nat_a.id


  depends_on = [
    aws_subnet.public_1
  ]
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

}

resource "aws_security_group" "database_sgrp" {
  name        = "sgrp-database"
  description = "Allow inbound traffic from application security group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Postgres from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sgrp.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_db_instance" "rds" {
  allocated_storage    = 10
  db_subnet_group_name = aws_db_subnet_group.subnet_group.id
  engine               = "postgres"
  engine_version       = "postgres13"
  instance_class       = "db.t2.micro"
  multi_az             = true

  db_name  = "mydb"
  username = "username"

  # If manage_master_user_password = true, RDS stores the master credentials in AWS Secrets Manager.
  # Your ECS task/application can read them at runtime via Secrets Manager (using the ECS task role).  
  manage_master_user_password = true

  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database_sgrp.id]
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.database_1.id, aws_subnet.database_2.id]

}