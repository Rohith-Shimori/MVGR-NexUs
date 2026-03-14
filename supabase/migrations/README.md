# MVGR NexUs - Supabase Database Migrations

Modular SQL files for setting up the Supabase database. Run files **in order** (00 → 12).

## 📁 File Structure

| File | Purpose | Tables/Objects |
|------|---------|----------------|
| `00_cleanup.sql` | 🧹 Reset database | Drops all |
| `01_extensions.sql` | 🔧 Extensions | uuid-ossp, pg_trgm |
| `02_schema_users.sql` | 👤 Users | users |
| `03_schema_clubs.sql` | 🏢 Clubs | clubs, club_members, club_requests, club_posts |
| `04_schema_events.sql` | 📅 Events | events, event_rsvps |
| `05_schema_content.sql` | 📝 Content | announcements, vault_items, forum_* |
| `06_schema_community.sql` | 🤝 Community | study_*, team_*, mentors, meetups, lost_found |
| `06b_schema_extras.sql` | 🎵 Extras | feedback, radio_tracks, mentorship_sessions |
| `07_schema_moderation.sql` | 🛡️ Moderation | reports |
| `08_functions.sql` | ⚙️ Functions | handle_new_user, get_user_role, etc. |
| `09_rls_policies.sql` | 🔐 RLS | Policies for all tables |
| `10_storage.sql` | 📦 Storage | 7 buckets (profiles, clubs, events, vault, etc.) |
| `11_indexes.sql` | 🚀 Performance | Query indexes |
| `12_seed_data.sql` | 🌱 Demo Data | Sample clubs (optional) |

## 🚀 Quick Setup

1. Go to [Supabase Dashboard](https://supabase.com) → SQL Editor
2. Run each file in order (00 → 12)
3. Check for ✅ success messages

> ⚠️ **Skip `00_cleanup.sql`** if you want to keep existing data!

## ⭐ Key Fix: Auth User Sync

File `08_functions.sql` contains the `handle_new_user()` trigger that **auto-creates user profiles** when someone signs up. This fixes the login issue!

## 📊 Total Tables: 25

```
Users (1) | Clubs (4) | Events (2) | Content (5)
Community (8) | Extras (4) | Moderation (1)
```

## ✅ Verification

After running all files:
```sql
-- Check tables exist
SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';
-- Expected: 25

-- Check auth trigger
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
```
