bucket         = "rd-tasks-tracker-tfstate"
key            = "eks/terraform.tfstate"
region         = "eu-central-1"
encrypt        = true
dynamodb_table = "rd-tasks-tracker-tfstate-lock" # prevents concurrent applies