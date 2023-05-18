# To create ASG_AutoScalingGroup, we shall first create Launch_Template.
# we have to create 6_auto_scaling_groups_ASG
# so that ASG by itself will create 2_instances each on (App)private_subnets

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

  image_id = data.aws_ami.ami.id

  instance_market_options {
  market_type = "spot"
}

  instance_type = var.instance_type

  tag_specifications {
  resource_type = "instance"
  tags = {
      Name = ${var.component}-${var.env}
  }
}

  # userdata.sh has to be sent in base64 format
  # the file_userdata.sh will be converted into base64_format using the function "filebase64encode"
  # " ${path.module} " >>  the file_userdata.sh will be searched in the location "p-tf-module-app"
  # " templatefile " >> is another function to replace the variables
  user_data = filebase64encode(templatefile("${path.module}/userdata.sh" , {
    component = var.component
    env       = var.env
  }) )
}


# Auto_Scaling_Group
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