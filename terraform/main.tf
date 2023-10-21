data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"] # changed VPC
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name" # changes tag name
    values = ["main-subnet-public1-us-east-1a"] #changed public subnet
  }
}

variable "environment" {
  type = list(object({
    name  = string
    value = bool
  }))

  // You can also set a default value if you want
  default = [
    {
      name  = "NEW_FEATURE"
      value = true #changed
    },
  ]
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "sctp-my-app-endless-cluster" #Change

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    sctp-my-app-endless = { #task def and service name -> #Change
      cpu    = 512
      memory = 1024

      # Container definition(s)
      container_definitions = {

        sctp-my-app-endless = { #container name - also refer to ecs-task-definition.json
          essential = true
          image     = "255945442255.dkr.ecr.us-east-1.amazonaws.com/sctp-my-app-endless:latest" #changed
          port_mappings = [
            {
              name          = "sctp-my-app-endless" #container name
              containerPort = 5000
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem = false
          environment              = var.environment
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = flatten(data.aws_subnets.public.ids)
      security_group_ids                 = [aws_security_group.allow_sg.id]
    }
  }
}

resource "aws_security_group" "allow_sg" {
  name        = "allow_tls-endless" #changed security name
  description = "Allow traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_sg"
  }
}
