// output the id of all compute instances in a list
output "compute_instances_id" {
  value = google_compute_instance.datastore_compute[*].id
}

output "compute_instances_zone" {
  value = google_compute_instance.datastore_compute[*].zone
}