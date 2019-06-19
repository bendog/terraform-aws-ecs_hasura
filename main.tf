data "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.ecs_task_execution_role_name}"
}

data "aws_acm_certificate" "domaincert" {
  domain      = "${var.certificate_domain}"
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "domain" {
  name = "${var.domain}."
}

# security group
# LB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "hasura_lb" {
  name        = "${var.project_name}-hasura-ecs-alb"
  description = "${var.project_name} controls access to the ALB"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    project = "${var.project_name}"
  }
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "hasura_tasks" {
  name        = "${var.project_name}-hasura-ecs-tasks"
  description = "${var.project_name} allow inbound access from the ALB only"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    protocol        = "tcp"
    from_port       = "${var.hasura_port}"                   # hasuras port
    to_port         = "${var.hasura_port}"
    security_groups = ["${aws_security_group.hasura_lb.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    project = "${var.project_name}"
  }
}

# ALB

resource "aws_lb" "hasura" {
  name            = "${var.project_name}-hasura-lb"
  subnets         = ["${var.aws_subnets}"]
  security_groups = ["${aws_security_group.hasura_lb.id}"]

  tags = {
    project = "${var.project_name}"
  }
}

resource "aws_lb_target_group" "hasura" {
  name        = "${var.project_name}-hasura-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.aws_vpc_id}"
  target_type = "ip"

  health_check {
    enabled             = "${var.health_check_enabled}"
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_healthy_threshold}"
    matcher             = "${var.health_check_matcher}"
  }

  tags = {
    project = "${var.project_name}"
  }
}

resource "aws_lb_listener" "hasura" {
  load_balancer_arn = "${aws_lb.hasura.id}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.domaincert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.hasura.id}"
  }
}

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = "${aws_lb.hasura.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# setup DNS

resource "aws_route53_record" "dns_record" {
  name    = "${var.subdomain}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.domain.id}"

  alias {
    name                   = "${aws_lb.hasura.dns_name}"
    zone_id                = "${aws_lb.hasura.zone_id}"
    evaluate_target_health = "${var.subdomain_evaluate_health}"
  }
}

# ECS

resource "aws_ecs_task_definition" "hasura" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "${var.hasura_cpu}"
  memory                   = "${var.hasura_memory}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"

  container_definitions = <<DEFINITION
[
  {
    "image": "${var.hasura_image}",
    "cpu": ${var.hasura_cpu},
    "memory": ${var.hasura_memory},
    "name": "${var.project_name}-hasura",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": ${var.hasura_port},
        "hostPort": ${var.hasura_port}
      }
    ],
    "environment": [
        {
            "name": "HASURA_GRAPHQL_ENABLE_CONSOLE",
            "value": "true"
        },
        {
            "name": "HASURA_GRAPHQL_ACCESS_KEY",
            "value": "${var.hasura_access_key}"
        },
        {
            "name": "HASURA_GRAPHQL_DATABASE_URL",
            "value": "postgresql://${var.hasura_db_user}:${var.hasura_db_pass}@${var.hasura_db_address}/${var.hasura_db_name}"
        },
        {
            "name": "HASURA_GRAPHQL_JWT_SECRET",
            "value": "{\"type\":\"RS256\",\"jwk_url\": \"${var.hasura_graphql_jwt_secret_jwk_url}\",\"claims_format\": \"stringified_json\"}"
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-region": "${var.aws_region}",
            "awslogs-group": "${var.cloudwatch_log_group_name}",
            "awslogs-stream-prefix": "${aws_route53_record.dns_record.fqdn}"
        }
    }
  }
]
DEFINITION

  tags = {
    project = "${var.project_name}"
  }
}

resource "aws_ecs_service" "hasura" {
  depends_on = [
    "aws_lb_listener.hasura",
    "aws_ecs_task_definition.hasura",
  ]

  name            = "${var.project_name}-hasura-service"
  cluster         = "${var.aws_ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.hasura.arn}"
  desired_count   = "${var.hasura_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["${aws_security_group.hasura_tasks.id}", "${var.aws_securitygroups}"]
    subnets          = ["${var.aws_subnets}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.hasura.id}"
    container_name   = "${var.project_name}-hasura"
    container_port   = "${var.hasura_port}"
  }

  tags = {
    project = "${var.project_name}"
  }
}
