locals {
  parameters = concat( [ var.component ], var.parameters)

  # var.parameters >> we are controlling components on which component is allowed to access which parameters from input_file(main.tfvars)
  # concat >> to combine two lists
}
