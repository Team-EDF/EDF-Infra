terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-398875891485-teamedf"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "edf-project-terraform-lock"
  }
}
