# Hold (OfficeHours)

Campus office-hours board. TAs post twenty-minute slots. Students hold one, read any private note the TA left, cancel if they cannot make it, or pass the slot to a classmate.

Flask, Jinja, and SQLite.

## Features

- Register with a `.edu` email, sign in, sign out
- Public board of upcoming slots
- Students hold an open slot
- Booking detail, including a private TA note when there is one
- Cancel a hold or transfer it by email
- TAs post new slots and see who booked
- Device handoff link on "My bookings" so you can open the same session on another browser

## Run locally

Python 3.11+.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Open [http://localhost:3000](http://localhost:3000). The database is created and seeded on first request at `data/officehours.db`.

```bash
python seed.py
```

## Run with Docker

```bash
docker compose up --build
```

The app listens on port 3000. Data lives in the `hold-data` volume.

## Deploy (any host)

The repo is host-agnostic — build the `Dockerfile` (or run `gunicorn app:app`) on any platform
(Render, Fly.io, Railway, a VM, etc.). Two things to set:

- **`SECRET_KEY`** — set a real, random secret in the host's environment. It is intentionally not
  baked into the image.
- **Serve over HTTPS.** The session cookie is marked `Secure` automatically when the request arrives
  over HTTPS (detected via `X-Forwarded-Proto`, which managed hosts set), so a browser only sends it
  on encrypted connections.

Other notes: the app reads `$PORT` at startup (most hosts inject it); `GET /health` returns
`{"ok": true}` for health checks; the SQLite file lives at `data/officehours.db`, so mount a
persistent volume there if you want bookings to survive restarts.

## Demo accounts

| Email | Password | Role |
|---|---|---|
| `lea@campus.edu` | `campus123` | student (already holds two slots) |
| `nico@campus.edu` | `campus123` | student |
| `ravi@campus.edu` | `ta-office` | TA |

New registrations are student accounts.

## Project layout

```
app.py                 Routes, sessions, booking flow
db.py                  SQLite schema
seed.py                First-run demo data
templates/             Jinja pages
static/css/style.css
```

## Assignment notes

Host this somewhere your classmates and instructor can reach. Walk the running app until you can explain:

- how a login becomes a cookie the browser sends back
- the difference between the public board and a booking detail
- which actions change server state (book, cancel, transfer, logout)
- what the device-handoff link on My bookings is doing

Then look for a security defect in the running system, document how to trigger it, and patch it without breaking normal booking. Submit the hosted URL, a short architecture sketch, the writeup, and the patched repo.
