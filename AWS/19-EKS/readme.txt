3 basic workloads:
        coredns | deployment
        aws-node | daemonset => runs on every node
        kube-proxy | daemonset => runs on every node


# update kubeconfig to be able to connect to EKS cluster from local machine
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>
aws eks --region us-east-1 update-kubeconfig --name hr-dev-eksdemo1

kubectl get nodes
kubectl describe deploy coredns -n kube-system
