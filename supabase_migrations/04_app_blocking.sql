-- =============================================
-- FocusFlow Database Migration 04: Content & Challenges
-- Motivational content and challenge system
-- =============================================

-- ===========================================
-- CONTENT LIBRARY (Motivational messages, challenges)
-- ===========================================
CREATE TABLE motivational_messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category TEXT,  -- "discipline", "focus", "faith", "productivity"
    message TEXT NOT NULL
);

CREATE TABLE challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    duration_days INTEGER NOT NULL,
    reward_points INTEGER NOT NULL
);

CREATE TABLE user_challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    challenge_id BIGINT REFERENCES challenges(id),

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    UNIQUE(user_id, challenge_id)
);

-- ===========================================
-- INSERT DEFAULT MOTIVATIONAL MESSAGES
-- ===========================================
INSERT INTO motivational_messages (category, message) VALUES
('discipline', 'Discipline is the bridge between goals and accomplishment.'),
('focus', 'Where focus goes, energy flows.'),
('faith', 'Faith makes all things possible, love makes them easy.'),
('productivity', 'The way to get started is to quit talking and begin doing.');

-- ===========================================
-- INSERT DEFAULT CHALLENGES
-- ===========================================
INSERT INTO challenges (title, description, duration_days, reward_points) VALUES
('Digital Detox Weekend', 'Spend the weekend with minimal social media usage', 2, 500),
('Morning Focus Challenge', 'No social media before 10 AM for one week', 7, 300),
('Productive Evening', 'Replace evening social media with productive activities', 5, 200);