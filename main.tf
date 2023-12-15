## I am policy
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

## I am Role
resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}-Ec2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}