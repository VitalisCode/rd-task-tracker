  # Remote state — keeps tfstate out of git
  terraform {
    backend "s3" {
      bucket         = "rd-task-tracker-tfstate"
      key            = "eks/terraform.tfstate"
      region         = "eu-central-1"
      encrypt        = true
      dynamodb_table = "rd-task-tracker-tfstate-lock"   # prevents concurrent applies
    }
  }