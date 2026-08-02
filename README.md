# coordination.tools

`coordination.tools` is a collection of practical tools for solving common coordination problems.

## Run it locally

The app uses Ruby on Rails, PostgreSQL, Stimulus, Turbo, and Action Cable. The easiest local setup is Docker:

```sh
docker compose up --build
```

Then open http://localhost:3100. No user accounts or seed data are required.
To choose another port, run `PORT=3200 docker compose up --build` instead.

## Tools

* Carpool organizer

## Planned tools (not built yet)

* Schedule availability finder
* Potluck planner
* Volunteer board
* Status tracker
* Check-in page
* Subgroup generator
* Queue tracker
* Cointoss and random selectors
* Common connection finder
* Common knowledge establisher
* Group decision maker
* Conditional commitment tracker
* Message deposit box