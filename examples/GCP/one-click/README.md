# GCP one-click example

This example is a wrapper root module that:
1. Calls the main module to allocate a VPC CIDR + subnets in BloxOne DDI (IPAM)
2. Creates a GCP VPC network and subnetworks using those CIDRs
3. Optionally creates demo GCE instances with static IPs allocated from BloxOne

## Run
From this folder (or from repo root using `-chdir`):
- `terraform init`
- `terraform plan`
- `terraform apply`

Notes:
- You must configure authentication for both providers:
  - `bloxone` (e.g., `BLOXONE_API_KEY` / `BLOXONE_CSP_URL`)
  - `google` (Application Default Credentials, service account key, workload identity, etc.)
- The example uses `demo.auto.tfvars` for inputs.

Recommended order (so auth works everywhere):
1) BloxOne auth (in your shell)
```
export BLOXONE_API_KEY='<your api key>'
export BLOXONE_CSP_URL='https://csp.infoblox.com'  # or your CSP base URL
```

If your environment uses `CSP_API_KEY` / `CSP_URL`, map them like this before running Terraform:
```
export BLOXONE_API_KEY="${BLOXONE_API_KEY:-$CSP_API_KEY}"
export BLOXONE_CSP_URL="${BLOXONE_CSP_URL:-${CSP_URL:-https://csp.infoblox.com}}"
```

Sanity check (should return `HTTP 200`):
```
curl -sS -o /dev/null -w "HTTP %{http_code}\n" \
  -H "Authorization: Token ${BLOXONE_API_KEY}" \
  "${BLOXONE_CSP_URL%/}/api/ddi/v1/ipam/ip_space"
```

2) GCP auth (gcloud)
```
gcloud auth application-default login
gcloud config set project '<your-gcp-project-id>'
```

3) Run Terraform (from repo root)
```
terraform -chdir=examples/GCP/one-click init
terraform -chdir=examples/GCP/one-click plan
terraform -chdir=examples/GCP/one-click apply
```

## Troubleshooting

If you see:
- `No IP Space found with name '...'`

Then update `ip_space` in `demo.auto.tfvars` to an existing BloxOne IP space name (exact match).

To list IP spaces quickly:
```
curl -sS -H "Authorization: Token ${BLOXONE_API_KEY}" \
  "${BLOXONE_CSP_URL%/}/api/ddi/v1/ipam/ip_space" | jq -r '.[].name'
```

If you see:
- `No parent container found ... with tag Cloud='GCP'`

Either:
- Keep `parent_pool_cidr` set in `demo.auto.tfvars` so Terraform creates the tagged parent pool, or
- Create a parent pool manually in that IP space with tags `Cloud = GCP` and `Role = parent-pool`.

## Optional: demo GCE instances

Set `gcp_vm_enabled = true` in `demo.auto.tfvars` to provision GCE instances with static private IPs
allocated from BloxOne DDI. This requires `dns_zone_fqdn` to be set so that host IP reservations
are made in BloxOne before the instances are created.

If `gcp_vm_ssh_public_key` is not set, Terraform generates an ED25519 keypair. Retrieve the
private key after apply with:
```
terraform -chdir=examples/GCP/one-click output -raw gcp_vm_private_key_pem
```

If `gcp_vm_public_ip = true`, static external IPs and an SSH firewall rule are also created.
