# Feature status and release boundaries

This source package implements the screens and backend workflows listed below. “Implemented” means code is included, **not that live deployment or production acceptance tests passed**.

## Phase 1 — source implemented

- Email/password login, owner/staff/technician route guards and separate user_roles.
- Public complaint submission through an Edge Function, honeypot, mobile/IP limits, transactional numbering, optional photos, thank-you screen and tracking.
- Redacted public status timeline: no customer name, address, notes or photos returned.
- Owner/staff dashboard, status filters, searches, complaint cards and Recharts dashboard.
- Admin complaint entry with customer lookup; source, priority, visit time and assignment.
- Complaint detail, status audit, notes, photo uploads, call/Maps/WhatsApp links and billing link.
- Customer directory/profile, alternate addresses, tags, consent, soft archive and CSV import/export.
- Atomic bill, line items, initial payment and stock deduction. Later payments check outstanding balances with row locking. GST and discount validation run on the server.
- English downloadable/printable invoices. PDF upload uses private Storage and a 7-day signed URL. The user explicitly taps a WhatsApp link after PDF generation; this avoids async popup blocking.
- Realtime complaint notification, unread badge and opt-in sound (enable it by tapping Sound on).

## Phase 2 — source implemented

- Warranty expiry and coverage, complaint-entry warranty banners and warranty views.
- Editable next-service dates, 7/30-day reminder lists, default 6-month AC service interval.
- AMC contracts, dates, visit counts and manual renewal reminders.
- Inventory catalogue, prices, stock in/out, low-stock thresholds and movement history.
- Technician accounts, assignment, own-job visibility, visit filter, call/Maps, photos and notes.

## Phase 3 — source implemented

- English seasonal templates, editable templates, consent-filtered audiences and live personalized preview.
- Manual WhatsApp/SMS queue and manual sent acknowledgement. There is no delivery API or automatic proof of delivery.
- Token-based customer feedback and review-request WhatsApp links.
- Owner cash-basis income/expense reports, outstanding, appliance mix, top customers and technician completions; CSV, XLSX and basic PDF export.
- Shop settings, logo storage, GST, UPI, footer, review link and default warranty.
- Owner-controlled user creation, enable/disable and role changes.
- Data-record Excel export, PWA app-shell caching, Android Capacitor config.

## Explicit gaps / decisions requiring work before launch

1. **Production build and live Supabase testing are not completed.** Install dependencies and use the included CI and test checklist. Database/function source audits do not replace executing migrations or RLS tests.
2. **Offline:** app assets and already-visible screens are retained. Customer/business data is not persisted offline in live mode, and writes are not queued. Cold-start offline viewing of live customer records requires a secure, user-scoped offline cache and revocation design. Demo mode persists sample data only.
3. **Native Android:** configuration is included, not an APK. File sharing, downloads, printing, camera/gallery, device back behavior and offline support need real-device validation and possibly Capacitor plugins.
4. **PDF:** English invoice contents and pagination are implemented; PDF generator uses standard Latin fonts. Shop logo is shown in the screen/print invoice; the downloadable PDF currently uses a branded text header rather than embedding a uploaded logo. Very long fields and advanced PDF styling need final acceptance testing.
5. **WhatsApp:** wa.me/SMS links only. No automatic sending, delivery webhooks, unsubscribe web page, paid API or scheduled campaigns. Per-customer opt_out is editable in the directory and enforced by recipient selection; re-check consent before each manual send.
6. **Consent/security:** public requests do not overwrite an existing customer's verified name, address or marketing consent. Submitted names/addresses are captured on the individual complaint instead. Shop staff can correct customer details. Existing customers' opt-in changes must be made by authorized staff.
7. **Reports:** cash surplus is collections minus explicitly recorded expenses, not audited accrual profit. Stock purchases are not automatically expense entries. Technician completion timestamps are the latest job update; add a dedicated completion timestamp for rigorous historical reporting.
8. **Exports:** Excel data export is not a complete restore backup. Storage files and Auth users require separate managed backups. CSV import is sequential and capped at 500 rows; duplicate rows within one import may be rejected. Detailed per-row retry logs are a future improvement.
9. **Scale:** table fetches are paginated, but whole accessible tables are held in memory. Add server-side searches, date-window queries, pagination and dashboard RPCs for large volumes.
10. **Users:** password reset/rotation is administered through Supabase by the owner. Self-service reset flows, owner MFA, advanced audit logs and invitation emails are not included.
11. **Warranty:** selecting None currently creates no warranty; it does not remove an existing warranty. Add an explicit cancel/revoke warranty action if needed.
12. **Inventory:** owner controls stock management and inventory cost. Staff can pick stock items while invoicing through a redacted catalogue. Staff do not have an inventory-management route.
13. **AMC/campaign writes:** basic record workflows are included. Add dedicated atomic visit-consumption and bulk campaign-creation RPCs for concurrent/multi-user workloads.
14. **Public routes:** login, `/complaint`, `/track` and token feedback are unauthenticated because the requested flows need them. All internal pages require a role-bearing login. Tracking is protected by mobile + complaint number and rate limits, not OTP verification.

Do not claim production readiness, complete native functionality or automatic WhatsApp delivery until these boundaries are resolved and acceptance tests pass.
