terraform {
  backend "s3" {
    bucket         = "petclinic-tfstate-118821711881"
    key            = "petclinic/terraform.tfstate"
    region         = "af-south-1"
    use_lockfile   = true
    encrypt        = true
  }
}
