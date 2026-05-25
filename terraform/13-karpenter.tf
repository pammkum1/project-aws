resource "helm_release" "karpenter" {

  namespace        = "karpenter"

  create_namespace = true

  name             = "karpenter"

  repository       = "oci://public.ecr.aws/karpenter"

  chart            = "karpenter"

  version          = "1.3.1"

  timeout          = 600

  values = [

<<EOF

settings:
  clusterName: ${aws_eks_cluster.eks.name}
  clusterEndpoint: ${aws_eks_cluster.eks.endpoint}

serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter.arn}

controller:
  env:
    - name: AWS_REGION
      value: us-east-2

EOF
  ]

  depends_on = [

    aws_iam_role_policy_attachment.karpenter,

    aws_eks_node_group.general
  ]
}