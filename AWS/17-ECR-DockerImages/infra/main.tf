# resource "aws_ecr_repository" "backend" {
#   name = "backend"
#   image_tag_mutability = "MUTABLE"
#   image_scanning_configuration {
#     scan_on_push = true
#   }
#   tags = {
#     env = "dev"
#     name = "backend"
#   }
# }

# creates an docker image repository inside the amazon ECR
# each repository is the holder for different versions of ONE image/application.
resource "aws_ecr_repository" "repository" {
  for_each = toset(var.repository_list)
  name     = each.key
  #  prevent image tags from being overwritten. After the repository is configured for immutable tags, an ImageTagAlreadyExistsException error is returned if you attempt to push an image with a tag that is already in the repository
  image_tag_mutability = "MUTABLE"
  # scan the image for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    env  = "dev"
    name = each.key
  }
}

# resource "docker_registry_image" "backend" {
#   name = "${aws_ecr_repository.backend.repository_url}:latest"
#   build {
#     context = "../application"
#     dockerfile = "backend.Dockerfile"
#   }
# }

# this is from the docker provider, to create a docker image from the docker file and source code
resource "docker_registry_image" "image" {
  for_each = toset(var.repository_list)
  # images full name and version
  # repository[each.key] => repository["backend"], repository["frontend"]
  name = "${aws_ecr_repository.repository[each.key].repository_url}:latest"

  build {
    # where is the folder where source code and docker file exsit
    context = "application"
    # full name of the docker file inside the context folder
    dockerfile = "${each.key}.Dockerfile"
  }
}

resource "docker_registry_image" "custom_image" {
  name = "${aws_ecr_repository.repository["frontend"].repository_url}:other-version"

  build {
    context = "application"
    dockerfile = "custom_image.Dockerfile"
  }
}