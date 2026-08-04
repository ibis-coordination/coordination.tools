# UX friction review

A walkthrough of every user-facing flow as of v0.1.0, listing friction points,
confusing mechanisms, and counterintuitive behavior. Ordered roughly by flow;
severity tags are a judgment call: **[high]** actively loses users or data,
**[medium]** causes confusion or rework, **[low]** polish.

> **Status (2026-08-04):** all 31 items were addressed test-first in the
> commit series following this review (each commit message cites the item
> numbers it fixes). Two partial resolutions to know about: #3 keeps the
> naive "event-local time" convention but now states it and dates
> off-day departures, and #19 was solved by giving each direction section
> its own join form rather than by inlining forms into the columns.

## Cross-cutting mechanisms

1. **[high] Flash messages are silently dropped on most pages.** The layout
   does not render `notice`/`alert`; only `carpools/show`, `sessions/new`, and
   `accounts/edit` render them locally. Consequences today:
   - "Signed out." redirects to the homepage → never shown.
   - "Signed in as …" after sign-up with no `return_to` lands on the homepage
     → never shown.
   - Any future redirect-with-flash to an uncovered page vanishes.
   Fix direction: render flash once in the layout, delete the per-view copies.

2. **[high] Magic-link email is sent inline with `deliver_now`.** The signup
   request blocks on SMTP (up to 10s open + 10s read timeout), and because
   `raise_delivery_errors = true`, a Resend hiccup turns "send me a link" into
   a bare 500 page with no guidance. This exact path already 500'd once in
   production. Fix direction: `deliver_later` (Solid Queue is already running
   in Puma) and/or rescue with a friendly "we couldn't send the email" retry
   page.

3. **[medium] No timezone handling anywhere.** No `config.time_zone`, and all
   times are naive: `datetime_local_field` in, `strftime` out. Consistent as
   long as everyone assumes "event local time", but nothing says so, and a
   carpool for an event in another timezone is ambiguous. Departure times also
   render time-only (`3:00 PM`) with no date, which misleads for return trips
   on a different day.

4. **[medium] Live refreshes can eat in-progress form input.** The board uses
   `turbo_stream_from` + `broadcast_refresh_to`, so any change by anyone
   reloads the page for everyone viewing it. A user mid-typing in the join
   panel or claim form can have their input wiped by someone else's update.
   Needs `data-turbo-permanent` on the forms (or morph-safe handling).

## Sign-in / sign-up

5. **[high] Returning users must fill in a "Name" field that is then thrown
   away.** The sign-in form requires name + email for everyone. If the email
   already exists, the typed name is silently discarded and a magic link is
   sent. A returning user who typed a *different* name reasonably expects a
   rename; nothing happens. Fix direction: email-first flow (ask for name only
   when the email is new), or at least mark name as "only used for new
   accounts".

6. **[high] The magic link usually opens in the wrong browser context.** Users
   commonly read email on their phone or in a different browser. The link
   signs in *that* browser; `session[:return_to]` lives in the original
   browser's session, so the new context lands on the homepage (where, per #1,
   the "Signed in as …" notice isn't even rendered), and the original tab
   stays signed out with no feedback. Classic magic-link friction — worth at
   least copy that sets expectations ("open this on the device you want to use"),
   or embedding the destination in the link/token instead of the session.

7. **[medium] A typo'd email creates a real account instantly.** New emails
   sign in with zero verification, so `dan@gmial.com` becomes a live identity
   whose (wrong) address is displayed to other carpool participants as the
   contact. There's no way to notice or fix it — no email change (see #12), so
   the user's only recourse is signing up again, orphaning the first entry.

8. **[low] The page is titled "Sign in" but is really sign-in *and*
   sign-up.** The explanatory paragraph does a lot of work ("New emails are
   signed in right away…") and reads as slightly alarming/confusing —
   creating an account is a side effect of a form labeled Sign in.

9. **[low] The success notice reveals account existence.** "That email already
   has an account" is an enumeration oracle and also wordier than needed;
   "Check your email for a sign-in link" covers both cases.

## Account page

10. **[medium] "Email me a sign-in link" from the account page dumps you into
    a nonsensical state.** A signed-in-but-unconfirmed user clicks the button
    to confirm their email; they are redirected to the *sign-in page* (while
    already signed in) with the notice "That email already has an account. We
    sent a sign-in link…" — a message written for a different flow. The
    account page should send the link and keep them there with "check your
    email to confirm".

11. **[medium] Name editing gated on email confirmation is unexplained.** The
    account page says "To edit your name, first confirm your email address" but
    never says *why* (anti-impersonation of an existing address). To a user it
    reads as arbitrary bureaucracy in an otherwise frictionless app.

12. **[medium] No way to change your email address, ever.** Combined with #7,
    a typo is permanent.

13. **[low] The header nav shows your raw email as the account link.** Long
    emails crowd the mobile header, and name would be friendlier once names
    are trustworthy.

## Finding your stuff

14. **[high] Lose the link, lose the carpool.** There is no "my carpools" list
    anywhere — not on the homepage for signed-in users, not on the account
    page. Creators and participants who lose the URL have no way back, even
    though the app knows exactly which carpools they own, posted rides in, or
    claimed seats in. This undermines the share-a-link model, since the link is
    a single point of failure.

15. **[medium] There is no way to delete (or cancel) a carpool.** Routes stop
    at create/show/edit/update. An organizer whose event is canceled can only
    edit the title to say "CANCELED".

## Creating a carpool

16. **[medium] Sign-up interstitial before you ever see the create form.**
    Clicking "Create a carpool" bounces to the sign-in page ("Enter your name
    and email to continue.") before showing the form. Given the stated
    frictionless-participation philosophy, consider letting people fill out the
    carpool form first and asking for name/email as the final step of the same
    form (or at submit time), so the reward is visible before the toll.

17. **[low] Nothing tells you your email will be publicly visible.** Contact
    emails are shown on ride cards to anyone signed in — and sign-in is
    effectively open (any name + unverified email). Nowhere in sign-up or
    posting a ride is the user told "your email will be visible to other
    participants." Trust/consent gap rather than a mechanism bug.

## The carpool board

18. **[high] The direction/role you click is lost through the sign-in
    detour.** A signed-out visitor clicks "I can drive" on the *return trip*
    section → anchor-jump to the join panel → "Sign in to continue" →
    `return_to` is the bare carpool path *without* the `role`/`direction`
    params → after sign-in they land back at the top of the board with the
    default form (driver/outbound) and must find and re-click the button.
    Two layers of friction: the choice is discarded, and the scroll position
    is lost.

19. **[medium] One shared join form at the bottom serves both direction
    sections.** "I can drive" / "I need a ride" buttons in each direction
    section jump to a single panel at the page bottom. The panel's heading does
    name the direction, but the spatial disconnect (click in the "Return trip"
    section, land on a form far below both sections) makes it easy to post to
    the wrong direction — especially since flipping the role radio there
    doesn't re-confirm direction. In-place forms per section (or a form that
    visibly belongs to a section) would be more intuitive.

20. **[medium] The role toggle changes the meaning of fields without changing
    their labels.** In the join form, "Number of seats" means seats *offered*
    for a driver and seats *needed* for a rider; "Starting location" quietly
    becomes "where to pick me up". The labels are computed server-side from
    direction only, so toggling the radio updates nothing. Same in ride edit.

21. **[medium] The join form is always shown even when you can't post.**
    A user who already has an entry in that direction still sees the full
    "Offer a ride" form; submitting yields the validation error "user already
    has an entry for this direction". The board should instead show "You
    already have an entry — edit it" with a link.

22. **[medium] Ride-create validation errors render at the bottom of a full
    board re-render.** On failure the controller re-renders `carpools/show`;
    the browser shows the top of the board and the error box is way down in
    the join panel, easy to miss entirely.

23. **[medium] "Join this ride" is a full page reload to reveal a form.** The
    claim form appears via `?join_ride=ID` + anchor — a server round-trip and
    scroll jump just to show two fields. Same pattern for "Switch to this
    ride". Feels clunky next to the live-updating board; a Turbo frame or
    details-toggle would keep context.

24. **[medium] Joining a ride ignores the info in your existing ride
    request.** If you posted a rider entry ("The Mission", 2 seats) and then
    click "Join" on a driver's ride, the claim form pre-fills only from a
    *previous claim* — your rider entry's location and seat count are ignored
    and you re-type them, even though the app then deletes that rider entry
    for you.

25. **[medium] Leaving a ride silently posts a public ride request in your
    name.** Leaving a claim auto-creates a rider entry noted "Previously
    assigned to a ride." Well-intentioned (don't lose displaced people), but
    surprising: someone who leaves because they're *no longer going* is now
    publicly requesting a ride and must notice and delete that entry too. Same
    mechanism when a driver cancels (note: "The previous ride was canceled.").
    At minimum the flash should say what happened ("we added a ride request
    for you — remove it if you no longer need a ride"); better, ask.

26. **[medium] Displaced passengers are only informed if they happen to be
    looking.** When a driver removes their ride, passengers are moved to ride
    requests with no email notification; the realtime refresh only helps
    people with the page open. Days-later passengers may believe they still
    have a seat.

27. **[medium] Drivers can't do anything with ride requests.** The board shows
    requests, but matching is one-directional: only riders can claim seats.
    A driver who sees a request can't invite or accept the rider — they must
    email them out-of-band and hope the rider comes back to click "Join". The
    two-column layout implies matching that the mechanics don't support.

28. **[low] "Updates appear automatically." is repeated in every section's
    action row.** Odd placement (inline with buttons) and duplicated per
    direction; belongs once, subtly, if at all.

29. **[low] Empty board gives the creator no next step.** A fresh carpool
    shows two "No rides…" empty states and the join form. The one-time flash
    says "ready to share", but after that nothing on the page nudges the
    organizer to copy the link or post the first ride.

30. **[low] "Copy link" gives no fallback if the clipboard API fails.** No
    visible URL text to select manually (matters in odd browsers/webviews);
    the button just silently does nothing if `navigator.clipboard` rejects.

31. **[low] Seat totals in column headers are ambiguous.** "Available rides —
    3 seats" (sum across all drivers) next to "Ride requests — 2 seats" reads
    like a matched pair but counts different things; fine once you get it,
    puzzling the first time.

## Suggested priority order

If tackling top-down by user impact:

1. Flash in layout (#1) — small fix, removes several invisible-feedback bugs.
2. "My carpools" on homepage/account (#14) — biggest single retention gap.
3. Async magic-link delivery + graceful failure (#2).
4. Email-first sign-in flow (#5, #8, #9, #10 mostly fall out of this).
5. Preserve role/direction through sign-in (#18) and pre-fill claims from
   existing requests (#24).
6. Per-section join forms or clearer direction affordance (#19, #21, #22).
7. The notification/consent cluster (#25, #26, #17).
