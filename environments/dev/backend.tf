terraform {
  backend "s3" {
    bucket         = "edf-terraform-state-556988669310"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "edf-terraform-lock"
  }
}
