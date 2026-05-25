data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "karpenter" {

  name = "KarpenterControllerPolicy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "ec2:*",
          "ssm:GetParameter",
          "iam:PassRole",
          "eks:DescribeCluster"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "karpenter" {

  name = "KarpenterControllerRole"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${replace(
              aws_iam_openid_connect_provider.eks.url,
              "https://",
              ""
            )}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter" {

  role       = aws_iam_role.karpenter.name

  policy_arn = aws_iam_policy.karpenter.arn
}