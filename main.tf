############### I am Policy ####################
resource "aws_iam_policy" "policy" {
  name        = "${var.component}.${var.env}.ssm.policy"
  path        = "/"
  description = "My test policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:GetParameter*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

################ I am role ##################
resource "aws_iam_role" "role" {
  name = "${var.component}.${var.env}.ec2role"

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
################ I am instance profile#####################
resource "aws_iam_instance_profile" "profile" {
  name = "${var.component}.${var.env}"
  role = aws_iam_role.role.name
}
################ Policy attachment##############
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

###### create ec2 instance terraform with vpc######
resource "aws_instance" "web" {
  ami                    = data.aws_ami.example.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.profile.name

  tags = {
    Name = "${var.component}.${var.env}"
  }
}

################ creating provisioner with null resource ################
resource "null_resource" "ansible" {
  depends_on = [aws_instance.web, aws_route53_record.www]   #### depends on this will create after this tasks
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.web.public_ip
    }
    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/jvrkrishna/robo-ansible roboshop.yml -e env=dev -e role_name=${var.component}"
    ]
  }
}
################# creating dns records #################
resource "aws_route53_record" "www" {
  zone_id = "Z0858447245XTBTK7DY06"
  name    = "${var.component}.${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.web.private_ip]
}

######### Security group terraform ##########
resource "aws_security_group" "sg" {
  name        = "${var.component}.${var.env}"
  description = "Allow TLS inbound traffic"

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
    Name = "${var.component}.${var.env}"
  }
}




