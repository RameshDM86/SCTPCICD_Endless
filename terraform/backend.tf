terraform {
  backend "s3" {
    bucket = "sctp-ce2-tfstate-chathra-bkt"
    key    = "chathra-ecs.tfstate" #Change the value  of this to yourname-docker-ec2.tfstate for  example
    region = "ap-southeast-1"
  }
}
