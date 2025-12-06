-- =============================================
-- FUNCTIONS: Database functions and triggers
-- =============================================

-- Drop existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_user_settings_updated_at ON public.user_settings;
DROP TRIGGER IF EXISTS update_reward_wallet_updated_at ON public.reward_wallet;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile
    INSERT INTO public.profiles (id, username, email)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NEW.email
    );
    
    -- Initialize user settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);
    
    -- Initialize reward wallet
    INSERT INTO public.reward_wallet (user_id, points)
    VALUES (NEW.id, 0);
        
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings 
    FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();

CREATE TRIGGER update_reward_wallet_updated_at BEFORE UPDATE ON public.reward_wallet 
    FOR EACH ROW EXECUTE PROCEDURE public.update_updated_at_column();