provider "aws" {
  region = "us-east-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com" # outra opção "https://ifconfig.me"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # ou ["099720109477"] ID master com permissão para busca

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"] # exemplo de como listar um nome de AMI - 'aws ec2 describe-images --region us-east-1 --image-ids ami-09e67e426f25ce0d7' https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
  }
}

resource "aws_instance" "maquina_nginx_java_mysql" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  key_name      = "treinamento-turma1_itau"
  associate_public_ip_address = true

  # subnet_id      = "subnet-12282387382372378"

  # root_block_device {
  #   encrypted = true
  #   volume_size = 8
  # }

  tags = {
    Name = "maquina_ansible_com_nginx_java_mysql"
  }
  vpc_security_group_ids = [aws_security_group.acessos.id]
}

resource "aws_security_group" "acessos" {
  name        = "acessos nginx java mysql"
  description = "acessos nginx java mysql inbound traffic"
  # vpc_id      = "vpc-12282387382372378"

  ingress = [
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null,
      security_groups: null,
      self: null
    },
    {
      description      = "Acesso HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = null,
      security_groups: null,
      self: null
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"],
      prefix_list_ids = null,
      security_groups: null,
      self: null,
      description: "Libera dados da rede interna"
    }
  ]

  tags = {
    Name = "acessos nginx java mysql"
  }
}

# terraform refresh para mostrar o ssh
output "aws_instance_e_ssh" {
  value = [
    "PUBLIC_DNS=${aws_instance.maquina_nginx_java_mysql.public_dns}",
    "PUBLIC_IP=${aws_instance.maquina_nginx_java_mysql.public_ip}",
    "ssh -i ~/Desktop/devops/treinamentoItau ubuntu@${aws_instance.maquina_nginx_java_mysql.public_dns} -o ServerAliveInterval=60"
  ]
}

# para liberar a internet interna da maquina, colocar regra do outbound "Outbound rules" como "All traffic"
# ssh -i ../../id_rsa_itau_treinamento ubuntu@ec2-3-93-240-108.compute-1.amazonaws.com
# conferir 
