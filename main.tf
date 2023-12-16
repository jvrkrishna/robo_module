################## Policy###################
resource "aws_iam_policy" "policy" {
  name        = "${var.component}.${var.env}.ssm.policy"
  path        = "/"
  description = "Used to access the ssm parameters"
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

resource "aws_iam_role" "test_role" {
  name = "${var.component}.${var.env}.ec2.Role"
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




###sg

###instance

##Route

