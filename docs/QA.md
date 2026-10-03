# Validation record and acceptance tests

## Executed in the creation environment

- Esbuild syntax parsing of 34 application/server TypeScript files: passed after fixing a feedback-form syntax error. Final source should be rechecked after package changes.
- Nine core domain assertions: tax after discount, service-only totals, rounding, Indian mobile validation, personalized placeholders, WhatsApp encoding and calendar date conversion: passed.
- Required route and 22-table/RLS source audit: passed. This only verifies code coverage, not SQL runtime correctness.
- All 20 screen variants rendered in a local compatibility harness at 390px: no JS exceptions or horizontal document overflow in that harness. Representative dashboard, public form, job list/detail and invoice-entry images were inspected. Full official-library visual acceptance is still pending.
- Dashboard was captured with the artifact validator: no console exceptions, failed resources or horizontal overflow.

## Important test limits

Dependencies were unavailable from the local cache, and outbound network was disabled. No full `npm install`, `tsc`, `vite build`, installed-library integration test, live SQL migration, Supabase RLS test, Edge Function deployment, signed-PDF sharing or Android build was run. The local visual harness used real React and app/demo state, but substituted the router, chart, QR and dialog dependency adapters and generated utility CSS. It is **not** evidence of a successful official production build. The harness is not part of the released app.

## Required acceptance tests (run in a test project)

### Build and routing
- Run `npm install`, `npm test`, `npm run build` and `npm run preview`. Commit the lockfile after success.
- Confirm every URL works after refresh, at 390px and desktop width, with actual Tailwind, Radix, Recharts and Supabase installed.
- Check keyboard focus, screen-reader labels, modal focus/escape, safe areas, minimum 44px action targets, toasts, empty lists, invalid forms, offline errors and loading skeletons.

### Authentication and isolation
- Signup is disabled. Login works only for pre-created users with an active profile and role.
- Anonymous table requests are denied. Staff cannot read expenses, inventory costs, campaigns or user settings through direct REST requests.
- Technician can see/update/photo only their own assigned jobs; direct calls for an unassigned job fail. No billing/customer-directory access.
- Technician update RPC ignores assignment and visit mutations; attempts to update complaints directly are denied.
- Disable an account and re-test both old JWT and a fresh sign-in. Switch accounts while data is loading and verify no stale private data appears.

### Public portal
- Valid form creates one customer/complaint and a unique number; invalid phones and oversized/malformed photos fail with useful English messages.
- Existing customer submissions do not overwrite verified name/address/consent. New submitted identity is captured on that complaint.
- Honeypot and fourth mobile submission in an hour are rejected. IP limiter and concurrency work on the actual gateway.
- Three public photo registrations succeed; the fourth fails even with simultaneous requests. Upload token expires after 30 minutes.
- Tracking with wrong mobile/number fails. Successful tracking returns no identity, notes, photos or technician personal data.
- Public feedback accepts one rating only for a completed job and the correct unpredictable token.

### Complaints and customers
- Phone lookup, filters, urgent priority, assignment, status history, before/after photos, phone links, Maps and WhatsApp update links work.
- An authenticated client receives a new complaint event, toast and badge. Sound works only after user activation.
- CSV imports distinguish valid/invalid rows. Consent flags are never guessed. Soft-archived customers stay out of the main directory.

### Financial integrity
- Service-only, part, GST, discount, paid/partial/unpaid and direct invoices produce correct totals.
- Concurrent bill requests do not oversell stock. Duplicate idempotency keys do not create duplicate bills/payments.
- Two simultaneous payments cannot exceed the balance. Negative amounts, overpayments, wrong-customer complaint links and discounts over the subtotal fail.
- Failed stock/payment validations roll back the entire transaction.
- Screen, print and PDF show the same invoice figures. Long line items paginate. A private uploaded PDF has a valid expiring sharing link; it is not publicly browsable.
- Owner archive preserves accounting and stock movement history; record retention policy is understood.

### Phase 2 / 3
- Warranty durations/dates, active-expired banners, reminder windows and AMC visit limits work.
- Stock adjustments cannot make quantity negative. Supplier/threshold changes update alerts.
- All marketing audiences exclude opted-out and non-consenting customers. Opening WhatsApp is not auto-marked sent.
- Report ranges reconcile against payment/expense records. CSV/XLSX exports escape spreadsheet formulas.
- Owner user creation, role change and disabling work; non-owner direct requests fail.
- PWA install/app-shell offline behavior and every Capacitor Android workflow are tested on a real device.

## Release sign-off

Do not use real customer data or announce production readiness until the full build, role security, transactional concurrency, backups and real-device checks pass. Record the tester, date and deployed commit for each acceptance category.
