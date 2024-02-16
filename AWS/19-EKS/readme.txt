3 basic workloads:
        coredns | deployment
        aws-node | daemonset => runs on every node
        kube-proxy | daemonset => runs on every node


# update kubeconfig to be able to connect to EKS cluster from local machine
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

kubectl get nodes
kubectl describe deploy coredns -n kube-system


aws eks --region eu-west-1 update-kubeconfig --name TestCluster

kubectl apply -f .

kubectl get nodes
kubectl get nodes -o wide
kubectl get svc

kubectl delete -f .


for creating remote terraform state:

Go to Services -> S3 -> Create Bucket
        Bucket name: terraform-on-aws-eks
        Region: US-East (N.Virginia)
        Bucket settings for Block Public Access: leave to defaults
        Bucket Versioning: Enable
        Rest all leave to defaults
        Click on Create Bucket
Create Folder
        Folder Name: dev
        Click on Create Folder
Create Folder
        Folder Name: dev/eks-cluster
        Click on Create Folder
Create Folder
        Folder Name: dev/app1k8s
        Click on Create Folder


Create Dynamo DB Table for EKS Cluster
        Table Name: dev-ekscluster
        Partition key (Primary Key): "LockID" (Type as String)
        Table settings: Use default settings (checked)
        Click on Create

Create Dynamo DB Table for app1k8s
        Table Name: dev-app1k8s
        Partition key (Primary Key): "LockID" (Type as String)
        Table settings: Use default settings (checked)
        Click on Create

terraform apply -destroy -auto-approve
rm -rf .terraform*


# Verify Kubernetes Service Account
kubectl get sa
kubectl describe sa irsa-demo-sa
        Observation:
        1. We can see that IAM Role ARN is associated in Annotations field of Kubernetes Service Account


# List & Describe Kubernetes Jobs
kubectl get job
kubectl describe job irsa-demo
        Observation:
        1. You should see COMPLETIONS 1/1
        2. You should see when you describe Pods Statuses:  0 Running / 1 Succeeded / 0 Failed
kubectl logs -f -l app=irsa-demo

# Verify EBS CSI Pods
kubectl -n kube-system get pods 

kubectl -n kube-system get deploy 
kubectl -n kube-system describe deploy ebs-csi-controller 

kubectl -n kube-system get pods
kubectl -n kube-system logs -f ebs-csi-controller-***************
kubectl -n kube-system logs -f liveness-probe 

# each kubbernetes node will have one daemonset running on it
kubectl -n kube-system get daemonset
kubectl -n kube-system describe ds ebs-csi-node

kubectl -n kube-system get sa 
kubectl -n kube-system describe sa ebs-csi-controller-sa

# Verify Storage Class
kubectl get storageclass

# Verify PVC and PV
kubectl get pvc
kubectl get pv

# see which user is connecting to the aws network
aws sts get-caller-identity

# EKS List AddOns for a EKS Cluster
aws eks list-addons --cluster-name hr-dev-eksdemo1