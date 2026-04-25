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
