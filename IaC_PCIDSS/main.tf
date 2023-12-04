terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-west-1"
}

resource "aws_instance" "EC2Instance" {
    ami = "ami-0e34ec67298a7ea81"
    instance_type = "t2.micro"
    key_name = "PrivateEC2s"
    availability_zone = "us-west-1a"
    tenancy = "default"
    subnet_id = "subnet-02fda89edc61db420"
    ebs_optimized = false
    vpc_security_group_ids = [
        "${aws_security_group.EC2SecurityGroup4.id}",
        "${aws_security_group.EC2SecurityGroup.id}"
    ]
    source_dest_check = true
    root_block_device {
        volume_size = 8
        volume_type = "gp3"
        delete_on_termination = true
    }
    tags = {
        Name = "PrivateWebServer"
    }
}

resource "aws_instance" "EC2Instance2" {
    ami = "ami-004e735215a3d52e7"
    instance_type = "t2.micro"
    key_name = "PrivateEC2s"
    availability_zone = "us-west-1c"
    tenancy = "default"
    subnet_id = "subnet-076bc50028ea559c4"
    ebs_optimized = false
    vpc_security_group_ids = [
        "${aws_security_group.EC2SecurityGroup.id}"
    ]
    source_dest_check = true
    root_block_device {
        volume_size = 8
        volume_type = "gp3"
        delete_on_termination = true
    }
    tags = {
        Name = "PrivateWebServer3"
    }
}

resource "aws_instance" "BastionHost" {
    ami = "ami-06e4ca05d431835e9"
    instance_type = "t2.micro"
    key_name = "BastonHost"
    availability_zone = "us-west-1a"
    tenancy = "default"
    subnet_id = "subnet-055662ff3faac783c"
    ebs_optimized = false
    vpc_security_group_ids = [
        "${aws_security_group.EC2SecurityGroup3.id}"
    ]
    source_dest_check = true
    root_block_device {
        volume_size = 8
        volume_type = "gp3"
        delete_on_termination = true
    }
    tags = {
        Name = "BastionHost"
    }
}

resource "aws_vpc" "EC2VPC" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = false
    instance_tenancy = "default"
    tags = {
        Name = "vpc-main"
    }
}

resource "aws_subnet" "EC2Subnet" {
    availability_zone = "us-west-1a"
    cidr_block = "10.0.1.0/24"
    vpc_id = "${aws_vpc.EC2VPC.id}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "EC2Subnet2" {
    availability_zone = "us-west-1c"
    cidr_block = "10.0.4.0/24"
    vpc_id = "${aws_vpc.EC2VPC.id}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "EC2Subnet3" {
    availability_zone = "us-west-1a"
    cidr_block = "10.0.3.0/24"
    vpc_id = "${aws_vpc.EC2VPC.id}"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "EC2Subnet4" {
    availability_zone = "us-west-1c"
    cidr_block = "10.0.2.0/24"
    vpc_id = "${aws_vpc.EC2VPC.id}"
    map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "EC2InternetGateway" {
    tags = {
        Name = "igw-Main"
    }
    vpc_id = "${aws_vpc.EC2VPC.id}"
}

resource "aws_eip" "EC2EIP" {
    vpc = true
}

resource "aws_route_table" "EC2RouteTable" {
    vpc_id = "${aws_vpc.EC2VPC.id}"
    tags = {
        Name = "nat-routes"
    }
}

resource "aws_route_table" "EC2RouteTable2" {
    vpc_id = "${aws_vpc.EC2VPC.id}"
    tags = {
        Name = "PubRT"
    }
}

resource "aws_route" "EC2Route" {
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = "nat-09d7720587137a862"
    route_table_id = "rtb-0ce1a2a4855273559"
}

resource "aws_route" "EC2Route2" {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "igw-0bf767dfd8b7297f1"
    route_table_id = "rtb-06858dcf8b0092b84"
}

resource "aws_nat_gateway" "EC2NatGateway" {
    subnet_id = "subnet-055662ff3faac783c"
    tags = {
        Name = "nat-Main"
    }
    allocation_id = "eipalloc-0af7d23850ca0a870"
}

resource "aws_route_table_association" "EC2SubnetRouteTableAssociation" {
    route_table_id = "rtb-0ce1a2a4855273559"
    subnet_id = "subnet-02fda89edc61db420"
}

resource "aws_route_table_association" "EC2SubnetRouteTableAssociation2" {
    route_table_id = "rtb-0ce1a2a4855273559"
    subnet_id = "subnet-076bc50028ea559c4"
}

resource "aws_route_table_association" "EC2SubnetRouteTableAssociation3" {
    route_table_id = "rtb-06858dcf8b0092b84"
    subnet_id = "subnet-055662ff3faac783c"
}

resource "aws_route_table_association" "EC2SubnetRouteTableAssociation4" {
    route_table_id = "rtb-06858dcf8b0092b84"
    subnet_id = "subnet-01945da7092210aae"
}

resource "aws_lb" "ElasticLoadBalancingV2LoadBalancer" {
    name = "ALB-main"
    internal = false
    load_balancer_type = "application"
    subnets = [
        "subnet-01945da7092210aae",
        "subnet-055662ff3faac783c"
    ]
    security_groups = [
        "${aws_security_group.EC2SecurityGroup2.id}"
    ]
    ip_address_type = "ipv4"
    access_logs {
        enabled = false
        bucket = ""
        prefix = ""
    }
    idle_timeout = "60"
    enable_deletion_protection = "false"
    enable_http2 = "true"
    enable_cross_zone_load_balancing = "true"
}

resource "aws_lb_listener" "ElasticLoadBalancingV2Listener" {
    load_balancer_arn = "arn:aws:elasticloadbalancing:us-west-1:110649600046:loadbalancer/app/ALB-main/6c5e2e74e54a84c3"
    port = 8080
    protocol = "HTTP"
    default_action {
        target_group_arn = "arn:aws:elasticloadbalancing:us-west-1:110649600046:targetgroup/TG/496dad506f73cfc2"
        type = "forward"
    }
}

resource "aws_lb_listener" "ElasticLoadBalancingV2Listener2" {
    load_balancer_arn = "arn:aws:elasticloadbalancing:us-west-1:110649600046:loadbalancer/app/ALB-main/6c5e2e74e54a84c3"
    port = 80
    protocol = "HTTP"
    default_action {
        target_group_arn = "arn:aws:elasticloadbalancing:us-west-1:110649600046:targetgroup/TG/496dad506f73cfc2"
        type = "forward"
    }
}

resource "aws_security_group" "EC2SecurityGroup" {
    description = "launch-wizard-1 created 2023-11-16T15:45:17.805Z"
    name = "PrivateSG"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    ingress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup2.id}"
        ]
        description = "Allow traffix from LB"
        from_port = 80
        protocol = "tcp"
        to_port = 80
    }
    ingress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup2.id}"
        ]
        description = "Port 8080 for app"
        from_port = 8080
        protocol = "tcp"
        to_port = 8080
    }
    ingress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup3.id}"
        ]
        description = "Port 8080 for bastion to test"
        from_port = 8080
        protocol = "tcp"
        to_port = 8080
    }
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "SSH anywhere"
        from_port = 22
        protocol = "tcp"
        to_port = 22
    }
    ingress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup3.id}"
        ]
        description = "Allow bastion host"
        from_port = 22
        protocol = "tcp"
        to_port = 22
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
    egress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup6.id}"
        ]
        description = "Allow outbound traffic to rds"
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
}

resource "aws_security_group" "EC2SecurityGroup2" {
    description = "alb"
    name = "ALB-SG"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 80
        protocol = "tcp"
        to_port = 80
    }
    ingress {
        ipv6_cidr_blocks = [
            "::/0"
        ]
        from_port = 80
        protocol = "tcp"
        to_port = 80
    }
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 8080
        protocol = "tcp"
        to_port = 8080
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
}

resource "aws_security_group" "EC2SecurityGroup3" {
    description = "Allow SSH"
    name = "BastionHost"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 22
        protocol = "tcp"
        to_port = 22
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
}

resource "aws_security_group" "EC2SecurityGroup4" {
    description = "Security group attached to instances to securely connect to main-db. Modification could lead to connection loss."
    name = "ec2-rds-1"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    egress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup7.id}"
        ]
        description = "Rule to allow connections to main-db from any instances this security group is attached to"
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
}

resource "aws_security_group" "EC2SecurityGroup5" {
    description = "Allw ssh from anywhere"
    name = "BastionSG"
    tags = {}
    vpc_id = "vpc-06c47958f6a91e2f7"
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "HTTP from all"
        from_port = 80
        protocol = "tcp"
        to_port = 80
    }
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "Open 8080"
        from_port = 8080
        protocol = "tcp"
        to_port = 8080
    }
    ingress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        description = "Allow SHH"
        from_port = 22
        protocol = "tcp"
        to_port = 22
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
}

resource "aws_security_group" "EC2SecurityGroup6" {
    description = "Created by RDS management console"
    name = "RDS-sg"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    ingress {
        cidr_blocks = [
            "41.250.211.242/32"
        ]
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
    ingress {
        security_groups = [
            "${aws_security_group.EC2SecurityGroup3.id}"
        ]
        description = "Allow bastion host to db instance"
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
    ingress {
        security_groups = [
            "sg-0cdfbd5faee4acb4b"
        ]
        description = "Allow inbound from private EC2"
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        from_port = 0
        protocol = "-1"
        to_port = 0
    }
}

resource "aws_security_group" "EC2SecurityGroup7" {
    description = "Security group attached to main-db to allow EC2 instances with specific security groups attached to connect to the database. Modification could lead to connection loss."
    name = "rds-ec2-1"
    tags = {}
    vpc_id = "${aws_vpc.EC2VPC.id}"
    ingress {
        security_groups = [
            "sg-076c58a8fec3b3d81"
        ]
        description = "Rule to allow connections from EC2 instances with sg-076c58a8fec3b3d81 attached"
        from_port = 3306
        protocol = "tcp"
        to_port = 3306
    }
}

resource "aws_lb_target_group" "ElasticLoadBalancingV2TargetGroup" {
    health_check {
        interval = 30
        path = "/"
        port = "traffic-port"
        protocol = "HTTP"
        timeout = 5
        unhealthy_threshold = 2
        healthy_threshold = 5
        matcher = "200"
    }
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = "${aws_vpc.EC2VPC.id}"
    name = "TG"
}

resource "aws_key_pair" "EC2KeyPair" {
    public_key = "REPLACEME"
    key_name = "PrivateEC2s"
}

resource "aws_key_pair" "EC2KeyPair2" {
    public_key = "REPLACEME"
    key_name = "BastonHost"
}

resource "aws_s3_bucket" "S3Bucket" {
    bucket = "aws-cloudtrail-logs-110649600046-ed9ac0d4"
}

resource "aws_db_instance" "RDSDBInstance" {
    identifier = "main-db"
    allocated_storage = 20
    instance_class = "db.t2.micro"
    engine = "mysql"
    username = "admin"
    password = "REPLACEME"
    backup_window = "08:00-08:30"
    backup_retention_period = 0
    availability_zone = "us-west-1a"
    maintenance_window = "sun:09:49-sun:10:19"
    multi_az = false
    engine_version = "8.0.33"
    auto_minor_version_upgrade = true
    license_model = "general-public-license"
    publicly_accessible = false
    storage_type = "gp2"
    port = 3306
    storage_encrypted = false
    copy_tags_to_snapshot = true
    monitoring_interval = 0
    iam_database_authentication_enabled = false
    deletion_protection = false
    db_subnet_group_name = "default-vpc-0e3128dba1ac8212d"
    vpc_security_group_ids = [
        "${aws_security_group.EC2SecurityGroup7.id}",
        "${aws_security_group.EC2SecurityGroup6.id}"
    ]
    max_allocated_storage = 1000
}

resource "aws_db_subnet_group" "RDSDBSubnetGroup" {
    description = "Created from the RDS Management Console"
    name = "default-vpc-0e3128dba1ac8212d"
    subnet_ids = [
        "subnet-055662ff3faac783c",
        "subnet-076bc50028ea559c4",
        "subnet-02fda89edc61db420",
        "subnet-01945da7092210aae"
    ]
}

resource "aws_cloudtrail" "CloudTrailTrail" {
    name = "management-events"
    s3_bucket_name = "${aws_s3_bucket.S3Bucket.id}"
    include_global_service_events = true
    is_multi_region_trail = true
    enable_log_file_validation = false
    enable_logging = true
}

