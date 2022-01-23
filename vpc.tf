locals {
  vpc_cidr = "10.0.0.0/16"

  # Subnets
  subnets = {
    public-a = {
      subnet_cidr       = cidrsubnet(local.vpc_cidr, 4, 0)
      availability_zone = "ap-northeast-1a"
    }
    public-c = {
      subnet_cidr       = cidrsubnet(local.vpc_cidr, 4, 1)
      availability_zone = "ap-northeast-1c"
    }
    private-a = {
      subnet_cidr       = cidrsubnet(local.vpc_cidr, 4, 2)
      availability_zone = "ap-northeast-1a"
    }
    private-c = {
      subnet_cidr       = cidrsubnet(local.vpc_cidr, 4, 3)
      availability_zone = "ap-northeast-1c"
    }
  }
}

## VPC
resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = "${var.system_name}-vpc"
  }
}

## Subnet
resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.subnet_cidr
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.system_name}-${each.key}"
    Role = strrev(substr(strrev(each.key), 2, -1))
  }
}

## Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.system_name}-igw"
  }
}

## Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.system_name}-public-rtb"
  }
}

# TODO NAT G/W作成時は変更
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.system_name}-private-rtb"
  }
}

resource "aws_route_table_association" "public" {
  for_each = { for k, v in aws_subnet.this : k => v if v.tags.Role == "public" }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = { for k, v in aws_subnet.this : k => v if v.tags.Role == "private" }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

## prefix_list
locals {
  prefix_lists = {
    kikuchi = {
      001 = {
        cidr = "122.26.4.17/32"
      }
    }
  }
}

resource "aws_ec2_managed_prefix_list" "this" {
  for_each = local.prefix_lists

  name           = each.key
  address_family = "IPv4"
  max_entries    = length(each.value)

  dynamic "entry" {
    for_each = { for k, v in each.value : k => v }

    content {
      cidr        = entry.value.cidr
      description = entry.key
    }
  }
}
