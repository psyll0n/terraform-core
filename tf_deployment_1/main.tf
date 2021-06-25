##################################################################################
# DATA - Used to pull information from the provider and use it later as reference.
##################################################################################

# Get available availability zones 
data "aws_availability_zones" "available" {}


# Get available AMI images
data "aws_ami" "aws-livpcnux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn-ami-hvm*"]
    }

    filter { 
        name = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


########################################
# RESOURCES
########################################


### NETWORKING ###


# VPC
resource "aws_vpc" "vpc" {
    cidr_block            = var.network_address_space
    enable_dns_hostnames  = "true"
}

# Subnet1
resource "aws_subnet" "subnet1" {
    cidr_block              = var.subnet1_address_space
    vpc_id                  = aws_vpc.vpc.id
    map_public_ip_on_launch = "true"
    availability_zone       = data.aws_availability_zones.available.names[0]
}

# Subnet2
resource "aws_subnet" "subnet2" {
    cidr_block              = var.subnet2_address_space
    vpc_id                  = aws_vpc.vpc.id
    map_public_ip_on_launch = "true"
    availability_zone       = data.aws_availability_zones.available.names[1]
}

# IGW
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

# Routing 
resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.vpc.id

    route { 
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta-subnet1" {
    subnet_id      = aws_subnet.subnet1.id
    route_table_id = aws_route_table.rtb.id
}

resource "aws_route_table_association" "rta-subnet2" {
    subnet_id      = aws_subnet.subnet2.id
    route_table_id = aws_route_table.rtb.id
}


### SECURITY GROUPS ###


# Security Group - NGINX
resource "aws_security_group" "sg" {
    name = "nginx-sg"
    description = "NGINX - Allowed ports"
    vpc_id = aws_vpc.vpc.id

    # SSH access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # HTTP access from the internal VPC address space
    ingress {
        from_port   = 80 
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [var.network_address_space]
    }

    # Outbound Internet access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# ELB - SG
resource "aws_security_group" "elb-sg" {
    name    = "nginx_elb_sg"
    vpc_id  = aws_vpc.vpc.id

    # Allow HTTP from anywhere
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } 

    # Allow all outbound
     egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Elastic Load Balancer
resource "aws_elb" "web" {
    name = "nginx-elb"

    subnets          = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups  = [aws_security_group.elb-sg.id]
    instances        = [aws_instance.nginx1.id, aws_instance.nginx2.id]

    listener {
        instance_port     = 80
        instance_protocol =  "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
}


# EC2 Instances
resource "aws_instance" "nginx1" {
    ami                     = data.aws_ami.aws-linux.id
    instance_type           = "t2.micro"
    subnet_id               = aws_subnet.subnet1.id
    private_ip              = "10.0.100.100"
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.sg.id]
}

resource "aws_instance" "nginx2" {
    ami                     = data.aws_ami.aws-linux.id
    instance_type           = "t2.micro"
    subnet_id               = aws_subnet.subnet2.id
    private_ip              = "10.0.200.200"
    key_name                = var.key_name
    vpc_security_group_ids  = [aws_security_group.sg.id]
}




