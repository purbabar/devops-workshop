provider "aws" {
    region = "us-east-1"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id = aws_vpc.dpp-vpc.id

  ingress {
    description      = "ssh from internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "demo-server" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t2.micro"
    key_name = "dpp"
    //security_groups = [ "allow_ssh" ]
    vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
    subnet_id = aws_subnet.dpp-public_subnet_01.id
    for_each = toset(["jenkins-master", "build-slave", "ansible"])

    tags = {
        Name = "${each.key}"
    }
}


resource "aws_vpc" "dpp-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "dpp-vpc"
  }
}

resource "aws_subnet" "dpp-public_subnet_01" {
  vpc_id     = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "dpp-public_subnet_01"
  }
}

resource "aws_subnet" "dpp-public_subnet_02" {
  vpc_id     = aws_vpc.dpp-vpc.id
  cidr_block = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "dpp-public_subnet_02"
  }
}

resource "aws_internet_gateway" "dpp-igw" {
  vpc_id = aws_vpc.dpp-vpc.id

  tags = {
    Name = "dpp_igw"
  }
}


resource "aws_route_table" "dpp_public_route" {
  vpc_id = aws_vpc.dpp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpp-igw.id
  }

  tags = {
    Name = "dpp_public_route"
  }
}

resource "aws_route_table_association" "adpp-asso" {
  subnet_id      = aws_subnet.dpp-public_subnet_01.id
  route_table_id = aws_route_table.dpp_public_route.id
}


resource "aws_route_table_association" "adpp-asso1" {
  subnet_id      = aws_subnet.dpp-public_subnet_02.id
  route_table_id = aws_route_table.dpp_public_route.id
}