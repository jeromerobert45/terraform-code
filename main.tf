terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

    tags = {
      Name = "terraform-vpc"
    }
}

resource "aws_subnet" "pubsub" {
    vpc_id     = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "public-subnet"
    }
}

resource "aws_subnet" "privsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

    tags = {
        Name = "private-subnet"
    }
}

resource "aws_internet_gateway" "tigw" {
 vpc_id = aws_vpc.myvpc.id

    tags = {
        Name = "terraform-igw"
    }
}

resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.tigw.id
    }

    tags = {
        Name = "Public-RT"
    }
}

resource "aws_route_table_association" "privassociation" {
    subnet_id      = aws_subnet.privsub.id
    route_table_id = aws_route_table.privrt.id
}

resource "aws_eip" "teip" {
    vpc      = true
}

resource "aws_nat_gateway" "tnat" {
    allocation_id = aws_eip.teip.id
    subnet_id     = aws_subnet.pubsub.id

    tags = {
        Name = "NAT-GW"
    }
}

resource "aws_route_table" "privrt" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.tnat.id
    }

    tags = {
        Name = "Private-RT"
    }
}

resource "aws_route_table_association" "pubassociation" {
    subnet_id      = aws_subnet.pubsub.id
    route_table_id = aws_route_table.pubrt.id
    }

resource "aws_security_group" "allow_all" {
    name        = "allow_all"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.myvpc.id

    ingress {
        description      = "TLS from VPC"
        from_port        = 0
        to_port          = 65535
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_all"
    }
}

resource "aws_instance" "pubmachine" {
    ami = "ami-0f5ee92e2d63afc18"
    availability_zone = "ap-south-1a"
    instance_type = "t2.micro"
    key_name = "jeropractise"
    subnet_id = aws_subnet.pubsub.id
    vpc_security_group_ids = [aws_security_group.allow_all.id]
}

resource "aws_instance" "privmachine" {
    ami = "ami-0f5ee92e2d63afc18"
    availability_zone = "ap-south-1b"
    instance_type = "t2.micro"
    key_name = "jeropractise"
    subnet_id = aws_subnet.privsub.id
    vpc_security_group_ids = [aws_security_group.allow_all.id]
}










