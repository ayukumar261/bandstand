# Bruno API tests

Bruno collection (`bandstand-api`) that exercises the Sinatra REST API at `http://localhost:4567`. Collection metadata lives in [bruno.json](bruno.json).

## Collection layout

- `health/` — `health.bru`
- `companies/` — `create-company`, `list-companies`, `get-company`, `update-company`, `delete-company`
- `jobs/` — `setup-company`, `create-job`, `list-jobs`, `get-job`, `update-job`, `delete-job`, `teardown-company`. The `setup-company` / `teardown-company` requests bracket the CRUD flow so the `jobs/` tests are self-contained.
- `environments/local.bru` — points the collection at `http://localhost:4567`.

## Prerequisites

- Bruno CLI:
  ```sh
  npm install -g @usebruno/cli
  bru --version
  ```
- The Sinatra API must be running and reachable at `http://localhost:4567`. See the root [README.md](../../../README.md) for how to start it in local or cloud mode.

## Running tests

Run from `apps/sinatra-api/bruno/`:

```sh
bru run --env local                                # run the whole collection
bru run companies --env local                      # run a single folder
bru run health/health.bru --env local              # run a single request
bru run --env local --bail                         # stop on the first failure
bru run --env local --reporter-json results.json   # emit a JSON report (useful in CI)
```

## Environments

`local` is the only environment today ([environments/local.bru](environments/local.bru)). To target a different host (e.g. a deployed API), add a new `.bru` file under `environments/` and select it with `--env <name>`.

## Authoring conventions

- `jobs/setup-company.bru` and `jobs/teardown-company.bru` are named so they sort before/after the CRUD requests and leave the database clean. Follow the same naming pattern when adding new test groups that need fixtures.
- Requests are executed in lexical order within a folder, so prefix dependent requests accordingly.

## CI / automation

Recommended invocation for CI:

```sh
bru run --env local --reporter-json out.json --bail
```

The JSON report is easy to parse from a CI step, and `--bail` prevents cascading failures from a broken fixture request.
