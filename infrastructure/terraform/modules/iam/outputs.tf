# IAM Module Outputs

output "ec2_ssm_instance_profile_name" {
  description = "IAM instance profile name for EC2 SSM"
  value       = aws_iam_instance_profile.ec2_ssm_profile.name
}

output "ec2_ssm_instance_profile_arn" {
  description = "IAM instance profile ARN for EC2 SSM"
  value       = aws_iam_instance_profile.ec2_ssm_profile.arn
}



