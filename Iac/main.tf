# ============================================================
# IAM User
# ============================================================
resource "aws_iam_user" "dev_user" {
  name = var.user_name
}

# Programmatic access key
resource "aws_iam_access_key" "dev_user_key" {
  user = aws_iam_user.dev_user.name
}

# Attach multiple user policies
resource "aws_iam_user_policy_attachment" "user_policies" {
  for_each   = toset(var.user_managed_policies)
  user       = aws_iam_user.dev_user.name
  policy_arn = each.value
}

# ============================================================
# IAM Role + Trust Relationship
# ============================================================
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.dev_user.arn]
    }
  }
}

resource "aws_iam_role" "project_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "role_policies" {
  for_each   = toset(var.role_managed_policies)
  role       = aws_iam_role.project_role.name
  policy_arn = each.value
}
