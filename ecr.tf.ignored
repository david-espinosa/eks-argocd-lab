resource "aws_ecr_repository" "hello-eks-nodejs" {
  name                 = "hello-eks-nodejs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "hello-eks-nodejs"
  }
}

output "ecr_repository_url" {
  description = "ECR repository URL — use this to tag and push your image"
  value       = aws_ecr_repository.hello-eks-nodejs.repository_url
}