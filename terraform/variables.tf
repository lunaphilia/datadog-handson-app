locals {
  workspaces {
    default = "${local.default}"
  }

  workspace = "${local.workspaces[terraform.workspace]}"

  loadbalancer_container_name = "sample"
  loadbalancer_container_port = "8080"

  name = "sample-${terraform.workspace}"

  tags {
    Terraform   = "true"
    Environment = "${terraform.workspace}"
  }
}

locals {
  default {
    database_address  = "/sample-default/db/database_endpoint"
    database_user     = "/sample-default/db/master_username"
    database_password = "/sample-default/db/master_password"
  }
}
