
# define provider
provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

# ==================== IAM Roles and Policies ====================

# define a role, which will be assumed by CodeDeploy service
resource "aws_iam_role" "codedeploy_role" {
  name = "appexample-dev-codedeploy-role-us-east-1"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "codedeploy.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# define a role, which will be assumed by a codedeploy app inside an EC2-instance during a deployment
resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "appexample-dev-EC2-codedeploy-role-us-east-1"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# define a policy, which allows access to S3 bucket with artifacts
resource "aws_iam_policy" "codedeploy_ec2_to_s3_policy" {
  name        = "appexample-dev-EC2-codedeploy-to-S3-policy-us-east-1"
  description = "Allow access to S3 bucket with artifacts"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:Get*", "s3:List*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_codedeploy_ec2_to_s3_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = aws_iam_policy.codedeploy_ec2_to_s3_policy.arn
}

# attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach_ssminstancecore_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# define an instance profile, which will be used by an EC2-instance
resource "aws_iam_instance_profile" "attach" {
  name = "appexample-dev-EC2-codedeploy-instanceprofile-us-east-1"
  role = aws_iam_role.codedeploy_ec2_role.name
}

# ==================== S3-Buckets ====================

# define a bucket for storing build artifacts
resource "aws_s3_bucket" "build_artifacts_bucket" {
  bucket = "appexample-dev-build-artifacts-us-east-1"
}

resource "aws_s3_bucket_versioning" "build_artifacts_bucket_versioning" {
  bucket = aws_s3_bucket.build_artifacts_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# ==================== Compute Resources ====================

resource "aws_security_group" "application_sg" {
  name        = "application-sg"
  description = "application-sg"
  ingress {
    description      = "-"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "-"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    self             = true
  }
  ingress {
    description      = "-"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }
}

# define a launch template, which will be used by an autoscaling group
resource "aws_launch_template" "auto_scaling_launch_template_test" {
  name_prefix   = "auto_scaling_launch_template_test"
  iam_instance_profile {
    name = aws_iam_instance_profile.attach.name
  }
  image_id      = "ami-0d4e980e3c1927a5f" # Enter here your AMI id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.application_sg.id]
}

# define an autoscaling group
resource "aws_autoscaling_group" "autoscaling_group" {
  name                      = "appexample-dev-autoscaling-group-us-east-1"
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  availability_zones = ["us-east-1a"]
  launch_template {
    id      = aws_launch_template.auto_scaling_launch_template_test.id
    version = "$Latest"
  }
}

# ==================== Codedeploy ====================

# define a CodeDeploy application
resource "aws_codedeploy_app" "codedeploy_app" {
  name = "appexample-dev-codedeploy-us-east-1"
  compute_platform = "Server"
}

# define a CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "appexample-dev-deployment-group-us-east-1"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  autoscaling_groups = [aws_autoscaling_group.autoscaling_group.name]
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
