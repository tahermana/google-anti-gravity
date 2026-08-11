# Supabase Security Checklist

This Flutter app must only use public Supabase values:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Never put these in Flutter, Git, or any client build:

- `SUPABASE_SERVICE_ROLE_KEY`
- `DATABASE_PASSWORD`
- `DIRECT_DATABASE_URL`
- `JWT_SECRET`

## Required Supabase Setup

1. Open the Supabase SQL editor for your project.
2. Run `supabase/migrations/20260809000000_security_hardening.sql`.
3. Run `supabase/rls_self_test.sql` to verify user isolation. It rolls back its test data.
4. Keep admin actions on a server only, such as Supabase Edge Functions or your own backend.
5. Before launch, confirm:
   - User A can read/write only User A data.
   - User B cannot read/write User A data.
   - Anonymous users cannot access private rows.

## Flutter Build Values

Pass public values at build/run time:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://your-project-ref.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-public-publishable-or-anon-key
```

Do not pass service-role or database password values with `--dart-define`.
