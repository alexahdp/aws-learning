
# define provider
provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

# ==================== IAM Roles and Policies ====================

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

resource "aws_iam_role_policy_attachment" "attach_ssminstancecore_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "attach" {
  name = "appexample-dev-EC2-codedeploy-instanceprofile-us-east-1"
  role = aws_iam_role.codedeploy_ec2_role.name
}

resource "aws_iam_policy" "codestar_connection_policy" {
  name        = "appexample-dev-codestar-connection-policy"
  description = "A policy with permissions for codestar connection"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_codestar_connection_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codestar_connection_policy.arn
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example_codebuild_project_role" {
  name               = "appexample-dev-codebuild-role-us-east-1"
  assume_role_policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_policy" "codebuild_write_cloudwatch_policy" {
  name        = "appexample-dev-codebuild-policy-us-east-1"
  description = "A policy for codebuild to write to cloudwatch"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "cloudwatch:*",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        # "Action": ["s3:Get*", "s3:List*"],
        "Action": ["s3:*"],
        # "Resource": [aws_s3_bucket.codepipeline_bucket.arn],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_codebuild_write_cloudwatch_policy" {
  role       = aws_iam_role.example_codebuild_project_role.name
  policy_arn = aws_iam_policy.codebuild_write_cloudwatch_policy.arn
}

resource "aws_iam_role" "codepipeline_role" {
  name = "appexample-dev-codepipeline-role"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codepipline_execution_policy" {
  name        = "appexample-dev-codepipeline-policy"
  description = "A policy with permissions for codepipeline"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow"
        "Action": ["codebuild:StartBuild", "codebuild:BatchGetBuilds"],
        "Resource": "*",
      },
      {
        "Action": ["cloudwatch:*"],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Action": ["s3:Get*", "s3:List*", "s3:PutObject"],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Action": ["codedeploy:CreateDeployment", "codedeploy:GetDeploymentConfig"],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_codepipline_execution_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipline_execution_policy.arn
}

# ==================== S3-Buckets ====================

resource "aws_s3_bucket" "build_artifacts_bucket" {
  bucket = "appexample-dev-build-artifacts-us-east-1"
}

resource "aws_s3_bucket_versioning" "build_artifacts_bucket_versioning" {
  bucket = aws_s3_bucket.build_artifacts_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "appexample-dev-codepipeline-bucket-us-east-1"
}

resource "aws_s3_bucket_versioning" "codepipeline_bucket_versioning" {
  bucket = aws_s3_bucket.codepipeline_bucket.id
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

resource "aws_launch_template" "auto_scaling_launch_template_test" {
  name_prefix   = "auto_scaling_launch_template_test"
  iam_instance_profile {
    name = aws_iam_instance_profile.attach.name
  }
  image_id      = "ami-0d4e980e3c1927a5f" # Enter here your AMI id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.application_sg.id]
}

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

resource "aws_codedeploy_app" "codedeploy_app" {
  name = "appexample-dev-codedeploy-us-east-1"
  compute_platform = "Server"
}

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

# ==================== CodeBuild ====================

resource "aws_codebuild_project" "example_codebuild_project" {
  name          = "appexample-dev-codebuild-us-east-1"
  description   = "Codebuild for appexample-dev"
  build_timeout = "30"
  service_role  = aws_iam_role.example_codebuild_project_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "example_codebuild_project-log-group"
      stream_name = "example_codebuild_project-log-stream"
    }
  }
  source {
    type = "CODEPIPELINE"
  }
}

# ==================== Codestar Connection ====================

resource "aws_codestarconnections_connection" "codestar_connection_example" {
  name          = "appexample-dev-codestar"
  provider_type = "GitHub"
}

# ==================== CodePipeline ====================

resource "aws_codepipeline" "pipeline" {
  name     = "appexample-dev-codepipeline-us-east-1"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.codestar_connection_example.arn
        FullRepositoryId = var.github_repository_url # IMPORTANT: put here url of your repository ("github.com/username/repo.git")
        BranchName       = "main"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.example_codebuild_project.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ApplicationName  = aws_codedeploy_app.codedeploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.deployment_group.deployment_group_name
      }
    }
  }
}
