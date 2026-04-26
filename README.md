# Turborepo starter

This Turborepo starter is maintained by the Turborepo core team.

## Using this example

Run the following command:

```sh
npx create-turbo@latest
```

## What's inside?

This Turborepo includes the following packages/apps:

### Apps and Packages

- `docs`: a [Next.js](https://nextjs.org/) app
- `web`: another [Next.js](https://nextjs.org/) app
- `@repo/ui`: a stub React component library shared by both `web` and `docs` applications
- `@repo/eslint-config`: `eslint` configurations (includes `eslint-config-next` and `eslint-config-prettier`)
- `@repo/typescript-config`: `tsconfig.json`s used throughout the monorepo

Each package/app is 100% [TypeScript](https://www.typescriptlang.org/).

### Utilities

This Turborepo has some additional tools already setup for you:

- [TypeScript](https://www.typescriptlang.org/) for static type checking
- [ESLint](https://eslint.org/) for code linting
- [Prettier](https://prettier.io) for code formatting

### Build

To build all apps and packages, run the following command:

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed (recommended):

```sh
cd my-turborepo
turbo build
```

Without global `turbo`, use your package manager:

```sh
cd my-turborepo
npx turbo build
pnpm dlx turbo build
pnpm exec turbo build
```

You can build a specific package by using a [filter](https://turborepo.dev/docs/crafting-your-repository/running-tasks#using-filters):

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed:

```sh
turbo build --filter=docs
```

Without global `turbo`:

```sh
npx turbo build --filter=docs
pnpm exec turbo build --filter=docs
pnpm exec turbo build --filter=docs
```

### Develop

To develop all apps and packages, run the following command:

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed (recommended):

```sh
cd my-turborepo
turbo dev
```

Without global `turbo`, use your package manager:

```sh
cd my-turborepo
npx turbo dev
pnpm exec turbo dev
pnpm exec turbo dev
```

You can develop a specific package by using a [filter](https://turborepo.dev/docs/crafting-your-repository/running-tasks#using-filters):

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed:

```sh
turbo dev --filter=web
```

Without global `turbo`:

```sh
npx turbo dev --filter=web
pnpm exec turbo dev --filter=web
pnpm exec turbo dev --filter=web
```

### Remote Caching

> [!TIP]
> Vercel Remote Cache is free for all plans. Get started today at [vercel.com](https://vercel.com/signup?utm_source=remote-cache-sdk&utm_campaign=free_remote_cache).

Turborepo can use a technique known as [Remote Caching](https://turborepo.dev/docs/core-concepts/remote-caching) to share cache artifacts across machines, enabling you to share build caches with your team and CI/CD pipelines.

By default, Turborepo will cache locally. To enable Remote Caching you will need an account with Vercel. If you don't have an account you can [create one](https://vercel.com/signup?utm_source=turborepo-examples), then enter the following commands:

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed (recommended):

```sh
cd my-turborepo
turbo login
```

Without global `turbo`, use your package manager:

```sh
cd my-turborepo
npx turbo login
pnpm exec turbo login
pnpm exec turbo login
```

This will authenticate the Turborepo CLI with your [Vercel account](https://vercel.com/docs/concepts/personal-accounts/overview).

Next, you can link your Turborepo to your Remote Cache by running the following command from the root of your Turborepo:

With [global `turbo`](https://turborepo.dev/docs/getting-started/installation#global-installation) installed:

```sh
turbo link
```

Without global `turbo`:

```sh
npx turbo link
pnpm exec turbo link
pnpm exec turbo link
```

## Connecting to Cloud SQL locally

The Sinatra API can run against either local Docker postgres or the Cloud SQL instance managed by [terraform/main.tf](terraform/main.tf). Selection is driven by `APP_ENV`:

- `APP_ENV=local` (default) — uses `apps/sinatra-api/.env.local`, talks to the `postgres` service in Docker Compose
- `APP_ENV=cloud` — uses `apps/sinatra-api/.env.cloud`, talks to Cloud SQL via `cloud-sql-proxy`

Terraform manages the Cloud SQL instance, database user, and password secret — see [terraform/README.md](terraform/README.md) for the infrastructure workflow and the DB password fetch recipe (`DB_PASSWORD` below is exported by that recipe).

### Start the proxy and api against Cloud SQL

The `api` container defaults to local postgres. To point it at Cloud SQL via the proxy, export `APP_DATABASE_URL` before starting compose (note the hostname is `cloud-sql-proxy`, not `127.0.0.1` — that's the docker-network service name):

```sh
export APP_DATABASE_URL="postgres://bandstand_app:${DB_PASSWORD}@cloud-sql-proxy:5432/bandstand"
docker compose --profile cloud up -d cloud-sql-proxy api
```

Run the API test suite against `http://localhost:4567` — see [apps/sinatra-api/bruno/README.md](apps/sinatra-api/bruno/README.md).

### Run migrations against Cloud SQL

From `apps/sinatra-api/`:

```sh
APP_ENV=cloud bundle exec rake db:migrate
APP_ENV=cloud bundle exec rake db:version
```

The Rakefile prints the masked `DATABASE_URL` before running so you can confirm which database you're pointed at.

## Deploying to Cloud Run (with Cloud SQL)

The Sinatra API runs on Cloud Run and talks to Cloud SQL over a Unix socket. No sidecar, no public IP on the database — the wiring is:

- **Cloud SQL volume mount** — `google_cloud_run_v2_service.api` declares a `volumes.cloud_sql_instance` block (see [terraform/cloudrun.tf](terraform/cloudrun.tf)). Cloud Run runs the SQL Auth Proxy for you and exposes the instance as a Unix socket at `/cloudsql/<connection-name>`.
- **Password from Secret Manager** — `DB_PASSWORD` is injected as an env var via `value_source.secret_key_ref` pointing at `bandstand-db-password`. Nothing secret lives in the image or in Terraform state.
- **`DATABASE_URL` built at boot** — [apps/sinatra-api/docker-entrypoint.sh](apps/sinatra-api/docker-entrypoint.sh) URL-encodes `DB_PASSWORD` and assembles `postgres://user:pw@/db?host=/cloudsql/<conn>` before exec-ing the server. URL-encoding is mandatory because the auto-generated password contains URL-reserved chars (`#`, `&`, `+`, `[`, `]`, …). The Sequel connect call ([apps/sinatra-api/db/connection.rb](apps/sinatra-api/db/connection.rb)) is identical local vs. cloud.
- **Runtime IAM** — the `bandstand-api-sa` service account ([terraform/iam.tf](terraform/iam.tf)) holds `roles/cloudsql.client`, `roles/secretmanager.secretAccessor` (scoped to the password secret), and `roles/logging.logWriter`.

### Prerequisites

```sh
gcloud auth login
gcloud auth application-default login   # used by Terraform's Google provider
gcloud config set project bandstand-494122
cd terraform && terraform init
```

### One-time bootstrap

The first time this project is provisioned in a new GCP project, enable the APIs and create IAM + the Artifact Registry repo before any image exists. From `terraform/`:

```sh
# 1. Enable required APIs (Cloud Run, Artifact Registry, Cloud Build, Cloud SQL Admin).
terraform apply \
  -target=google_project_service.run \
  -target=google_project_service.artifactregistry \
  -target=google_project_service.cloudbuild \
  -target=google_project_service.sqladmin

# 2. Provision the runtime SA, IAM bindings, and Artifact Registry repo.
terraform apply \
  -target=google_artifact_registry_repository.api \
  -target=google_service_account.api_runtime \
  -target=google_secret_manager_secret_iam_member.api_db_password \
  -target=google_project_iam_member.api_sql_client \
  -target=google_project_iam_member.api_log_writer \
  -target=google_project_iam_member.compute_default_cloudbuild_builder
```

The last binding (`compute_default_cloudbuild_builder`) grants the Compute Engine default SA the permissions Cloud Build needs to write build artifacts to its staging bucket — required on GCP projects created after the 2024 Cloud Build IAM defaults change.

### Build, push, deploy

Tag images with the short git SHA so rollbacks are just a re-apply with a different `image_tag`:

```sh
TAG=$(git rev-parse --short HEAD)

# 1. Build on Cloud Build (native linux/amd64, sidesteps Apple Silicon mismatch).
gcloud builds submit apps/sinatra-api \
  --tag us-central1-docker.pkg.dev/bandstand-494122/bandstand/api:${TAG} \
  --project bandstand-494122

# 2. Roll the new image out to Cloud Run.
cd terraform
terraform apply -var image_tag=${TAG}
```

The first apply (with no existing service) takes ~2 minutes because Cloud Run waits for the startup probe (`GET /health`) to pass. Subsequent rollouts re-use the revision plumbing and finish in ~30s.

### Run migrations

Migrations are run from a laptop through the Cloud SQL Auth Proxy — Cloud Run does not run them automatically. Use the `APP_ENV=cloud` flow documented in [Connecting to Cloud SQL locally](#connecting-to-cloud-sql-locally) above.

### Verify

```sh
URL=$(cd terraform && terraform output -raw api_url)

curl -fsS "$URL/health"     # → {"status":"ok","service":"api","time":"..."}
curl -fsS "$URL/companies"  # → 200 with [] or rows (proves the socket + password decoding work)

cd apps/sinatra-api/bruno && bru run --env cloud   # full CRUD smoke test
```

### Rollback

Re-apply the previous image tag — no rebuild needed because Artifact Registry retains every pushed image:

```sh
cd terraform
terraform apply -var image_tag=<previous-sha>
```

### View logs

Cloud Run captures stdout, and `RACK_ENV=production` puts `semantic_logger` into JSON mode (see the Logging section below):

```sh
# Tail live.
gcloud logging tail \
  'resource.type=cloud_run_revision AND resource.labels.service_name=bandstand-api'

# Or pull the last 20 entries as JSON.
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=bandstand-api' \
  --limit 20 --format=json
```

## Logging

The Sinatra API uses [`semantic_logger`](https://github.com/reidmorrison/semantic_logger) plus a custom Rack middleware ([`apps/sinatra-api/lib/middleware/request_logger.rb`](apps/sinatra-api/lib/middleware/request_logger.rb)) to emit one structured log line per request. Logs are written to stdout, which Docker (and Cloud Logging when running on GCP) captures automatically.

### What gets logged

- **One line per request** with `method`, `path`, `status`, `duration_ms`, `remote_ip`, `user_agent`, tagged with a `request_id`.
- **Error events** from the controller error handlers (`Sequel::NoMatchingRow`, `Sequel::ValidationFailed`, `JSON::ParserError`, and a `StandardError` catch-all that maps to a JSON 500). Each carries the exception class, message, and backtrace.
- **Sequel SQL queries** when `LOG_LEVEL=debug`, tagged with the same `request_id` as the parent request so you can trace every query a request issued.

### Format

| `RACK_ENV`    | Format                  | When to use                          |
| ------------- | ----------------------- | ------------------------------------ |
| `development` | Colorized text          | Local dev — easier to scan by eye    |
| `production`  | Newline-delimited JSON  | Cloud Run / log aggregators / `jq`   |

The format switch lives in [apps/sinatra-api/lib/logger.rb](apps/sinatra-api/lib/logger.rb).

### Environment variables

- `LOG_LEVEL` — `trace`, `debug`, `info` (default), `warn`, `error`, `fatal`. Set to `debug` to surface Sequel SQL.
- `RACK_ENV` — `development` (default in compose) or `production` (selects JSON formatter).

### Request correlation

Every response carries an `X-Request-Id` header. The middleware honors an inbound `X-Request-Id` if the client sends one (useful for tracing a request across services); otherwise it generates a UUID. All log lines emitted while handling that request — request line, error log, SQL queries — are tagged with the same id.

```sh
curl -i -H 'X-Request-Id: trace-abc' http://localhost:4567/companies/1
# every log line for this call is tagged: request_id=trace-abc
```

### Reading logs in production

Each line is a self-contained JSON object — pipe through `jq`:

```sh
docker compose logs api | jq -c 'select(.name == "Request") | {request_id: .named_tags.request_id, method: .payload.method, path: .payload.path, status: .payload.status, ms: .payload.duration_ms}'
```

## Useful Links

Learn more about the power of Turborepo:

- [Tasks](https://turborepo.dev/docs/crafting-your-repository/running-tasks)
- [Caching](https://turborepo.dev/docs/crafting-your-repository/caching)
- [Remote Caching](https://turborepo.dev/docs/core-concepts/remote-caching)
- [Filtering](https://turborepo.dev/docs/crafting-your-repository/running-tasks#using-filters)
- [Configuration Options](https://turborepo.dev/docs/reference/configuration)
- [CLI Usage](https://turborepo.dev/docs/reference/command-line-reference)
