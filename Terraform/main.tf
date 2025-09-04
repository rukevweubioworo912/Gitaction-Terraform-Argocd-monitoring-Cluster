resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "master" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "master_subnet"
  }
}

resource "aws_subnet" "worker1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "worker1_subnet"
  }
}

resource "aws_subnet" "worker2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "worker2_subnet"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "master" {
  subnet_id      = aws_subnet.master.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_route_table_association" "worker1" {
  subnet_id      = aws_subnet.worker1.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_route_table_association" "worker2" {
  subnet_id      = aws_subnet.worker2.id
  route_table_id = aws_route_table.my_route.id
}

resource "aws_security_group" "k8s_cluster_sg" {
  name        = "k8s-cluster-sg"
  description = "Security group for Kubernetes cluster nodes"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-cluster-sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "mykeyname" {
  key_name   = "mykeyname"
  public_key = file("id_rsa.pub")
}

resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "ec2_cloudwatch_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "ec2_cloudwatch_profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}

resource "aws_instance" "k8s_master" {
  ami                 = data.aws_ami.amazon_linux.id
  instance_type       = "t3.medium"
  key_name            = aws_key_pair.mykeyname.key_name
  subnet_id           = aws_subnet.master.id
  security_groups     = [aws_security_group.k8s_cluster_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  user_data = file("${path.module}/cloudwatch.sh")
 
  
 

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "k8s_worker" {
  count               = 2
  ami                 = data.aws_ami.amazon_linux.id
  instance_type       = "t3.medium"
  key_name            = aws_key_pair.mykeyname.key_name
  subnet_id           = element([aws_subnet.worker1.id, aws_subnet.worker2.id], count.index)
  security_groups     = [aws_security_group.k8s_cluster_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_cloudwatch_profile.name
  user_data = file("${path.module}/monitoring-stack.sh")
  

  tags = {
    Name = "k8s-worker-${count.index + 1}"
  }
}