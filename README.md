# Internal Application Load Balancer

Production-ready Internal ALB on GCP with Cloud Run backends across multiple regions.

---

## Overview

**Internal HTTPS Load Balancer** for private Cloud Run services in GCP.

- 🔒 **VPC-only access** (not internet-accessible)
- 🌍 **Multi-region** (northamerica-northeast1, us-central1)
- 🚀 **Cloud Run backends** via serverless NEGs
- 🔐 **SSL termination** with self-managed certificates
- 📝 **YAML configuration** - single source of truth

---

## Architecture
```
Client (VPC) → Forwarding Rule (Internal IP) → HTTPS Proxy (SSL)
→ Backend Service → NEGs → Cloud Run Services
```

**Resources Created:**
- 2× Internal IPs (one per region)
- 1× SSL Certificate
- 8× Network Endpoint Groups (4 services × 2 regions)
- 2× Backend Services (regional)
- 2× URL Maps + HTTPS Proxies + Forwarding Rules

---

## Quick Start

### 1. Prerequisites

- Terraform ≥ 1.3
- gcloud CLI configured
- GCP project with Compute & Cloud Run APIs enabled
- Cloud Run services deployed in both regions

### 2. Clone & Configure
```bash
git clone git@github.com:mostafaBachir/sami-ilb.git
cd sami-ilb
```

Edit `config.yaml` with your service names:
```yaml
cloudrun_services:
  - name: "your-service-1"
  - name: "your-service-2"
  - name: "your-service-3"
```

### 3. Deploy
```bash
terraform init
terraform plan
terraform apply
```

### 4. Get Internal IPs
```bash
terraform output internal_ip_addresses
```

---

## Configuration

**All settings in `config.yaml`:**
```yaml
project_id: "sami-ilb"
prefix: "mobility-internal"

regions:
  - "northamerica-northeast1"
  - "us-central1"

network: "projects/sami-ilb/global/networks/default"

subnetworks:
  northamerica-northeast1: "projects/.../subnetworks/default"
  us-central1: "projects/.../subnetworks/default"

certificate_path: "certs/certificate.crt"
private_key_path: "certs/private.key"

cloudrun_services:
  - name: "fetch-data"
  - name: "delete-data"
  - name: "create-data"
  - name: "checkout-data"
```

**To add a service:**
1. Deploy Cloud Run service in both regions
2. Add to `cloudrun_services` in config.yaml
3. Run `terraform apply`

---

## Testing

### Create Test VM
```bash
gcloud compute instances create test-vm \
  --zone=northamerica-northeast1-a \
  --subnet=default \
  --machine-type=e2-micro
```

### Test Connectivity
```bash
# Get internal IP
INTERNAL_IP=$(terraform output -json internal_ip_addresses | jq -r '.["northamerica-northeast1"]')

# Test from VM
gcloud compute ssh test-vm --zone=northamerica-northeast1-a \
  --command="curl -k https://$INTERNAL_IP"
```

---

## Project Structure
```
sami-ilb/
├── main.tf                    # Main orchestration
├── config.yaml                # Configuration (edit this!)
├── provider.tf                # GCP provider
├── backend.tf                 # Terraform Cloud backend
├── variable.tf                # Input variables
├── output.tf                  # Outputs
├── certs/                     # SSL certificates
│   ├── certificate.crt
│   └── private.key
├── networkendpointgroup/      # NEG module
│   ├── main.tf
│   ├── variable.tf
│   └── output.tf
└── backendservice/            # Backend service module
├── main.tf
├── variable.tf
└── output.tf
```

---

## Monitoring

### View Logs
```bash
# Recent logs
gcloud logging read "resource.type=http_load_balancer" --limit=20

# Errors only
gcloud logging read "resource.type=http_load_balancer AND httpRequest.status>=400"
```

### Check Resources
```bash
# Forwarding rules
gcloud compute forwarding-rules list --filter="name~mobility-internal"

# Backend health
gcloud compute backend-services get-health \
  mobility-internal-backend-northamerica-northeast1 \
  --region=northamerica-northeast1
```

---

## Troubleshooting

### Cannot Access Load Balancer

**Problem:** Timeout when connecting to internal IP

**Solution:**
1. Verify you're **inside the VPC** (use a VM in the VPC)
2. Check firewall rules:
```bash
gcloud compute firewall-rules create allow-internal-lb \
  --network=default \
  --allow=tcp:443 \
  --source-ranges=10.0.0.0/8
```

### Service Not Found

**Problem:** NEG reports Cloud Run service not found

**Solution:**
1. Verify service exists: `gcloud run services list --region=northamerica-northeast1`
2. Check **exact name match** in config.yaml (case-sensitive)
3. Service must exist in **both regions**

### SSL Certificate Error

**Problem:** SSL handshake failures

**Solution:**
```bash
# Verify certificate
openssl x509 -in certs/certificate.crt -text -noout

# Verify private key
openssl rsa -in certs/private.key -check
```

---

## Cost Estimation

| Resource | Monthly Cost |
|----------|-------------|
| Forwarding Rules (2×) | ~$36 |
| Data Processing | $0.008/GB |
| Internal Traffic | Free |
| Cloud Run | Variable |

**Total:** ~$40-50/month (excluding Cloud Run usage)

---

## Security

- ✅ **Internal-only** - No internet access
- ✅ **VPC isolated** - Private IPs only
- ✅ **SSL/TLS** - Encrypted traffic
- ⚠️ **Self-signed certs** - Replace in production
- ✅ **Least privilege** - Service account with minimal permissions

### Production Recommendations

1. Use Google-managed SSL certificates
2. Enable Cloud Armor for DDoS protection
3. Implement VPC Service Controls
4. Enable binary authorization for Cloud Run
5. Rotate certificates every 90 days

---

## Terraform Commands
```bash
# Initialize
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply

# View outputs
terraform output

# Destroy (careful!)
terraform destroy
```

---

## Collaboration

### For Team Members

**GitHub:** https://github.com/mostafaBachir/sami-ilb

**Setup:**
```bash
git clone git@github.com:mostafaBachir/sami-ilb.git
cd sami-ilb
```

**Make Changes:**
1. Edit `config.yaml`
2. Test: `terraform plan`
3. Deploy: `terraform apply`
4. Commit: `git add . && git commit -m "Update: description"`
5. Push: `git push`

---

## Important Notes

⚠️ **This is an INTERNAL load balancer:**
- ❌ NOT accessible from internet
- ✅ Only accessible from VPC
- ✅ Requires VPN/Interconnect for external access
- ✅ Perfect for private microservices

🔧 **Current Setup:**
- Test Cloud Run services (hello world)
- Self-signed SSL certificates
- Replace with your actual services in production

---

## Additional Documentation

- `SAMI_ONBOARDING.md` - Quick start for collaborators
- `STEP_BY_STEP_GUIDE.md` - Detailed deployment guide
- `PROJECT_CONTEXT.md` - Complete project context

---

## Support

- **Issues:** Create GitHub issue
- **Questions:** mostafa.bachir@gmail.com
- **GCP Console:** https://console.cloud.google.com/welcome?project=sami-ilb
- **Terraform Cloud:** https://app.terraform.io/app/Triforce/hyrule

---

## License

Private - Internal use only

---

**Authors:** Bachir Mostafa, Sami Islam  
**Version:** 1.0.0  
**Last Updated:** October 2025

---

Built with ❤️ for sami-ilb project
