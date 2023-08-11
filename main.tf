#vpc creation

resource "aws_vpc" "myvpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "myvpc for test project"
  }
}

#create public_subnet
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet)
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.public_subnet[count.index]    
 map_public_ip_on_launch = true


  tags = {
    Name = "public-subnet"
  }
}

#create private_subnet
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet)
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = var.private_subnet[count.index]       

  tags = {
    Name = "private-subnet"
  }
}


#create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "vpc-IGW"
  }
}

#create nat gateway
resource "aws_nat_gateway" "nat-gtw" {
  allocation_id = aws_eip.eip-nat.id
  subnet_id     = aws_subnet.public_subnet[0].id
}

#create elastic ip
resource "aws_eip" "eip-nat" {
  tags = {
    Name = "myeip"
  }
}

#create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.myvpc.id
   
  route = []
  tags = {
    Name = "private-rt"
  }
}


#subnet association public and private
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
   count = length(var.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "nat_route" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat-gtw.id
  depends_on    = [aws_route_table.private]
}
