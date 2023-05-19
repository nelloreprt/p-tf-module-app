# data_source block to fetch ami in aws_account
data "aws_ami" "ami" {
  name_regex       = "devops-practice-with-ansible"
  owners           = ["self"]

}

# to get >> peer_owner_id
data "aws_caller_identity" "account" {}