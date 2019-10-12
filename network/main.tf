# VPC
resource "aws_vpc" "accela_vpc" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "accela"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "accela_igw" {
  vpc_id = "${aws_vpc.accela_vpc.id}"
  tags {
    Name = "accela-gw"
  }
}

# Subnets : public
resource "aws_subnet" "public" {
  count = "${length(var.public_subnets_cidr)}"
  vpc_id = "${aws_vpc.accela_vpc.id}"
  cidr_block = "${element(var.public_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"
  tags {
    Name = "accelapublic--subnet-${count.index+1}"
  }
}

# Subnets : private
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets_cidr)}"
  vpc_id = "${aws_vpc.accela_vpc.id}"
  cidr_block = "${element(var.private_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"
  tags {
    Name = "accelaprivate--subnet-${count.index+1}"
  }
}


# Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.accela_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.accela_igw.id}"
  }
  tags {
    Name = "publicRouteTable"
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "a" {
  count = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

# IP to NAT Gateway
resource "aws_eip" "nat_eip" {
  count    = "${length(var.azs)}"
  vpc      = true
  depends_on = ["aws_internet_gateway.accela_igw"]
}

# NAT Gateway
resource "aws_nat_gateway" "accela_nat" {
  count = "${length(var.public_subnets_cidr)}"
  allocation_id = "${element(aws_eip.nat_eip.*.id,count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id,count.index)}"
  depends_on = ["aws_internet_gateway.accela_igw"]
}

# Route table for private
resource "aws_route_table" "private_rt" {
  count = "${length(var.public_subnets_cidr)}"
  vpc_id = "${aws_vpc.accela_vpc.id}"
  tags {
      Name = "private rt"
  }
}

# Route for private
resource "aws_route" "private_route" {
  count = "${length(var.public_subnets_cidr)}"
  route_table_id  = "${element(aws_route_table.private_rt.*.id,count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.accela_nat.*.id,count.index)}"
}


resource "aws_route_table_association" "b" {
  count = "${length(var.public_subnets_cidr)}"
  subnet_id = "${element(aws_subnet.private.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.private_rt.*.id,count.index)}"
}

#Security group for public subnet
resource "aws_security_group" "sg-public" {
  name = "vpc_accela_pb_sb"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.accela_vpc.id}"

  tags {
    Name = "accela_vpc_pb_sg"
  }
}

# Define the security group for private subnet for example to allow traffic to pass from private to internet 
resource "aws_security_group" "sg-private"{
  name = "vpc_accela_pv_sb"
  description = "Allow traffic to pass from private to internet"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["${var.private_subnets_cidr}"]
  }
  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["${var.private_subnets_cidr}"]
    }
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.accela_vpc.id}"

    tags {
        Name = "accela_vpc_pb_sg"
    }
}
