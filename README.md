# Tally — budget with Penny

Split every paycheck into percentage "buckets", track income and expenses, and chat with **Penny**, an AI helper that reads your real numbers and can log things for you.

This is the finished app: sign-up/sign-in, private per-user budgets, Free/Pro plans, Stripe billing, Plaid bank import, an admin dashboard, and Penny (powered by Claude).

## Run it

```bash
npm install
cp .env.example .env      # then fill in what you want (see below)
npm start                 # http://localhost:5000
```

Needs Node 18+. `npm test` runs 150+ end-to-end checks against fake Anthropic/Stripe/Plaid servers (no real keys needed).

The app works with **no keys at all**: accounts, buckets, paycheck splitting, income, expenses and the overview all run. Each extra switches on when you add its keys:

| Feature | Add these | Without them |
|---|---|---|
| Penny + "Penny's take" | `ANTHROPIC_API_KEY` | Pro users see a "Penny isn't switched on yet" message |
| Pro subscriptions | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` | Upgrade button is disabled; you can still grant Pro by hand in Admin |
| Bank import | `PLAID_CLIENT_ID`, `PLAID_SECRET` | "Connect a bank" is disabled |

## Make yourself the admin

Set `ADMIN_EMAIL=you@example.com`, then **sign up in the app with that email**. You get Pro permanently and an **Admin** page (all accounts, plan changes, deletes, rough revenue).

## Stripe setup

1. Put your **secret key** in `STRIPE_SECRET_KEY`. Prices ($11.99/mo, $79.99/yr) are created automatically, or set `STRIPE_PRICE_MONTH` / `STRIPE_PRICE_YEAR` to use your own.
2. Dashboard → Developers → Webhooks → add endpoint `https://YOUR-SITE/api/billing/webhook` with events `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`. Put its signing secret in `STRIPE_WEBHOOK_SECRET`.
3. Turn on the **Customer portal** (Settings → Billing → Customer portal) so "Manage or cancel" works.

Even without the webhook, the app re-checks Stripe when someone returns to the Billing page, but the webhook keeps plans correct when people cancel or a card fails.

## Plaid setup

Create a Plaid account, put the keys in `PLAID_CLIENT_ID` / `PLAID_SECRET`, and leave `PLAID_ENV=sandbox` to test (login `user_good` / `pass_good`). Switch to `production` once Plaid approves you. Bank access tokens are encrypted in the database and never sent to the browser.

## Deploy

Any host that runs Node or Docker works (Render, Railway, Fly.io, a VPS). **The one rule: the database is a file, so mount a persistent disk and point `DATA_DIR` at it**, otherwise data is lost on redeploy. Run **one instance** (SQLite isn't meant for multi-server setups).

```bash
docker build -t tally .
docker run -p 5000:5000 -v tally-data:/data --env-file .env tally
```

Serve it over HTTPS (the hosts above do this for you). Behind a proxy, the app already trusts `X-Forwarded-*`.

## How it's built

- `server/` — Express + SQLite (`better-sqlite3`). Those are the only two dependencies; Stripe, Plaid and Claude are called over plain HTTPS.
- `public/` — the compiled web app (React). Hash-routed, so no special server rules needed.
- Passwords: scrypt. Sessions: random tokens stored hashed, 30 days, kept in an HttpOnly cookie that's exchanged for a Bearer token on page load; all data routes require the Bearer token, so they're CSRF-proof. Sign-in, sign-up and chat are rate-limited.

## Known gaps

- **No "forgot password" or email verification** (needs an email service such as Resend or Postmark). Until then an admin can delete an account so the person can re-register.
- **The frontend source isn't in this folder.** `public/` is the compiled output from the original build, with one patch (the API address). To change the UI itself you'll need the original source project.
- SQLite is fine for hundreds of users on one server. For real scale, move to hosted Postgres (e.g. Supabase); all data access lives in `server/budget.js`, `bank.js`, `penny.js` and `index.js`.
- Penny is a budgeting helper, not a financial advisor. The UI says so; keep it that way.
