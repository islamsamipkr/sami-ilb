# Internal Application Load Balancer - sami-ilb

## Overview
Terraform module for deploying an Internal Application Load Balancer on GCP with Cloud Run backends.

## Architecture
- **Internal ALB**: Private load balancer (VPC-only access)
- **Multi-region**: Deployed in northamerica-northeast1 and us-central1
- **Cloud Run backends**: Via serverless NEGs
- **SSL termination**: Self-signed certificates

## Structure
```
sami-ilb/
├── main.tf                  # Main orchestration
├── config.yaml              # YAML configuration
├── provider.tf              # GCP provider setup
├── backend.tf               # Terraform Cloud backend
├── variable.tf              # Input variables
├── output.tf                # Outputs
├── networkendpointgroup/    # NEG module
├── backendservice/          # Backend service module
└── certs/                   # SSL certificates (gitignored)
```

## Prerequisites
- Terraform >= 1.3
- GCP project with Compute API enabled
- VPC network and subnets configured
- Cloud Run services deployed

## Configuration
Edit `config.yaml` to customize:
- Project ID and regions
- Network and subnetwork paths
- Cloud Run service names
- Backend settings

## Deployment
```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy infrastructure
terraform apply
```

## Outputs
After deployment:
- `internal_ip_addresses`: Internal IPs per region
- `load_balancer_urls`: HTTPS URLs for internal access

## Testing
Test from a VM within the VPC:
```bash
curl -k https://INTERNAL_IP
```

## Notes
⚠️ This is an **INTERNAL** load balancer - accessible only from within the VPC or via VPN/Interconnect.

## Author
Created for sami-ilb project

