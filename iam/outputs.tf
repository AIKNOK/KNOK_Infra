# EKS 클러스터 생성 시, 필요한 IAM Role의 ARN을 외부에 출력
output "eks_role_arn" {
    value = aws_iam_role.eks_cluster_role.arn
    description = "EKS 클러스터용 IAM 역할 ARN"
}

# EKS 노드 그룹 생성 시, 필요한 IAM Role의 ARN을 외부에 출력
output "node_role_arn" {
    value = aws_iam_role.eks_node_role.arn
    description = "EKS 노드 그룹용 IAM 역할 ARN"
}