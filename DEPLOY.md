# Deploying coordination.tools

Production runs on a single DigitalOcean Droplet, deployed with
[Kamal](https://kamal-deploy.org). The Droplet hosts three containers:

- **web** — the Rails app (built from `Dockerfile`, served by Thruster behind
  kamal-proxy, which handles Let's Encrypt TLS)
- **coordination-tools-db** — Postgres 17, data persisted in a host volume
- **coordination-tools-db-backup** — nightly `pg_dump` of the primary database
  to DigitalOcean Spaces (`config/backup.sh`)

Deploys are manual: nothing ships until you run `kamal deploy` from your
laptop.

## One-time setup

### 1. Install Kamal locally

```sh
gem install kamal
```

Kamal builds the image locally (Docker Desktop must be running) and talks to
the Droplet over SSH. Load your SSH key into the agent first so Kamal can
authenticate — you'll type your passphrase once per session:

```sh
ssh-add ~/.ssh/id_ed25519   # or whichever key the Droplet trusts
```

### 2. DigitalOcean resources

`script/provision` creates everything reproducibly: registers your SSH key,
creates the Droplet (Ubuntu 24.04, 2 GB — Postgres, Rails, and the backup
container together are tight on 1 GB), the DNS zone + A record, a Spaces
access key, and the backup bucket. It's idempotent — re-running skips
whatever already exists.

```sh
brew install doctl
doctl auth init      # API token from cloud.digitalocean.com/account/api/tokens
script/provision     # see the script header for overridable env vars
```

It prints the Spaces key pair at the end — copy it into `.kamal/secrets`
immediately; the secret can't be retrieved again later.

**Nameserver delegation (one-time, manual):** DNS records live in
DigitalOcean's zone, so the domain registrar must point at DO's
nameservers (`ns1.digitalocean.com`, `ns2.digitalocean.com`,
`ns3.digitalocean.com`). The script warns until this is done. DNS must
resolve to the Droplet before the first deploy — kamal-proxy needs it to
obtain the TLS certificate.

### 3. Container registry (GHCR)

Release images are built by CI: pushing a `v*` tag triggers
`.github/workflows/docker-publish.yml`, which pushes to
`ghcr.io/ibis-coordination/coordination-tools` using the workflow's own
`GITHUB_TOKEN`.

You still need a personal access token (classic) locally so Kamal can log
the Droplet into ghcr.io: `read:packages` suffices for `kamal ship`
deploys; add `write:packages` only if you want local build+push deploys
(`kamal setup` / `kamal deploy`).

### 4. Resend

1. Add and verify the `coordination.tools` domain in Resend (it gives you
   SPF/DKIM DNS records to add).
2. Create an API key. Mail sends from `no-reply@coordination.tools`
   (`app/mailers/application_mailer.rb`).

### 5. Fill in config

1. `config/deploy.yml` needs no editing: servers are addressed by the
   `coordination.tools` hostname (DNS just has to be pointing at the
   Droplet — step 2 above), and everything else lives in secrets.
2. Create the secrets file and fill in real values, including the Spaces
   bucket name and endpoint:

   ```sh
   cp .kamal/secrets.example .kamal/secrets
   ```

   `.kamal/secrets` is gitignored. Generate the database password with
   something like `openssl rand -hex 24` — it's only ever used
   container-to-container.

### 6. First deploy

```sh
kamal setup
```

This installs Docker on the Droplet, starts the Postgres and backup
accessories, builds and pushes the app image, and boots the app. On boot,
`bin/docker-entrypoint` runs `db:prepare`, which creates all four databases
(primary, cache, queue, cable) and loads their schemas.

Verify:

```sh
kamal app logs                 # app booted cleanly
curl -I https://coordination.tools/up   # 200 once DNS + TLS are live
kamal accessory logs db-backup # first dump uploaded to Spaces
```

## Releases and everyday deploys

Normal deploys don't build locally — CI builds the image when you push a
version tag, and `kamal ship` tells the Droplet to pull and swap it:

```sh
# 1. Bump VERSION, update CHANGELOG.md, commit.
# 2. Tag and push (the tag push triggers the image build):
git tag v0.2.0 && git push origin main --tags
# 3. Once the Actions build is green:
kamal ship --version=0.2.0    # note: no `v` prefix — docker convention
```

`kamal ship` is an alias for `deploy --skip-push`; the image must already
exist in ghcr.io. CI-built images carry the `service=coordination-tools`
label Kamal requires — without it Kamal refuses to manage the container
(learned the hard way on collectiveplayer.games).

```sh
kamal deploy      # local build+push of git HEAD (needs write:packages PAT)
kamal console     # rails console on the server
kamal logs        # tail app logs
kamal shell       # bash in the app container
kamal dbc         # rails dbconsole (psql)
kamal rollback    # list/return to a previous version
```

## Backups

`config/backup.sh` runs inside the `db-backup` accessory: it dumps the
primary database on container start and then every 24 hours, uploads
`coordination_tools_production_<timestamp>.sql.gz` to
`s3://<bucket>/postgres/`, and prunes to the newest 14 dumps. The
cache/queue/cable databases are not backed up — they're recreated by
`db:prepare`.

After changing backup settings: `kamal accessory reboot db-backup`.

### Restore

```sh
# Download the dump you want from Spaces, then:
scp coordination_tools_production_<stamp>.sql.gz root@<droplet-ip>:
ssh root@<droplet-ip> \
  'gunzip -c coordination_tools_production_<stamp>.sql.gz |
   docker exec -i coordination-tools-db psql -U coordination_tools -d coordination_tools_production'
```

For a restore into a fresh database (e.g. after `DROP DATABASE`), create it
first with `docker exec -i coordination-tools-db createdb -U coordination_tools coordination_tools_production`.

## Notes

- `config/master.key` never leaves your laptop except as the
  `RAILS_MASTER_KEY` env var Kamal injects at run time; it is excluded from
  the image by `.dockerignore`.
- Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA`), so there's no
  separate job container. If a future tool needs heavy background work,
  split it into a `job` role in `config/deploy.yml`.
- To serve additional hostnames later, add them under `proxy.host` in
  `config/deploy.yml` and to `config.hosts` in
  `config/environments/production.rb`.
