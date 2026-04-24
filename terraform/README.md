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
terraform destroy               # tear everything down — note that deletion_protection is off on the SQL instance, so this will really drop the DB
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

## See also

The API selects between local Docker postgres and this Cloud SQL instance via the `APP_ENV` variable. See the root [README.md](../README.md) "Connecting to Cloud SQL locally" section for how the API consumes the provisioned infra.
