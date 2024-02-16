# install EBS CSI driver using HELM
# Resource: Helm Release, A Release is an instance of a chart running in a Kubernetes cluster
resource "helm_release" "ebs_csi_driver" {
    depends_on = [ aws_iam_role.ebs_csi_iam_role ]
    # this is the local name of the helm chart
    name = "${local.name}-aws-ebs-csi-driver"
    # where to pull the chart from
    repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
    chart = "aws-ebs-csi-driver"
    # which namespace to install it at
    namespace = "kube-system"
    # Value block with custom values to be merged with the values yaml
    # docker image to pull, based on region
    set {
      name = "image.repository"
      # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
      value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-ebs-csi-driver"
    }
    # this will create a service account when installing the helm chart
    set {
        name = "controller.serviceAccount.create"
        value = "true"
    }

    set {
      name  = "controller.serviceAccount.name"
      value = "ebs-csi-controller-sa"
    }
    # annotate the service account with the role that we created before, so it can create/edit ebs volumes
    set {
      name = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = "${aws_iam_role.ebs_csi_iam_role.arn}"
    }
}

output "ebs_csi_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.ebs_csi_driver.metadata
}

/*
this will create two service accounts
ebs-csi-controller-sa
ebs-csi-node-sa
*/
