# EKS 리소스 이름에 쓰일 클러스터 이름을 외부에서 입력받음
# IAM Role 이름에 "${var.cluster_name}-eks-node-role"처럼 활용됨
variable "cluster_name" {
    description = "EKS 클러스터 이름 (IAM Role 이름 구성용)"
    type = string
}