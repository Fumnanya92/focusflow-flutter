-- =============================================
-- FocusFlow Database Migration 06: Security Policies
-- Row Level Security for data protection
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_usage_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_wallet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_spin ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.motivational_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- User settings policies
CREATE POLICY "Users can view own settings" ON public.user_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON public.user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own settings" ON public.user_settings FOR DELETE USING (auth.uid() = user_id);

-- App usage sessions policies
CREATE POLICY "Users can view own app usage" ON public.app_usage_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own app usage" ON public.app_usage_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own app usage" ON public.app_usage_sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own app usage" ON public.app_usage_sessions FOR DELETE USING (auth.uid() = user_id);

-- Daily summaries policies
CREATE POLICY "Users can view own summaries" ON public.daily_summaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own summaries" ON public.daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own summaries" ON public.daily_summaries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own summaries" ON public.daily_summaries FOR DELETE USING (auth.uid() = user_id);

-- Badges policies (read-only for users)
CREATE POLICY "Anyone can view badges" ON public.badges FOR SELECT USING (TRUE);

-- User badges policies
CREATE POLICY "Users can view own badges" ON public.user_badges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own badges" ON public.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Reward wallet policies
CREATE POLICY "Users can view own wallet" ON public.reward_wallet FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wallet" ON public.reward_wallet FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wallet" ON public.reward_wallet FOR UPDATE USING (auth.uid() = user_id);

-- Reward transactions policies
CREATE POLICY "Users can view own transactions" ON public.reward_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON public.reward_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily spin policies
CREATE POLICY "Users can view own spins" ON public.daily_spin FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own spins" ON public.daily_spin FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own spins" ON public.daily_spin FOR UPDATE USING (auth.uid() = user_id);

-- Motivational messages policies (read-only)
CREATE POLICY "Anyone can view messages" ON public.motivational_messages FOR SELECT USING (TRUE);

-- Challenges policies (read-only)
CREATE POLICY "Anyone can view challenges" ON public.challenges FOR SELECT USING (TRUE);

-- User challenges policies
CREATE POLICY "Users can view own challenges" ON public.user_challenges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own challenges" ON public.user_challenges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own challenges" ON public.user_challenges FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own challenges" ON public.user_challenges FOR DELETE USING (auth.uid() = user_id);