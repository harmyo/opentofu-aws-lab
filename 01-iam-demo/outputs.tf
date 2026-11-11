output "demo_user_arn" {
  description = "ARN des von OpenTofu angelegten IAM-Users"
  value       = aws_iam_user.demo_user.arn
}

output "demo_user_unique_id" {
  description = "Von AWS vergebene, unveränderliche ID des Users"
  value       = aws_iam_user.demo_user.unique_id
}
