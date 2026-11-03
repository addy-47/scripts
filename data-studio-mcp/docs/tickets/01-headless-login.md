# 01: Prove a one-time Chrome login and headless reuse

**Type:** spike

**What to build:** Answer one question: can we sign a persistent Chrome profile
into Data Studio once on this headless server (or an approved alternative), then
reuse it headlessly for every later report tool call?

**Layer:** environment / authentication

**Blocked by:** None (can start immediately)

**Non-goals:** Building any report, installing another BI tool, changing ADC,
production auth design.

**Note:** ADC cannot replace this login. The Data Studio web app ignores Bearer
tokens and has no create API. If a one-time login is unacceptable, evaluate the
CDP session-reuse option in `docs/auth-and-headless.md`, but do not block this
ticket on it.

**Invariants touched:** Free Data Studio only; at most one manual intervention;
no cloud resources.

**Verify:** `auth` reports signed in, then `list_reports` returns a list (empty
is fine) with no visible browser window.

**Status:** done (2026-11-02)

- [x] Choose a login path: **SSH X11 forwarding**. Recorded in `docs/auth-and-headless.md`.
- [x] Make Google Chrome available: `/opt/google/chrome/chrome`.
- [x] Sign in once with a Google account that has Data Studio edit access.
- [x] Store the profile at `profiles/chrome/` with `chmod 700`.
- [x] Set `headless: true` and prove `auth` passes.
- [x] Prove `list_reports` works headlessly: returns "No reports yet."
- [x] Record commands and the verification result in `docs/auth-and-headless.md`.

**Exit:** Finding recorded. `auth` reports both credentials OK, and
`list_reports` runs headless with no visible browser.

**Verified result (2026-11-02):**

```
✔ Google APIs: token OK (adhbhut.gupta@hypr4.io)
✔ Looker Studio: browser profile signed in
list_reports -> No reports yet.
```
