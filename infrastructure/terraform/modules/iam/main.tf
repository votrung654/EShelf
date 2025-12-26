# IAM Module for eShelf - SSM Support

# IAM Role for EC2 instances to use SSM
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project}-ec2-ssm-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-ec2-ssm-role-${var.environment}"
  })
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.project}-ec2-ssm-profile-${var.environment}"
  role = aws_iam_role.ec2_ssm_role.name

  tags = merge(var.tags, {
    Name = "${var.project}-ec2-ssm-profile-${var.environment}"
  })
}



