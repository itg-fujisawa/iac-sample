output "network" {
  value = google_compute_network.main.id
}
output "network_name" {
  value = google_compute_network.main.name
}
output "subnets" {
  value = { for k, v in google_compute_subnetwork.sub : k => v.id }
}
output "psa_connection" {
  value = google_service_networking_connection.psa.id
}
output "interconnect_pairing_keys" {
  value     = { for k, v in google_compute_interconnect_attachment.partner : k => v.pairing_key }
  sensitive = true
}
