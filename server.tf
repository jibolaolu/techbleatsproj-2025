resource "aws_instance" "jenkins-web" {
  ami             = var.instance_ami
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public[0].id
  security_groups = [aws_security_group.ec2_sg.id]
  key_name = var.keypair
  tags            = merge(local.common_tags, { Name = "${local.name_prefix}-Jenkins-Pipeline" })
}
