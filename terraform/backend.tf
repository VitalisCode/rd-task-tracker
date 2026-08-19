# Remote state — keeps tfstate out of git
terraform {
  backend "s3" {
    bucket         = "rd-tasks-tracker-tfstate"
    key            = "eks/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "rd-tasks-tracker-tfstate-lock" # prevents concurrent applies
  }
}

terraform {
  backend "s3" {}
}