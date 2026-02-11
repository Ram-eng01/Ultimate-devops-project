
# Resource-1: VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = merge(var.tags, 
        {
            Name = "${var.environment_name}-vpc"
        }
    )
    lifecycle {
    prevent_destroy = false
  }
}

# Resource-2: Internet Gateway

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = merge(var.tags,
        {
            Name = "${var.environment_name}-igw"
        }
    )
}

# Resource-3: Public Subnets
resource "aws_subnet" "public" {
        for_each = { for index, az in local.local.azs : az => local.local.public_subnets[index]}
            #sample map ==>result for above for each
             #  {
            #    us-east-1a = 10.0.0.0/24
            #    us-east-1b = 10.0.1.0/24
            #    us-east-1c = 10.0.2.0/24
            #   }
        vpc_id = aws_vpc.main.id
        cidr_block = each.value
        availability_zone = each.key
        map_public_ip_on_launch = true
        tags = merge(var.tags, {
    Name = "${var.environment_name}-public-${each.key}"
  })

}


# Resource-4: Private Subnets
resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : az => local.private_subnets[idx] }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = merge(var.tags, {
    Name = "${var.environment_name}-private-${each.key}"
  })
}

# Resource-5: Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  tags = merge(var.tags, { Name = "${var.environment_name}-nat-eip" })
}

# Resource-6: NAT Gateway

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = values(aws_subnet.public)[0].id
    tags = merge(var.tags, { Name = "${var.environment_name}-nat" })
    depends_on = [aws_internet_gateway.igw]
}

# Resource-7: Public Route Table

