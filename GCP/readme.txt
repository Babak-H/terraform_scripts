**** GCP Snapshot *****
gcp snapshot => to back up persistent disks in gcp
can be scheduled per day or week,...
snapshot can be regional or multi-regional (can be stored in same region as disk or in several regions)

manual snapshot
scheduled snapshot

** Manual **
in GUI => go to VM => go to disk that you want to backup => click "create snapshot"
                                                                - snapshot name
                                                                - source disk
                                                                - location: region /multi-region


$ gcloud compute snapshots create proxysql-test-snapshot-1 --project=lpgprj-b2b-p-mysql-us-01 --source-disk=lpgmysql-proxysql-p-useast1b-001-code --source-disk-zone=us-east1-b --storage-location=us


** Scheduled **
go to snapshot tab => click "Create a snapshot schedule" => - scheduled snapshot name
                                                            - region (should be same region as the disk)
                                                            - location: region /multi-region
                                                            - schedule frequency: hourly/daily/weekly
                                                            - start time: day-of-week/hour
                                                            - auto delete after: 14days
                                                            - delete snapshot after deleting the orignal disk: yes/no


// weekly
$ gcloud compute resource-policies create snapshot-schedule proxysql-scheduled-snapshot-1 --project=lpgprj-b2b-p-mysql-us-01 --region=us-east1 --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --weekly-schedule-from-file=SCHEDULE_FILE_PATH --storage-location=us-east1

// daily
$ gcloud compute resource-policies create snapshot-schedule proxysql-scheduled-snapshot-2 --project=lpgprj-b2b-p-mysql-us-01 --region=us-east1 --max-retention-days=14 --on-source-disk-delete=keep-auto-snapshots --daily-schedule --start-time=07:00 --storage-location=us-east1

** add disk to scheduled snapshots **
go to disks => select the target disk => click edit => select the "snapshot schedule" and save

$ gcloud compute disks add-resource-policies lpgmysql-proxysql-p-useast1b-001-code --resource-policies proxysql-scheduled-snapshot-2 --zone us-east1-b

* create disk from snapshot *
- name
- location: single zone / regional
- source : the snapshot source
- disk type
- size (set same as disk size)
- enable schedule (so new disk can also be snapshoted via schedule)
- encyption: google managed / customer managed

$ gcloud compute disks create disk-from-snapshot-test-1 --project=lpgprj-b2b-p-mysql-us-01 --type=pd-standard --size=100GB --resource-policies=projects/lpgprj-b2b-p-mysql-us-01/regions/us-east1/resourcePolicies/proxysql-scheduled-snapshot --zone=us-east1-b --source-snapshot=projects/lpgprj-b2b-p-mysql-us-01/global/snapshots/proxysql-test-snapshot-1


* attach disk to machine *
go to instance => click edit => Additional disks: attach existing disk => select the disk and click save

$ gcloud compute instances attach-disk lpgmysql-proxysql-p-useast1b-001 --disk disk-from-snapshot-test-1



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


**************** Terraform GCP project instruction: ****************
- main folder 
  backend.tf => remote backend
  main.tf => include "computeInstance" module and "lp_project_apis" remote module
  providers.tf => gcp provider
  varibales.tf => variables defined
  versions.tf , outputs.tf => empty for now

- config folder
  main.tf => create kafka and zookeeper instances (based on computeinstance module) and logSink (google_logging_project_sink) based on remote module
  outputs.tf => varibales (ip address) that can be used in other modules

- modules/compute_instance folder
  main.tf => create a virtual machine with two (code, data) external storages and static ip
  variables.tf => list of variables for compute_instance, used to customize module in config/main
  outputs.tf => varibales that can be used in other modules

- VMs defined in modules/compute_instance
- several instances created in config/ as modules
- everything is added up in main/ folder

