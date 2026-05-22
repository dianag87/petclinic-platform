terraform {
  backend "s3" {
    bucket         = "petclinic-tfstate-820444288149"
    key            = "petclinic/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "petclinic-terraform-locks"
  }
}
