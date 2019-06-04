terraform {
  backend "s3" {
    key    = "sample.terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  version = "~> 1.52"
  region  = "ap-northeast-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "ecr" {
  name = "sample"
}

data "terraform_remote_state" "infra" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config {
    key    = "terraform.tfstate"
    bucket = "terraform-backend-${data.aws_caller_identity.current.account_id}"
    region = "${data.aws_region.current.name}"
  }
}

module "svc_sg" {
  source = "modules/security_group"

  vpc_id = "${data.terraform_remote_state.infra.vpc_id}"

  name        = "${local.name}-service"
  description = "service rule"

  ingress_with_cidr_block_rules = [
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow all IP at 80 port"
    },
    {
      cidr_blocks = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow all IP at 443 port"
    },
  ]
}

data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars {
    region                      = "ap-northeast-1"
    name                        = "${local.name}"
    loadbalancer_container_port = "80"
    repository_url              = "${data.aws_ecr_repository.ecr.repository_url}"
    database_address            = "${local.workspace["database_address"]}"
    database_user               = "${local.workspace["database_user"]}"
    database_password           = "${local.workspace["database_password"]}"
    dd_image_tag                = "latest"
    dd_api_key                  = "${local.workspace["dd_api_key"]}"
    env                         = "${terraform.workspace}"
  }
}

module "ecs_service" {
  source = "modules/ecs_service"

  name = "${local.name}"

  vpc_id  = "${data.terraform_remote_state.infra.vpc_id}"
  subnets = "${data.terraform_remote_state.infra.private_subnets}"

  ecs_cluster_name        = "${data.terraform_remote_state.infra.ecs_cluster_name}"
  main_container_name     = "sample"
  task_log_names          = ["ecs", "datadog"]
  service_security_groups = ["${module.svc_sg.sg_id}"]
  container_definitions   = "${data.template_file.container_definitions.rendered}"
  alb_listener_arn        = "${data.terraform_remote_state.infra.http_listener_arn}"
  alb_health_check_path   = "/ping"
}
