# AWS SETTINGS

variable "project_name" {
  type        = "string"
  description = "the name of the project used to prefix"
}

variable "aws_region" {
  type        = "string"
  description = "the aws region to use for logging"
}

variable "domain" {
  type        = "string"
  description = "domain name to build the subdomain on"
}

variable "subdomain" {
  type        = "string"
  description = "subdomain name for the load balancer"
}

variable "subdomain_evaluate_health" {
  default = false
}

variable "certificate_domain" {
  type        = "string"
  description = "domain name for the certificate"
}

variable "aws_vpc_id" {
  type        = "string"
  description = "the AWS VPC id to run hasura in"
}

variable "aws_ecs_cluster_id" {
  type        = "string"
  description = "the id for the AWS ECS cluster to use"
}

variable "aws_subnets" {
  type        = "list"
  description = "the AWS subnets to run hasura in"
}

variable "aws_securitygroups" {
  type        = "list"
  description = "additional AWS security groups to run hasura with"
  default     = []
}

variable "cloudwatch_log_group_name" {
  type        = "string"
  description = "the AWS cloudwatch log group name to use for logs"
}

variable "ecs_task_execution_role_name" {
  type        = "string"
  description = "the name of the role used to execute the ecs task - must have access to CloudWatch logs"
  default     = "ecsTaskExecutionRole"
}

# health check settings

variable "health_check_enabled" {
  default = true
}

variable "health_check_interval" {
  default = 30
}

variable "health_check_path" {
  default = "/v1/version"
}

variable "health_check_timeout" {
  default = 15
}

variable "health_check_healthy_threshold" {
  default = 3
}

variable "health_check_matcher" {
  default = "200,202"
}

# HASURA SETTINGS

variable "hasura_access_key" {
  type        = "string"
  description = "the password to access the hasura graphql engine"
}

variable "hasura_db_user" {
  type        = "string"
  description = "the user name to authenticate with the hasura db"
}

variable "hasura_db_pass" {
  type        = "string"
  description = "the password name to authenticate with the hasura db"
}

variable "hasura_db_address" {
  type        = "string"
  description = "the address for the postgres server"
}

variable "hasura_db_name" {
  type        = "string"
  description = "the name of the postgres database"
}

variable "hasura_cpu" {
  type        = "string"
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "hasura_memory" {
  type        = "string"
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "hasura_image" {
  type        = "string"
  description = "docker image for hasura"
  default     = "hasura/graphql-engine:latest"
}

variable "hasura_port" {
  type    = "string"
  default = 8080
}

variable "hasura_count" {
  type        = "string"
  description = "Number of docker containers to run"
  default     = 1
}
