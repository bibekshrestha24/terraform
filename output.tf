output "instances_ips" {
   value = aws_instance.mywebserver.*.public_ip
}

output "lb_address" {
  value = aws_lb.myalb.dns_name
}