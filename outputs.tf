output "hasura_alb_address" {
  value = "${aws_alb.hasura.dns_name}"
}

output "hasura_alb_id" {
  value = "${aws_alb.hasura.id}"
}

output "hasura_access_key" {
    value = "${var.hasura_access_key}"
}
