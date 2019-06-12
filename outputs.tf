output "hasura_alb_address" {
  value = "${aws_lb.hasura.dns_name}"
}

output "hasura_url" {
  value = "${aws_route53_record.dns_record.fqdn}"
}

output "hasura_alb_id" {
  value = "${aws_lb.hasura.id}"
}

output "hasura_access_key" {
  value = "${var.hasura_access_key}"
}
