-- Table for user-created custom meals.
-- Run this in the Supabase SQL Editor once to enable cloud sync.
--
-- Anonymous Auth must be enabled in Supabase:
--   Authentication → Providers → Anonymous Sign-In → Enable

CREATE TABLE IF NOT EXISTS user_custom_meals (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lookup_key  TEXT NOT NULL,
    meal_data   JSONB NOT NULL,
    updated_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, lookup_key)
);

ALTER TABLE user_custom_meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own custom meals"
    ON user_custom_meals FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
