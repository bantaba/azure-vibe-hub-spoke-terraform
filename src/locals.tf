# locals { # https://github.com/smorenburg/pathway-to-aks-deploying-with-terraform/blob/main/terraform/main.tf
#   # Set the application name    
#   app = ""

#   # Lookup and set the location abbreviation, defaults to na (not available).
#   location_abbreviation = try(var.location_abbreviation[var.location], "na")

#   # Construct the name suffix.
#   prefix = "${local.location_abbreviation}-${terraform.workspace}-"

#   # Construct the name suffix.
#   suffix = "${local.app}-${terraform.workspace}-${local.location_abbreviation}"

#   # Clean and set the public IP address
#   public_ip = chomp(data.http.public_ip.response_body)

#   # Set the authorized IP ranges for the Kubernetes cluster.
#   authorized_ip_ranges = ["${local.public_ip}/32"]
# }