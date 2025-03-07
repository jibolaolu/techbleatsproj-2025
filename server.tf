resource "aws_instance" "jenkins-web" {
  ami             = var.instance_ami
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public[0].id
  security_groups = [aws_security_group.ec2_sg.id]
  key_name        = var.keypair
  tags            = merge(local.common_tags, { Name = "${local.name_prefix}-Jenkins-Pipeline" })
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-Jenkins-Server-SG" })
}