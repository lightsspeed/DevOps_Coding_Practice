#Defining Terraform Provider

provider "aws" {
  region = var.region
}

#Creating VPC

resource "aws_vpc" "test_vpc" {

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment} - vpc"
    }
  )
}

#Creating an Internet Gateway

resource "aws_internet_gateway" "test_igw" {

  vpc_id = aws_vpc.test_vpc.id

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment} - igw"
    }
  )

}


#Creating Public Subnets

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment} - igw"
    }
  )
}


# Creating a route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.custom_tags,
    {
      Name = "${var.environment}-public-rt"
    }
  )
}

# Associating the route table with public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
