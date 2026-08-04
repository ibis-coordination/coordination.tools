# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Initial release candidate: the **coordination.tools** suite with one tool.

### Added

- **Carpool organizer at `/carpool`** — create a carpool page for an event,
  share the link, and let drivers offer seats and riders claim them, per
  direction (to the event / returning). Real-time updates via Turbo Streams.
- **Frictionless participation** — joining requires only a name and email,
  with no confirmation step. Claiming an email that already exists requires
  proving ownership via a magic sign-in link; confirmed users can edit
  their name.
- **Kamal deploy to a DigitalOcean Droplet** — Postgres accessory, nightly
  `pg_dump` to Spaces, Resend SMTP for magic-link email, and
  `script/provision` for reproducible DigitalOcean resource setup.
- **CI-built images on `v*` tags** — GitHub Actions builds and pushes a
  `linux/amd64` image to `ghcr.io/ibis-coordination/coordination-tools`;
  deploys pull it with `kamal ship --version=…` instead of building
  locally.
