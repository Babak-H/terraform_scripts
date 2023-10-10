// iam role for eks cluster master node
resource "aws_iam_role" "master" {
  name = "ed-eks-master"

  assume_role_policy = <<POlICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POlICY
}

// attach these 3 (existing) policies to the master IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.master.name
}

// create the worker node IAM role
resource "aws_iam_role" "worker" {
  name = "ed-eks-worker"

  assume_role_policy = <<POlICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POlICY
}

// create autoscaler iam policy
resource "aws_iam_policy" "autoscaler" {
  name   = "ed-eks-autoscaler-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeTags",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

// attach these (existing) policies to the worker node IAM role
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "x-ray" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.worker.name
}

// attach autoscaler policy to worker node IAM role
resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

// An instance profile is a container for an IAM role that you can use to pass role information to an EC2 instance when the instance starts
resource "aws_iam_instance_profile" "worker" {
  depends_on = [aws_iam_role.worker]
  name = "ed-eks-worker-new-profile"
  role = aws_iam_role.worker.name
}

###############################

// create the cluster, make sure all the needed policies are attached to the master node and define the needed subnets
resource "aws_eks_cluster" "eks" {
  name = "ed-eks-01"
  role_arn = aws_iam_role.master.arn

  vpc_config {
    subnet_ids = [var.subnet_ids[0], var.var.subnet_ids[1]]
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
   ]
}

// Manages an EKS Node Group, which can provision and optionally update an Auto Scaling Group of Kubernetes Worker nodes compatible with EKS
resource "aws_eks_node_group" "backend" {
  cluster_name = aws_eks_cluster.eks.name
  node_group_name = "dev"
  node_role_arn = aws_iam_role.worker.arn
  subnet_ids = [var.subnet_ids[0], var.var.subnet_ids[1]]

  capacity_type = "ON_DEMAND"
  disk_size = "20"
  instance_types = ["t2.small"]

  scaling_config {
    desired_size = 2
    max_size = 3
    min_size = 1
  }

  update_config {
    max_unavailable = 1
  }

  remote_access {
    # TODO: change the key name
    # this is the same key that we used for login to the test ec2 instance (vpc.tf file)
    ec2_ssh_key = "rtp-03"
    source_security_group_ids = [var.sg_ids]
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
   ]
}