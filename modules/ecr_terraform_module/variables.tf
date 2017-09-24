variable "registries" {
  type = "list"
}

variable "stack_details" {
  type = "map"
}

output "repository_urls" {
  value = "${aws_ecr_repository.ecr.*.repository_url}"
}
