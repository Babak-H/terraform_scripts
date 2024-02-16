// both loadbalancers will be available in LoadBalancer section on AWS

resource "kubernetes_service_v1" "lb_service" {
  metadata {
    name = "myapp1-lb-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app
    }
    port {
      port = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service_v1" "lb_service_nlb" {
  metadata {
    name = "myapp1-lb-service-nlb"
    # To create Network Load Balancer
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"    
    }    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app      
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}