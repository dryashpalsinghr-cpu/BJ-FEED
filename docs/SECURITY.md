# Security and launch checklist

## Included controls

- Separate `user_roles`; active profiles checked in security-definer helpers.
- RLS enabled for all 22 tables including the internal rate-limit table.
- Technician access is constrained to active assignments. Customer contact is returned through an assignment-checked RPC, not a directory policy.
- No anonymous direct table insert/select policies. Public flows go through a narrow Edge Function using server-only credentials.
- Public tracking returns only complaint number, status, appliance and status timestamps.
- Private photos and PDFs. Internal photo access follows job assignment. PDF links expire after 7 days; anyone holding a signed link can access it until expiry.
- Public media MIME, size and signature validation. Public upload token expires after 30 minutes and permits at most 3 registered photos with server-side locking.
- Atomic bill totals, stock deduction and initial payment. Idempotent bill creation; row-locked, idempotent additional payments. No direct client inserts into bills/payments or status-history writes.
- Owner-only verified Edge Function for user administration. Roles are not client-mutable.
- Spreadsheet formula-injection prevention on exported text.
- Customer opt-out and positive marketing consent filters. No service-role secret in source.

## Before a public release

1. Deploy to a non-production project first. Apply all migrations in order and inspect database/Edge logs.
2. Run every acceptance case in `QA.md` against owner, staff, technician and anonymous sessions. Also call REST/RPC endpoints directly; hidden navigation is not a security control.
3. Disable signup, enforce strong passwords, enable owner MFA where practical and configure password resets and recovery procedures.
4. Audit dependencies, add a lockfile, update vulnerable packages, and configure HTTPS, CSP/security headers and PII-safe monitoring. Browser font downloads currently use Google Fonts; self-host Inter for deterministic offline typography.
5. Add retention policies for complaint photos, PDFs, expired rate-limit keys and public-upload orphans. Never log phone numbers or service-role secrets.
6. Set up database and private-storage backups, test recovery, and tightly restrict Supabase admin access. Excel export alone is not a recovery plan.
7. For abuse at scale add CAPTCHA/Turnstile, verified contact flow, per-project usage thresholds and a trusted-proxy/WAF limiter. Phone/IP rate limits here are simple local-business protections, not comprehensive anti-bot controls. Validate IP forwarding semantics on the deployed gateway.
8. Existing contact data is not overwritten by unauthenticated requests. Staff should review potentially duplicate or spoofed requests. Phone + sequential complaint number is not identity verification; status output remains redacted.
9. Review applicable consent, customer privacy, tax and invoice rules with a qualified local professional. Do not market to sample numbers.
10. Review revoke/disable behavior for already-open sessions and mobile devices. Live customer data stays in memory; do not add a shared localStorage business-data cache without user scoping, encryption and revocation handling.

## Permissions matrix

| Area | Owner | Staff | Technician | Public |
|---|---|---|---|---|
| Complaints | All | All | Assigned jobs only | Submit / redacted track |
| Customer directory | Read / write | Read / write | No; assigned contact RPC only | No |
| Bills and payments | All workflows | Create / read / collect | No | Signed link if shared |
| Income analytics / expenses | Yes | No report route | No | No |
| Inventory | Full | Redacted parts catalogue for billing | No | No |
| Warranty / reminders / AMC | Read / write | Read / write | No | No |
| Marketing / settings / users | Full | No | No | No |
| Feedback | Read | Read | No | Token submission for completed repair |

Staff necessarily see invoice and payment amounts to perform billing; hiding the income dashboard does not prevent them inferring income from accessible bills. If strict accounting isolation is needed, define a more restrictive operational billing scope with server-generated financial redaction.
