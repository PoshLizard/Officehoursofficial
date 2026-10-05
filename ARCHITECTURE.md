# Hold (OfficeHours) — Architecture Sketch

A single Flask process renders server-side Jinja pages and talks to one SQLite file. No JavaScript,
no API layer — every action is a plain HTML form POST that redirects back to a page.

## Request flow

```
            Browser (cookie: hold_session)
                     │  HTTP
                     ▼
        ┌──────────────────────────────┐
        │  Flask app (app.py)          │
        │                              │
        │  before_request:             │   reads hold_session cookie,
        │    load_user() ──────────────┼── joins sessions→users, sets g.user
        │                              │
        │  route handler (view)        │   runs the query, renders a template
        │                              │
        │  after_request:              │   (re)writes hold_session cookie
        │    persist_session_cookie()  │   HttpOnly + SameSite=Lax + Secure(https)
        └───────────────┬──────────────┘
                        │ sqlite3
                        ▼
              data/officehours.db  (users, slots, bookings, sessions, handoff_codes)
```

## Pieces

| File | Responsibility |
|---|---|
| `app.py` | Routes, auth (`load_user` / cookie), booking flow, secure device handoff |
| `db.py` | SQLite connection + schema (`init_db`) |
| `seed.py` | First-run demo data (TA, two students, five slots, two bookings) |
| `templates/` | Jinja server-rendered pages (`base`, `home`, `mine`, `booking`, …) |
| `static/css/style.css` | Styling |
| Dockerfile / docker-compose.yml | Container build; runs `gunicorn app:app` on port 3000 |

## Data model

```
users(id, email UNIQUE, password_hash, display_name, role['student'|'ta'])
slots(id, ta_id→users, starts_at, location, topic)
bookings(id, slot_id→slots UNIQUE, student_id→users, private_note)   # UNIQUE slot_id = one hold per slot
sessions(token PK, user_id→users)                                    # cookie value = this token
handoff_codes(code PK, user_id→users, expires_at, used)              # one-time device-handoff codes
```

## Who can see / do what

- **Anyone:** the board (`GET /`) — time, TA, topic, location, held/open only.
- **Signed-in student:** hold an open slot; view *their own* booking detail (incl. the TA's private
  note); cancel or transfer it; create a one-time device-handoff link.
- **Signed-in TA:** post slots; see who booked their slots.
- **Auth:** session token in an `HttpOnly` cookie, looked up on every request. Never in the URL.

## Routes

| Method | Path | State change? |
|---|---|---|
| GET | `/`, `/me`, `/bookings/<id>`, `/slots/new`, `/health` | read-only |
| GET/POST | `/login`, `/register` | creates session / user |
| POST | `/logout` | deletes session |
| POST | `/slots` | TA posts a slot |
| POST | `/slots/<id>/book` | creates a booking |
| POST | `/bookings/<id>/cancel` | deletes a booking |
| POST | `/bookings/<id>/transfer` | reassigns a booking |
| POST | `/me/handoff` | issues a one-time handoff code |
| GET | `/handoff/<code>` | redeems code → mints a new session |
