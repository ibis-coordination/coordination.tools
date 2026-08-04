# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

A UX pass driven by a full friction review (see `docs/ux-friction.md`);
every change below was built test-first against a documented friction point.

### Added

- **Your carpools** on the homepage: the carpools you organize, drive in,
  or ride in, upcoming first with past ones collapsed.
- Owners can **delete a carpool** from the edit page.
- **Email change** on the account page, confirmed via a link sent to the
  new address (`users.pending_email`).
- Drivers can **pick up ride requests** directly; the rider is seated,
  their request removed, and they get an email.
- Displaced passengers are **emailed** when a driver cancels a ride.
- Signed-out visitors can **create a carpool in one step** — name/email
  fields are part of the form; existing emails finish via magic link.

### Changed

- Flash messages render in the layout, so notices are no longer dropped
  on pages without a local flash block.
- Sign-in is **email-first**: existing accounts get a sign-in link, new
  emails are asked for a name (with a disclosure that name and email are
  visible to participants).
- Magic-link emails are sent asynchronously and carry the return path in
  the link, so opening the link on another device lands on the right page.
- The carpool board has **per-direction join forms**; role/direction
  choices survive the sign-in detour; claim forms are inline, prefilled
  from your request or current claim, and refresh-safe; users with an
  entry see their status instead of a duplicate form; failed posts show
  their error at the top of the page.
- Leaving a ride explains the ride request posted on your behalf (and
  the confirm dialog warns first).
- Seats labels follow the selected role; the header shows your name;
  departure times on a different day include the date.

## [0.1.0] - 2026-08-04

Initial release: the **coordination.tools** suite with one tool.

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
