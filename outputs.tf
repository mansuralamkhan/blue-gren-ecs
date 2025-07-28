output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "active_environment" {
  value = local.next_environment
}