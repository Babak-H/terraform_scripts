** in case of changing the backend configurations (providers), use reconfigure commands:
    terraform init -reconfigure

** in terraform modules, if something is only repeated once, call it "this" for its name

always try to keep the modules small. its not a good idea to have large modules, that cant be customized

** to add helm charts to EKS cluster:
a. we need existing cluster
b. we need 'role' and 'policies' that allow that chart to access the resources in the cluster
c. attach role and policies together
d. create the resource "helm_release" with information about the role and it's arn, that will be set to k8s service
   account