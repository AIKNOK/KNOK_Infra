##############################
# EKS 클러스터용 IAM 역할 생성
##############################
resource "aws_iam_role" "eks_cluster_role" {
    name = "${var.cluster_name}-eks-cluster-role"

    # 이 IAM 역할을 누가 assume할 수 있는지 정의하는 신뢰 정책
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                # eks.amazonaws.com이 이 역할을 assume 가능하도록 허용
                # 즉, EKS 클러스터가 이 Role을 사용할 수 있도록 함
                Principal = {
                    Service = "eks.amazonaws.com"
                }
                # 해당 주체가 이 역할을 Assume할 수 있도록 허용
                Action = "sts:AssumeRole"
            }
        ]
    })
    tags = {
        Name = "EKS Cluster Role"
    }
 }

 # 위에서 만든 클러스터 역할에 AmazonEKSClusterPolicy(AWS 관리형 정책) 부여
 # 이 정책은 클러스터가 AWS 리소스를 사용할 수 있게 허용하는 권한(Permission)
 resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster_role.name                    
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" 
 }

##############################################
# EKS 노드 그룹(EC2 워커 노드)용 IAM 역할 생성
##############################################
resource "aws_iam_role" "eks_node_role" {
    name = "${var.cluster_name}-eks-node-role"

    # EC2 인스턴스(노드)가 이 역할을 assume 가능하도록 설정
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
    tags = {
        Name = "EKS Node Role"
    }
}

# 워커 노드가 EKS 클러스터와 통신하고 필요한 리소스를 조작할 수 있게 권한 부여
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    role = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" 
}

# 워커 노드에게 VPC CNI(네트워크 인터페이스) 작업 권한 부여
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    role = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ECR에서 컨테이너 이미지를 pull하기 위한 권한 부여
resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
    role = aws_iam_role.eks_node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}