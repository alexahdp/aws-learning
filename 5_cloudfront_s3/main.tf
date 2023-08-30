provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

data "aws_caller_identity" "current" {}
locals {
  account_id    = data.aws_caller_identity.current.account_id
}
output "account_id" {
  description = "Selected AWS Account ID"
  value       = local.account_id
}

resource "aws_iam_role" "codepipeline_role" {
  name = "appexample-dev-codepipeline-forntend-role"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Sid": "01",
        "Effect": "Allow",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codestar_connection_policy" {
  name        = "appexample-dev-codestar-frontend-connection-policy"
  description = "A policy with permissions for codestar connection"
  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "codestar-connections:UseConnection",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ],
        Resource: "*",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_codestar_connection_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codestar_connection_policy.arn
}

resource "aws_iam_policy" "codepipline_execution_policy" {
  name        = "appexample-dev-codepipeline-frontend-policy"
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

resource "aws_iam_role" "codebuild_project_role" {
  name               = "appexample-dev-codebuild-frontend-role-us-east-1"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        # "Sid": "01",
        "Effect": "Allow",
        "Principal": {
          "Service": "codebuild.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_policy" "codebuild_policy" {
  name        = "appexample-dev-codebuild-frontend-policy-us-east-1"
  description = "Allow access to S3 buckets for codebuild"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = ["cloudwatch:*"],
        Resource = "*",
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = ["s3:Get*", "s3:List*", "s3:Put*"]
        Resource = [
          aws_s3_bucket.codepipeline_frontend_bucket.arn,
          "${aws_s3_bucket.codepipeline_frontend_bucket.arn}/*",
        ]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_codebuild_policy" {
  role       = aws_iam_role.codebuild_project_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "appexample-dev-codedeploy-cloudfront-role-us-east-1"
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "AWS": [aws_iam_role.codepipeline_role.arn]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_policy" "codedeploy_policy" {
  name        = "appexample-dev-codedeploy-frontend-S3-policy-us-east-1"
  description = "Allow access to S3 buckets for codedeploy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:Get*", "s3:List*"]
        Resource = [
          aws_s3_bucket.codepipeline_frontend_bucket.arn,
          "${aws_s3_bucket.codepipeline_frontend_bucket.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:Get*", "s3:List*", "s3:Put*"]
        Resource = [
          aws_s3_bucket.frontend_bucket.arn,
          "${aws_s3_bucket.frontend_bucket.arn}/*",
        ]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_codedeploy_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

resource "aws_s3_bucket" "codepipeline_frontend_bucket" {
  bucket = "appexample-dev-codepipeline-frontend-bucket-us-east-1"
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "appexample-dev-frontend-us-east-1"
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.frontend_bucket.arn}/*",
        ]
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudfront::${local.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_codestarconnections_connection" "codestar_connection_frontend" {
  name          = "appexample-dev-frontend-codestar"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "example_codebuild_project" {
  name          = "appexample-dev-codebuild-frontend-us-east-1"
  description   = "Codebuild for appexample-dev frontend"
  build_timeout = "300"
  service_role  = aws_iam_role.codebuild_project_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "appexample-codebuild-frontend"
      stream_name = "appexample-codebuild-frontend"
    }
  }
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_codedeploy_app" "codedeploy_app" {
  name = "appexample-dev-codedeploy-frontend-us-east-1"
  compute_platform = "Server"
}

resource "aws_codepipeline" "frontend_pipeline" {
  name     = "appexample-dev-codepipeline-frontend-us-east-1"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_frontend_bucket.bucket
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
        ConnectionArn    = aws_codestarconnections_connection.codestar_connection_frontend.arn
        FullRepositoryId = "alexahdp/aws-terraform-cicd-frontend-example" # ENTER HERE YOUR URL
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
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"
      role_arn        = aws_iam_role.codedeploy_ec2_role.arn
      configuration   = {
        BucketName = aws_s3_bucket.frontend_bucket.bucket
        Extract = "true"
      }
    }
  }
}

resource "aws_cloudfront_origin_access_control" "cloudfront_s3_oac" {
  name                              = "appexample-cloudfront-s3-OAC"
  description                       = "Cloud Front S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_s3_oac.id
  }
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.bucket
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  price_class = "PriceClass_200"
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
