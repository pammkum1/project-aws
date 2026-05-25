resource "aws_iam_role" "eks" {
  name = "${local.env}-${local.eks_name}-eks-cluster"

  assume_role_policy = <<POLICY
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        }
        
      }
    ]
  }

  POLICY
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource"aws_eks_cluster" "eks" {
  name     = "${local.env}-${local.eks_name}"
  version = local.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_public_access = true
    endpoint_private_access = false

    security_group_ids = [aws_security_group.eks.id]

    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id
    ]
  }

  access_config {
     authentication_mode      = "API"
     bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

resource "aws_security_group" "eks" {

  name   = "${local.env}-${local.eks_name}-sg"

  vpc_id = aws_vpc.main.id

  tags = {
    "karpenter.sh/discovery" = local.eks_name
  }
}