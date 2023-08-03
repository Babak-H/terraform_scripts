## Instance Template
instance template: An instance template is a resource that you can use to create virtual machine (VM) instances, managed instance groups (MIGs), or reservations.
Instance templates define the machine type, boot disk image or container image, labels, startup script, and other instance properties

You can then use an instance template to do the following:
- Create individual VMs.
- Create VMs in a managed instance group (MIG).
- Create reservations for VMs.

Instance templates are a convenient way to save a VM instance's configuration, so that you can use it later to create VMs, groups of VMs, or reservations.
An instance template is a global resource that is not bound to a zone or a region. 
If you want to create a group of identical instances–a MIG–you must have an instance template that the group can use.
If you need to make changes to the configuration, create a new instance template. You can create a template based on an existing instance template, or based on an existing instance. 

## Instance Group
An instance group is a collection of virtual machine (VM) instances that you can manage as a single entity.
Compute Engine offers two kinds of VM instance groups, managed and unmanaged:
- Managed instance groups (MIGs) let you operate apps on multiple identical VMs. You can make your workloads scalable and highly available by taking advantage 
  of automated MIG services, including: autoscaling, auto-healing, regional (multiple zone) deployment, and automatic updating.
- Unmanaged instance groups let you load balance across a fleet of VMs that you manage yourself.


## Managed Instance Group (MIG)
Use a managed instance group (MIG) for scenarios like these:
- Stateful applications, such as databases, legacy applications, and long-running batch computations with checkpointing
- Stateless serving workloads, such as a website frontend
- Stateless batch, high-performance, or high-throughput compute workloads, such as image processing from a queue
- MIGs work with load balancing services to distribute traffic across all of the instances in the group.
advantages: Automatically repairing failed VMs, Application-based auto-healing.


google_compute_instance => https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
google_compute_disk => https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_disk
google_logging_project_sink => https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink
google_compute_instance_group => https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group
                              => https://github.com/GoogleCloudPlatform/terraform-google-managed-instance-group/blob/master/main.tf
                              => https://cloud.google.com/compute/docs/instance-groups/#unmanaged_instance_groups
google_compute_instance_template => https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template
external Application Load Balancers => https://cloud.google.com/load-balancing/docs/https/ext-http-lb-tf-module-examples
                                    => https://github.com/guillermo-musumeci/terraform-gcp-single-region-private-lb-unmanaged/blob/master/network-firewall.tf




