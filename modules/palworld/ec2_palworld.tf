resource "aws_iam_instance_profile" "this" {
  name = "palworld_profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name               = "palworld_role"
  description        = "The role for the Palworld server"
  assume_role_policy = data.aws_iam_policy_document.allow_ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "allow_ec2_assume_role" {
  statement {
    sid     = "AllowEc2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "this" {
  name        = "allow_server traffic"
  description = "Allow TLS and game server inbound traffic and all outbound"
  vpc_id      = "vpc-8244e2f9"
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_palworld_query_inbound_tcp" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 27015
  ip_protocol       = "tcp"
  to_port           = 27016
}

resource "aws_vpc_security_group_ingress_rule" "allow_palworld_query_inbound_udp" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 27015
  ip_protocol       = "udp"
  to_port           = 27016
}

resource "aws_vpc_security_group_ingress_rule" "allow_palworld_game_inbound" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8211
  ip_protocol       = "udp"
  to_port           = 8211
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_launch_template" "this" {
  name          = "palworld"
  instance_type = "r5a.xlarge"
  image_id      = "ami-026ad73ed895934d6"
  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size = 50
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  disable_api_stop        = true
  disable_api_termination = true
  ebs_optimized           = true
  security_group_names    = [aws_security_group.this.name]
  #user_data = filebase64("${path.module}/user_data.sh")
}

resource "aws_instance" "palworld_server" {
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tags = {
    Name = "palworld"
  }
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.palworld_server.id
}
