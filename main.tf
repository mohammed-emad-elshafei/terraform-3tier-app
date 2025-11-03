provider "aws" {
  region = "us-east-1"
}

# ------------------------
# Create VPC
# ------------------------
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-vpc"
  }
}

# ------------------------
# Public Subnet
# ------------------------
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ------------------------
# Private Subnets (2 AZs)
# ------------------------
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-b"
  }
}

# ------------------------
# Internet Gateway
# ------------------------
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# ------------------------
# Route Table for Public Subnet
# ------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------
# Security Groups
# ------------------------
# Allow SSH + HTTP for EC2
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "allow_ssh_http"
  }
}

# SG for Database (only backend EC2 can access)
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow MySQL from backend only"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh_http.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_sg"
  }
}

# ------------------------
# DB Subnet Group
# ------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# ------------------------
# RDS MySQL Database
# ------------------------
resource "aws_db_instance" "database" {
  identifier              = "mydatabase"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "mydb"
  username                = "admin"
  password                = "Admin1234!"
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false

  tags = {
    Name = "mydatabase"
  }
}

# ------------------------
# Backend Server
# ------------------------
resource "aws_instance" "backend" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  #key_name      = "labsuser"

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y python3-pymysql mysql-client
              mysql -h ${aws_db_instance.database.address} -u admin -pAdmin1234! -e "CREATE TABLE IF NOT EXISTS mydb.users (id INT PRIMARY KEY, name VARCHAR(50), gmail VARCHAR(50));"
              mysql -h ${aws_db_instance.database.address} -u admin -pAdmin1234! -e "INSERT INTO mydb.users (id, name, gmail) VALUES (1,'mohamed','mohamed@iti.com'),(2,'emad','emad@iti.com'),(3,'elshafei','elshafei@iti.com');"
              EOF

  tags = {
    Name = "backend"
  }
}

# ------------------------
# Frontend Server
# ------------------------
resource "aws_instance" "frontend" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
#  key_name      = "my-keypair"

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2 mysql-client
              systemctl enable apache2
              systemctl start apache2
              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>Mohamed Emad Elshafei</title>
                <style>
                  body { font-family: Arial; background-color: #f9f9f9; text-align: center; margin-top: 50px; }
                  h1 { color: #007bff; }
                  p { font-size: 18px; color: #555; }
                  button { background-color: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; }
                  table { margin: 20px auto; border-collapse: collapse; width: 50%; }
                  th, td { border: 1px solid #ddd; padding: 8px; }
                  th { background-color: #007bff; color: white; }
                </style>
              </head>
              <body>
                <h1>Mohamed Emad Elshafei</h1>
                <p>System Administrator Trainee at ITI</p>
                <button onclick="loadData()">Show Users</button>
                <table id="dataTable" style="display:none;">
                  <tr><th>ID</th><th>Name</th><th>Gmail</th></tr>
                </table>
                <script>
                  async function loadData() {
                    const response = await fetch('http://${aws_instance.backend.private_ip}:5000/data');
                    const data = await response.json();
                    const table = document.getElementById('dataTable');
                    table.style.display = 'table';
                    data.forEach(row => {
                      const tr = document.createElement('tr');
                      tr.innerHTML = `<td>$${row.id}</td><td>$${row.name}</td><td>$${row.gmail}</td>`;
                      table.appendChild(tr);
                    });
                  }
                </script>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "frontend"
  }
}
