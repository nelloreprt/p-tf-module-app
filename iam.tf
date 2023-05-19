# step -1 >> Create policy
resource "aws_iam_policy" "main" {
  name        = "${var.component}-${var.env}-iam-policy"
  path        = "/"
  description = "${var.component}-${var.env}-iam-policy

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        Resource : ["arn:aws:ssm:us-east-1:${data.aws_caller_identity.account.account_id}:parameter/${var.env}.${var.component}*"]
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : "ssm:DescribeParameters",
        "Resource" : "*"
      }

    ]
  })
}

# Step-2 >> create role
resource "aws_iam_role" "main" {
  name = "${var.component}-${var.env}-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    merge (var.tags, Name = "${var.component}-${var.env}")

}

# step -3 >> Attach policy to role
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

# step -4 >> Create instance profile to ec2 (using ARN_details)
resource "aws_iam_instance_profile" "main" {
  name = "${var.component}-${var.env}-iam-instance-profile"
  role = aws_iam_role.main.name
}




















