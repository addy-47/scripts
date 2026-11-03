# Auth and headless login

There are two independent credentials. Do not mix them up.

| Purpose | Credential | Refresh method |
|---|---|---|
| BigQuery | ADC | `gcloud auth application-default login` |
| Data Studio reports | Chrome profile | `looker-studio-mcp login` |

## 1. ADC (BigQuery)

Current ADC works. To refresh it on a headless server, use the gcloud remote
bootstrap flow.

**On the server:**

```bash
gcloud auth application-default login --no-browser
```

gcloud prints a long command that starts with:

```bash
gcloud auth application-default login --remote-bootstrap="..."
```

**On your laptop:** copy and run that whole command. A browser opens locally.
Finish the sign-in. It prints a long URL.

**Back on the server:** paste that URL at the `Enter the output of the above
command` prompt.

This is the flag you were thinking of: `--no-browser` plus the generated
`--remote-bootstrap="..."` command. It works for both `gcloud auth login` and
`gcloud auth application-default login`.

Verify:

```bash
gcloud auth application-default print-access-token >/dev/null && echo ADC_OK
```

## 2. Data Studio Chrome profile

The MCP `login` command has **no remote flag**. It spawns a real Chrome on the
machine where it runs. On a headless server, choose one of these.

### Option A — SSH X11 forwarding (recommended for this test)

Requires Google Chrome on the server and an X server on your laptop.

1. Install Chrome on the server (Ubuntu):

   ```bash
   wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
   sudo apt-get install -y /tmp/chrome.deb
   ```

2. Connect from your laptop with X11 forwarding:

   ```bash
   ssh -X -Y user@server
   ```

   On macOS, install XQuartz first. On Windows, use VcXsrv or WSLg.

3. On the server, run the login:

   ```bash
   export PATH="/opt/sandobx/looker-agent-feasibility/tools/node20/bin:$PATH"
   cd /opt/sandobx/looker-agent-feasibility/mcp/looker-studio-mcp
   node build/cli/main.js login --config ../../config/config.yaml
   ```

   A Chrome window opens **on your laptop**. Sign in with a Google account that
   has edit access to Data Studio. Open Data Studio once. Close Chrome
   completely.

4. Verify:

   ```bash
   node build/cli/main.js auth --config ../../config/config.yaml
   ```

   After this one-time step, the agent can run headless. The profile lives at
   `profiles/chrome/` in this project.

### Option B — VNC on the server

If X11 forwarding is slow or blocked, run Xvfb plus x11vnc and connect with a
VNC viewer. Same login command. More setup, same result.

### Option C — run the MCP on your laptop

For a pure feasibility test this is the simplest path. Run the MCP where Chrome
already exists. Use the server only for code and docs. The report tools then
have no remote-login problem at all.

### Option D — copy a Chrome profile (not recommended)

Chrome cookies are tied to the OS keychain. The MCP deliberately disables
`--use-mock-keychain` and `--password-store=basic` to keep cookies valid. A
profile copied from another machine often cannot decrypt them. Avoid.

### Option E — reuse an existing Chrome session over CDP (workaround, not a fix)

If a one-time login is unacceptable, run Chrome where it is already signed in
and let Playwright attach to it:

1. Start Chrome with remote debugging:
   `google-chrome --remote-debugging-port=9222`
2. Make that port reachable from the server, for example with a reverse SSH
   tunnel: `ssh -R 9222:localhost:9222 user@server`.
3. Teach the MCP to attach with `chromium.connectOverCDP("http://localhost:9222")`
   instead of launching a persistent profile.

Caveats:

- The browser must stay open. The agent controls your live session.
- The user's browsing can interfere with automation.
- Google may still treat the session as automated.
- This is a code change to the vendored MCP (~50–100 LOC), not a config flag.
- It still does **not** use ADC. It reuses a browser session; it does not remove
  the need for one.

Use this only if X11/VNC is painful. For the feasibility test, the one-time
login is simpler and within the "one manual intervention" criterion.

## Why ADC cannot replace the Chrome login

Tested on 2026-11-02:

| Probe | Result |
|---|---|
| `GET https://lookerstudio.google.com/navigation/reporting` with `Authorization: Bearer <ADC token>` | **Byte-identical HTML** to the same request without the header. The Bearer token is ignored. |
| `GET https://datastudio.googleapis.com/v1/assets:search` with the ADC token | `403`, first for a missing quota project, then for the API being disabled in `h4-internal` |
| ADC token scopes | `openid`, `email`, `cloud-platform`, `sqlservice.login`, `userinfo.email` — **no `datastudio` scope** |

The Data Studio web app authenticates with browser **session cookies**, not with
an OAuth Bearer token. ADC is a Google Cloud API credential. Even if the Data
Studio API were enabled, it exposes only `assets:search` and permission
methods; there is no create-report method.

**Conclusion:** the separate `login` is not a gap in the MCP repo. It is the
only supported way to obtain an authenticated editor session. ADC is already
used correctly for BigQuery.

## 3. Security

- `profiles/chrome/` contains a live Google session. Keep it out of git. It is
  already in `.gitignore`.
- Restrict it: `chmod 700 profiles/chrome`.
- Never print ADC tokens or copy the profile to a shared location.
- The audit log is at `~/.looker-studio-mcp/audit.ndjson`.

## 4. Verification record

- **2026-11-02:** SSH X11 forwarding used. Google Chrome at
  `/opt/google/chrome/chrome`. Profile at `profiles/chrome/`, `chmod 700`.
  `auth` reports both credentials OK, and `list_reports` runs headless and
  returns "No reports yet." One-time login is proven.

## 5. Order of operations

1. ADC works → BigQuery smoke test.
2. Chrome installed → one-time login via X11 or VNC.
3. `auth` passes → report tools usable headless.
