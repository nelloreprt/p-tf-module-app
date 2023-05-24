# To create ASG_AutoScalingGroup, we shall first create Launch_Template.
# we have to create 6_auto_scaling_groups_ASG
# so that ASG by itself will create 2_instances each on (App)private_subnets

# step-1
# Launch_Template
resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"

  # our instances need to fetch parameters from aws_parameter_store
  # SPECIAL # SPECIAL # SPECIAL # SPECIAL # SPECIAL
  # we need to connect the instance_profile created in iam.tf
  # for my api_components to access aws_parameter_store, i need instance_profile
#  iam_instance_profile {
#  name = "test"
#  }


  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
   }

  image_id = data.aws_ami.ami.id

  instance_market_options {
  market_type = "spot"
}

  instance_type = var.instance_type

  # refering back security_group details
  vpc_security_group_ids = ["aws_security_group.allowall.id"]

  tag_specifications {
  resource_type = "instance"
    tags = {
      merge (var.tags, Name = "${var.component}-${var.env}")
  }

}

  # userdata.sh has to be sent in base64 format
  # the file_userdata.sh will be converted into base64_format using the function "filebase64encode"
  # " ${path.module} " >>  the file_userdata.sh will be searched in the location "p-tf-module-app"
  # " templatefile " >> is another function to replace the variables
  user_data = filebase64encode(templatefile("${path.module}/userdata.sh" , {
    component = var.component
    env       = var.env
  })
}

# step-2
# Auto_Scaling_Group (latest_version)
resource "aws_autoscaling_group" "main" {
  name = "${var.component}-${var.env}"
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnet_ids

  tag {
    key                 = "name"
    value               = "${var.component}-${var.env}"
    propagate_at_launch = true
  }

launch_template {
  id      = aws_launch_template.main.id
  version = "$Latest"        # launch_template supports versioning, always go with latest
  }
}

# step-3 Security_Group for ASG(instances)
resource "aws_security_group" "allowall" {
  name        = "${var.component}-${var.env}-security_group"
  description = "${var.component}-${var.env}-security_group"
  vpc_id      = var.vpc_id

  # attaching target_group to auto_scaling_group
  alb_target_group_arn = ["aws_lb_target_group.main.arn"]

  ingress {
    description      = "SSH"
    from_port        = 22           # we are opening To bastion_cidr
    to_port          = 22           # we are opening opening port 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr     # bastion_node Private_ip is used
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "APP"
    from_port        = var.port           # we are opening To bastion_cidr
    to_port          = var.port           # we are opening opening port 22
    protocol         = "tcp"
    cidr_blocks      = var.cidr_block     # here we have to specify which subnet should access the servers (not in terms of subnet_id, but in terms of cidr_block)
  }

  tags = {
    merge (var.tags, Name = "${var.component}-${var.env}-security-group")
}
}

# create Target_group >> inside ASG (because the servers are created by ASG)
resource "aws_lb_target_group" "main" {
   name     = "${var.component}-${var.env}-target-group"
   port     = var.port
   protocol = "HTTP"
   vpc_id   = var.vpc_id

   # In the Target_Groups we will have Healt_Check Option
   health_check {
   enabled = true
   healthy_threshold = 2
   unhealthy_threshold = 2
   timeout = 5
   interval = 5
      }

   tags = {
     merge (var.tags, Name = "${var.component}-${var.env}-target-group")
    }



#    I.e Load_Balancer name we will give in C_Name record
#    using CNAME of Route53 >> cname = name to name mapping
#    Note: so far we know [DNS_Records name to ip_address]
#    This is how you wil send traffic to load_balancer
# So if any one hitting from internet with dev.nellore.online
# it will be allowed to access the (Public_LB + Private_LB) (as the rule is matching)
resource "aws_route53_record" "name" {
    zone_id = data.aws_route53_zone.domain.zone_id      # input >> dns_domain = "nellore.online"
    name    = ${var.component}-${var.env}-${var.dns_domain}              # catalogue-dev-nelllore.online
    type    = "CNAME"
    ttl     = 30
    records = var.alb_records    # hitting from internet with dev.nellore.online >> allowed to access the (Public_LB + Private_LB)
                                 # cname = name to name
}

# adding rule in Listner----(this is Listener, listener is different vs Listener_rule is different)---------

# Forward action
resource "aws_lb_listener_rule" "listner_rule" {
      listener_arn = var.listener_arn # from output >> module.alb
      priority     = var.listener_priority   # order of listener >> from input "listener_priority = 10"
      # multiple_rules are there,
      # so, to process the order of listener_RULES in order one after the other based on Listener_Priority_number
      # same Listener_Priority_number can be alloted to Public_LB & Private_LB
      # Listener_Priority_number order does not matter for us

      # step-2
      action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main.arn
      }

      # step-1
      condition {
      host_header {
      values = ["${var.component}-${var.env}-${var.dns_domain}"]  # dns_name from >> "aws_route53_record.name"
      }
      }
    }