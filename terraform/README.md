# Terraform

This directory manages the project's Google Cloud infrastructure. All commands below are run from `terraform/`.

## What's managed

[main.tf](main.tf) provisions:

- `bandstand-postgres` — Cloud SQL instance (PostgreSQL 16, `us-central1`, `db-f1-micro`, ZONAL availability, backups enabled)
- `bandstand` — database on that instance
- `bandstand_app` — SQL user with an auto-generated 32-character password
- `bandstand-db-password` — Secret Manager secret holding the password (Secret Manager API is enabled as part of the same apply)

State is stored in GCS: bucket `bandstand-494122-tfstate`, prefix `terraform/state`. The Google provider targets project `bandstand-494122`.

## Prerequisites

- Terraform `>= 1.5` — check with:
  ```sh
  terraform version
  ```
- Application default credentials for the Google provider:
  ```sh
  gcloud auth application-default login
  ```
- Access to the `bandstand-494122` GCP project.

## Core workflow

Run from `terraform/`:

```sh
terraform init       # initialize backend + providers (first time, and after provider/backend changes)
terraform fmt        # canonicalize .tf formatting
terraform validate   # static config validation
terraform plan       # preview changes before applying
terraform apply      # apply changes (prompts for confirmation)
```

Less frequent:

```sh
terraform apply -auto-approve   # apply without prompting — use carefully
terraform destroy               # tear everything down — `deletion_protection = true` on the SQL instance will block this; flip to false in sql.tf first if you really mean it
```

## State management

```sh
terraform state list                  # list tracked resources
terraform state show <address>        # show attributes of one resource
terraform state rm <address>          # stop tracking without deleting
terraform import <address> <id>       # adopt an existing GCP resource into state
```

## Fetching the DB password

Downstream tooling (the Cloud SQL proxy path, `.env.cloud`) reads the password from Secret Manager and expects it URL-encoded, because the generated password contains URL-reserved characters (`!`, `#`, `+`, `(`, ...). Fetch and export it like this:

```sh
RAW="$(gcloud secrets versions access latest --secret=bandstand-db-password --project=bandstand-494122)"
export DB_PASSWORD="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$RAW")"
unset RAW
```

`.env.cloud` expands `${DB_PASSWORD}` from the shell, so the secret never lands on disk.

## Non-interactive / CI runs

For automation, save the plan and apply it in two steps so the apply is deterministic:

```sh
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
```

## Cost protection

This project targets a **monthly spend ceiling of ~$15**. Several layers of guardrails keep us there:

- **Budget alerts** ([billing.tf](billing.tf)) — `google_billing_budget.monthly` emails `var.notification_email` at 50/75/90/100/120% of `var.monthly_budget_usd`. The budget itself doesn't disable anything; it's a tripwire.
- **Cloud Run cap** — `max_instance_count = 2` ([cloudrun.tf](cloudrun.tf)) bounds worst-case Cloud Run compute under a sustained attack to roughly $40/month.
- **Cloud SQL fixed cost** — `db-f1-micro` is the cheapest tier; `disk_autoresize = false` and `disk_autoresize_limit = 10` ([sql.tf](sql.tf)) prevent disk from silently scaling up. `deletion_protection = true` blocks accidental DB drop.
- **Artifact Registry retention** — `cleanup_policies` on the `bandstand` repo ([cloudrun.tf](cloudrun.tf)) keeps the 10 most-recent image versions and deletes anything older than 30 days, so a year of CI pushes can't quietly add gigabytes of storage cost.

### Required setup before applying budget changes

`google_billing_budget` is scoped to a billing account, not a project, so the principal running `terraform apply` needs billing-account-level permissions:

```sh
# 1. Find your billing account ID.
gcloud billing accounts list

# 2. Grant the CI service account permission to manage budgets.
gcloud billing accounts add-iam-policy-binding <ACCOUNT_ID> \
  --member="serviceAccount:bandstand-ci-sa@bandstand-494122.iam.gserviceaccount.com" \
  --role="roles/billing.costsManager"

# 3. Put your billing account ID in terraform.tfvars (gitignored):
echo 'billing_account_id = "<ACCOUNT_ID>"' >> terraform.tfvars
```

If you also `terraform apply` locally, your own user needs the same role on the billing account (usually granted by default if you created the account).

### What to do if you get a budget alert email

1. Open https://console.cloud.google.com/billing/reports — filter by service to see what spiked.
2. If Cloud Run is the culprit, check the revisions page for unexpected scale-up or sustained traffic.
3. If Cloud SQL grew, check disk usage at https://console.cloud.google.com/sql/instances/bandstand-postgres.
4. Worst case, stop the SQL instance to halt the bleed: `gcloud sql instances patch bandstand-postgres --activation-policy NEVER --project bandstand-494122`.

## See also

The API selects between local Docker postgres and this Cloud SQL instance via the `APP_ENV` variable. See the root [README.md](../README.md) "Connecting to Cloud SQL locally" section for how the API consumes the provisioned infra.
