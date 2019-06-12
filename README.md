# AWS ECS module for quickly deploying hasura

hasura docker image running on AWS ECS with ALB and target groups.

requires version 0.11

## usage without https

```terraform

# PROVIDER

provider "aws" {
  //    access_key = "${var.aws_access_key}"
  //    secret_key = "${var.aws_secret_key}"
  profile = "${var.aws_profile}"
  region = "${var.aws_region}"
}

data "aws_ecs_cluster" "mycluster" {
  cluster_name = "${var.aws_ecs_cluster_name}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.project_name}"
  retention_in_days = 30

  tags {
    Name    = "${var.project_name}_log_group"
    project = "${var.project_name}"
  }
}

module "ecs_hasura" {
  source  = "bendog/ecs_hasura/aws"
  version = "0.3.1"
  
  project_name = "${var.project_name}"
  
  aws_region = "${var.aws_region}"
  aws_vpc_id = "${var.aws_vpc_id}"
  aws_ecs_cluster_id = "${data.aws_ecs_cluster.mycluster.arn}"
  aws_subnets = ["${var.aws_public_subnets}"]
  aws_securitygroups = ["${var.aws_rds_security_group_id}"]
  cloudwatch_log_group_name = "${aws_cloudwatch_log_group.log_group.name}"

  hasura_access_key = "myverysecrethasuraaccesskey"
  hasura_db_address = "my.database.address"
  hasura_db_user = "root"
  hasura_db_pass = "myverysecretpassword"
  hasura_db_name = "mydb"
}
```

## usage with https

```terraform

# see above...

module "ecs_hasura" {
  source  = "bendog/ecs_hasura/aws"
  version = "0.5.0"
  
  project_name = "${var.project_name}"

  domain = "mydomain.com"
  subdomain = "hasura.mydomain.com"
  certificate_domain = "*.mydomain.com"


  
  aws_region = "${var.aws_region}"
  aws_vpc_id = "${var.aws_vpc_id}"
  aws_ecs_cluster_id = "${data.aws_ecs_cluster.mycluster.arn}"
  aws_subnets = ["${var.aws_public_subnets}"]
  aws_securitygroups = ["${var.aws_rds_security_group_id}"]
  cloudwatch_log_group_name = "${aws_cloudwatch_log_group.log_group.name}"

  hasura_access_key = "myverysecrethasuraaccesskey"
  hasura_db_address = "my.database.address"
  hasura_db_user = "root"
  hasura_db_pass = "myverysecretpassword"
  hasura_db_name = "mydb"
}
```
