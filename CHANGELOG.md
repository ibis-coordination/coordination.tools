# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-08-04

Branding and dark mode.

### Added

- **Logo and favicon**: the Ibis Coordination octagram (rotated 22.5° so
  one point faces up) replaces the default Rails icon and appears in the
  header next to the wordmark. The SVG favicon inverts automatically in
  dark mode.
- **Automatic dark mode**: the site follows the OS color scheme. Every
  color in the stylesheet goes through `:root` custom properties, with a
  `prefers-color-scheme: dark` block overriding the palette; native form
  controls and scrollbars adapt via `color-scheme`.
- The footer credits **Ibis Coordination** with a link to
  ibis-coordination.com.

## [0.2.0] - 2026-08-04

A UX and safety pass driven by a full friction review (see
`docs/ux-friction.md`) and a safety review of the coordination
mechanics; every change was built test-first.

### Added

- **Your carpools** on the homepage: the carpools you organize, drive in,
  or ride in, upcoming first with past ones collapsed.
- Owners can **delete a carpool** from the edit page.
- **Email change** on the account page, confirmed via a link sent to the
  new address (`users.pending_email`).
- Drivers can **offer a seat** to a ride request; the rider is emailed
  and chooses to accept or decline — nothing is booked until they
  accept, and a declined offer can't be repeated. (Replaces an earlier
  direct-pickup design that seated riders without their consent.)
- Drivers can **remove a passenger** from their ride; the passenger is
  moved back to ride requests and emailed.
- **Organizer moderation**: the carpool owner can remove any ride or
  claim from their event; those affected are emailed.
- Displaced passengers are **emailed** when a driver's ride is removed.
- Signed-out visitors can **create a carpool in one step** — name/email
  fields are part of the form; existing emails finish via magic link.

### Changed

- **Minimal forms**: only trip name, your name/email, and seat counts
  are required (seats default to 1). Everything else — destination
  address, times, locations, notes — is optional inside a collapsed
  "Add more details" section, with required fields marked `*` and
  grouped first. Blank values degrade to "TBD" / "not specified".
- **Least-privilege visibility**: contact emails are shown only to
  yourself, the organizer, and the people you ride with; pickup
  addresses only to the driver and that passenger (the claim form says
  so).
- **Repost consent**: leaving a ride yourself no longer posts a request
  in your name; automatic reposts after removal or cancellation no
  longer republish the pickup address.
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
- Seats labels follow the selected role; the header shows your name;
  departure times on a different day include the date; typography uses
  a four-step type scale.

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
