# BALAJI ELECTRIC REPAIR AND SERVICES

English, mobile-first service desk for **Shop No 2, Juhu Road, Andheri**. Phones: **+91 70219 35696 / +91 97699 72070**.

## Important delivery status

This is a source implementation with a working local sample-data path, Supabase migrations and Edge Functions. It is **not a deployed service, a generated APK, or a certified production-ready release**. In the creation environment, external network access was disabled and required dependencies were not cached. Source syntax and core domain assertions were checked; a full `npm install`, strict TypeScript/Vite production build and live Supabase integration/RLS tests must be run after setup. See `docs/QA.md`, `docs/SECURITY.md` and `docs/FEATURE-STATUS.md`.

**Uploading files to GitHub alone does not make the backend work.** Configure Supabase and deploy the frontend separately. Never put a Supabase service-role key in the frontend or GitHub.

## 1. Put this project on GitHub

1. Extract the ZIP on your phone or computer.
2. Create a GitHub repository.
3. Upload the **contents of the `balaji-electric` directory** to the repository root: `package.json`, `src`, `supabase`, `public`, etc. Do not upload the ZIP itself and expect GitHub to build it.
4. Include the hidden `.github`, `.gitignore` and `.env.example` files. GitHub's web upload may not show hidden files; use Git or a Codespace if needed.
5. The included Actions workflow runs dependency installation, tests and the production build. Read the workflow result before deployment.

For browser-based setup, use a GitHub Codespace. For a local computer use Node.js 22+ and Git.

## 2. Try sample data first

```sh
npm install
cp .env.example .env
```

Set `.env` to:

```env
VITE_DEMO_MODE=true
```

Then:

```sh
npm run dev
```

Open the local URL. Choose **Owner demo**, **Staff demo** or **Technician demo**. Demo data is stored only in that browser's localStorage. It is not sent to Supabase. This bypass is intentionally restricted to the build-time `VITE_DEMO_MODE=true` setting. **Never deploy a real business workspace in demo mode.**

The sample set includes 5 customers, 8 complaints, 3 stock items, a bill/payment, a technician, a warranty and a service reminder. Reset it in Settings. Do not send real marketing messages to sample phone numbers.

## 3. Create the live Supabase backend

1. Create a Supabase project and save the project URL and **public publishable/anon key**.
2. In **Authentication → Providers → Email**, disable public signup. Keep email/password sign-in enabled. Disable unused providers.
3. Install the Supabase CLI on your own connected computer or Codespace and log in.
4. Link the project and deploy the migrations:

```sh
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Alternatively, run each SQL file from `supabase/migrations` in numerical order in the SQL editor. Do not run a migration twice.

The migrations create all application tables, separate `user_roles`, RLS policies, private storage buckets, transactional billing/payment/stock functions and Realtime publication.

### Create the first owner (no public signup)

In Supabase **Authentication → Users**, add an email/password user. Copy its UUID. Run in the SQL editor, replacing the placeholder:

```sql
begin;
insert into public.profiles (id, name, mobile)
values ('OWNER_AUTH_UUID', 'Business Owner', '7021935696');
insert into public.user_roles (user_id, role)
values ('OWNER_AUTH_UUID', 'owner');
commit;
```

Never put a role on `profiles`. The role is always stored in `user_roles`. All later staff and technician accounts can be created by the owner in Settings → Users.

### Deploy the Edge Functions

Use the exact deployed website origin, without a trailing slash:

```sh
supabase secrets set APP_ORIGIN=https://YOUR_APP_DOMAIN
supabase functions deploy public-portal --no-verify-jwt
supabase functions deploy manage-user
```

Supabase provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to deployed Edge Functions. They are server-side secrets. The public function checks request types, input, image signatures and rate limits, and only returns redacted tracking information. The user-management function verifies the caller and owner role before using admin APIs.

`public-portal` must be deployed without JWT verification because customers are not signed in. **Never** disable JWT verification for `manage-user`.

### Optional SQL sample data

Run `supabase/seed.sql` only in a test project. Remove sample customers/jobs with `supabase/cleanup-demo.sql` before adding real linked records. If demo rows have real bills or warranties, cleanup intentionally fails rather than cascading away business records. The browser demo needs no SQL seed.

## 4. Connect and build the real app

Set local `.env` or your hosting environment variables:

```env
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_KEY
VITE_DEMO_MODE=false
```

```sh
npm test
npm run build
npm run preview
```

After a successful install, commit the generated `package-lock.json`. Use `npm ci` in CI after that. Before release, run dependency/security audits and review any findings; package versions supplied here were not audited against live advisories.

## 5. Deploy from GitHub

### Vercel

Import the repository, choose the Vite framework, use build command `npm run build` and output directory `dist`. Add the three `VITE_*` variables above. `vercel.json` contains SPA rewrites.

### Netlify

Use build command `npm run build`, publish directory `dist`, and the same environment variables. `public/_redirects` provides SPA route fallback.

Update Supabase **Authentication → URL configuration** with the website URL and allowed redirect URLs. Set `APP_ORIGIN` to that same origin and redeploy functions after changing domains. Test `/complaint`, `/track` and a direct `/jobs/:id` URL.

Customer complaint link: `https://YOUR_APP_DOMAIN/complaint`.

## 6. Android / Capacitor later

```sh
npm run build
npm run android:init   # once
npm run android:sync
npx cap open android
```

Install Android Studio and its SDK, configure the package/app name in `capacitor.config.ts`, then build and sign an Android release. **The ZIP does not contain an APK or signing key.** Use the same Supabase variables at frontend build time. Check native WhatsApp/SMS opening, camera/gallery permissions, system back navigation, keyboard layout, file downloads and printing on a real Android device before release. CORS supports Capacitor origins; install/native-function interactions still require device testing.

## Main modules

- Public complaint form, private photo uploads, redacted tracking and token feedback.
- Email/password authentication; owner/staff/assigned-technician role boundaries.
- Dashboard, complaint entry, technician assignment, status timeline and before/after photos.
- Customer directory, CSV import/export, profiles, past jobs/bills/payments.
- Transactional invoices, partial payments, dues reminders, downloadable PDF and private signed PDF sharing links.
- Warranty, service reminders, AMC visit counts, inventory movements and technician overview.
- Consent-filtered manual WhatsApp/SMS queue, editable templates and campaign history.
- Owner reports, expenses, exports, business settings, team creation/disable/roles and data export.
- PWA app-shell caching, responsive sidebar/bottom tabs and Capacitor configuration.

## Folder guide

```text
src/components/ui/       shadcn-style Button and Radix Dialog primitives
src/components/          shared forms, list, navigation and share-link UI
src/hooks/               auth, data loading, demo mutations and Realtime
src/lib/                 Supabase client, application types, billing and exports
src/pages/               route screens
supabase/migrations/     database schema, RLS and transactional RPCs
supabase/functions/      verified server-side public/user workflows
supabase/seed.sql         optional disposable SQL sample rows
docs/                    feature status, testing and security requirements
public/                  icons and SPA redirect configuration
.github/workflows/       build validation
```

The schema uses a single business/workspace, not multi-tenancy. Data loading is paginated but fetched into memory; add server-side filtered queries and pagination before very large customer/job volumes.
