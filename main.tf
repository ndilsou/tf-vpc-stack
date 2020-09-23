terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "aws-nsoungadoy2-bbg-tf-state"
    key            = "networking/vpc/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "tf-state-lock"
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
  tags = {
    Name  = "main-vpc"
    Group = "Networking"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
}


# DMZ

resource "aws_subnet" "public" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 2, each.value)
  availability_zone = each.key
  tags = {
    Name  = "Public-${each.value}"
    Group = "Networking"
  }
}

resource "aws_route_table_association" "rt_assoc" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Zone

resource "aws_subnet" "private" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.newbits, length(var.subnets) + each.value)
  availability_zone = each.key
  tags = {
    Name  = "Private-${each.value}"
    Group = "Networking"
  }
}

resource "aws_eip" "ngw_eip" {
  for_each = var.nats
  vpc      = true
  tags = {
    Name  = "ngw-eip-${each.value}"
    Group = "Networking"
  }
}

resource "aws_nat_gateway" "ngw" {
  for_each      = var.nats
  allocation_id = aws_eip.ngw_eip[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name  = "ngw-${each.value}"
    Group = "Networking"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "ngw_route" {
  for_each               = var.nats
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[each.key].id
}
