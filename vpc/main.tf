# ✅ VPC 생성
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# ✅ 퍼블릭 서브넷 2개 생성
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name                               = "public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/pri-cluster" = "owned"     # EKS 클러스터에서 쓸 경우
    "kubernetes.io/role/elb"             = "1"        # 퍼블릭 ALB용
  }

  depends_on = [aws_internet_gateway.igw]
}

# ✅ 프라이빗 서브넷 2개 생성
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# ✅ 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# ✅ 탄력 IP (EIP) for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "main-vpc-eip"
  }
}

# ✅ NAT 게이트웨이 (퍼블릭 서브넷 0번에 설치)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "main-nat"
  }
}

# ✅ 퍼블릭 라우팅 테이블 + 라우트 추가
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# ✅ 퍼블릭 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ✅ 프라이빗 라우팅 테이블 + NAT 경로 추가
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# ✅ 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
