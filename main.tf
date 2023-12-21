########### Create I am policy in terraform ############
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}-ssm-pm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-pm-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParametersByPath",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DescribeParameters"
            ],
            "Resource": "arn:aws:ssm:us-east-1:207072006229:parameter/roboshop.${var.env}.${var.component}.*"
        }
    ]
}
EOF
}

############# Create I am role in terraform ######################
resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}-ec2-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}
############### Create I am instance profile ###################
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-instance-profile"
  role = aws_iam_role.role.name
}
############### Create Policy attachment in terraform ##############
resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

########### Create ec2 instance in terraform #############
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = {
    Name = "${var.component}-${var.env}"
  }
}

############# Create vps security group in terraform ##############
resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

############ create DNS Records for instances in teraform ###########
resource "aws_route53_record" "www" {
  zone_id = "Z0858447245XTBTK7DY06"
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instance.private_ip]
}

############## Provisioner for remote in terraform ################
resource "null_resource" "ansible" {
  depends_on = [aws_instance.instance, aws_route53_record.www]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.instance.public_ip
    }
    inline = [
      "sudo labauto ansible",
      "set-hostname -skip-apply ${var.component}",
      "ansible-pull -i localhost, -U https://github.com/jvrkrishna/robo-ansible roboshop.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}