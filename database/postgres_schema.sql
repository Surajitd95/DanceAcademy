-- ═══════════════════════════════════════════════════════════════
--  NRITYA KALA MANDIR — PostgreSQL Schema
--  Run this in pgAdmin Query Tool on the nritya_kala_mandir database
-- ═══════════════════════════════════════════════════════════════

-- ── TABLES ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS admin_users (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email         VARCHAR(200),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS site_content (
    content_key   VARCHAR(100) PRIMARY KEY,
    content_value TEXT         NOT NULL,
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by    VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS dance_classes (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    description TEXT         NOT NULL,
    image_url   VARCHAR(500),
    tags        VARCHAR(300),
    sort_order  INT          NOT NULL DEFAULT 0,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gallery (
    id          SERIAL PRIMARY KEY,
    media_url   VARCHAR(500) NOT NULL,
    media_type  VARCHAR(20)  NOT NULL CHECK (media_type IN ('photos','videos')),
    caption     VARCHAR(300) DEFAULT '',
    sort_order  INT          NOT NULL DEFAULT 0,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    uploaded_by VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS events (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(300) NOT NULL,
    location    VARCHAR(300) NOT NULL,
    event_date  DATE         NOT NULL,
    event_day   VARCHAR(5)   NOT NULL,
    event_month VARCHAR(10)  NOT NULL,
    description TEXT,
    status      VARCHAR(20)  NOT NULL DEFAULT 'upcoming'
                CHECK (status IN ('upcoming','past')),
    image_url   VARCHAR(500),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS enquiries (
    id          SERIAL PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(200) NOT NULL,
    phone       VARCHAR(30),
    dance_form  VARCHAR(100),
    message     TEXT,
    is_read     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS testimonials (
    id          SERIAL PRIMARY KEY,
    author_name VARCHAR(150) NOT NULL,
    author_role VARCHAR(200),
    avatar_url  VARCHAR(500),
    quote_text  TEXT         NOT NULL,
    sort_order  INT          NOT NULL DEFAULT 0,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hero_banners (
    id          SERIAL PRIMARY KEY,
    image_url   VARCHAR(500) NOT NULL,
    alt_text    VARCHAR(300) DEFAULT 'Hero Banner',
    sort_order  INT          NOT NULL DEFAULT 0,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    uploaded_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth_tokens (
    id           SERIAL PRIMARY KEY,
    token        VARCHAR(128) NOT NULL UNIQUE,
    admin_user_id INT         NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    expires_at   TIMESTAMPTZ  NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS ix_enquiries_is_read   ON enquiries(is_read);
CREATE INDEX IF NOT EXISTS ix_enquiries_created   ON enquiries(created_at DESC);
CREATE INDEX IF NOT EXISTS ix_auth_tokens_token   ON auth_tokens(token);
CREATE INDEX IF NOT EXISTS ix_auth_tokens_expires ON auth_tokens(expires_at);

-- ── SEED DATA ────────────────────────────────────────────────

-- Default admin: password is admin123 (bcrypt hash)
INSERT INTO admin_users (username, password_hash, email)
VALUES ('admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewFnT.pDHxCkSi6S', 'admin@yourdomain.com')
ON CONFLICT (username) DO NOTHING;

-- Site content
INSERT INTO site_content (content_key, content_value) VALUES
('about', '{
    "title": "A Legacy of Grace & Devotion",
    "body": "<p>Founded in the heart of Durgapur, Nritya Kala Mandir has been nurturing the art of Indian classical dance for over 19 years.</p><p>Our Guru is a graded artist of Doordarshan Kendra Kolkata, having performed across prestigious Indian festivals and internationally in Germany, Netherlands, and Sweden.</p>",
    "quote": "Let your life lightly dance on the edges of Time like dew on the tip of a leaf.",
    "years": "19+",
    "students": "500+",
    "perfs": "100+"
}'),
('contact', '{
    "address": "Durgapur, West Bengal - 713201",
    "phone": "+91-XXXXXXXXXX",
    "email": "info@yourdomain.com",
    "hours": "Mon-Sat: 4:00 PM - 8:00 PM",
    "facebook": "",
    "instagram": "",
    "youtube": ""
}')
ON CONFLICT (content_key) DO NOTHING;

-- Dance classes
INSERT INTO dance_classes (name, description, tags, sort_order) VALUES
('Bharatanatyam', 'One of India''s oldest classical dance forms, rooted in Tamil Nadu''s temple traditions. A rigorous and expressive art of rhythm and devotion.', 'All Ages,Beginner to Advanced', 1),
('Kuchipudi',     'A vibrant dance-drama tradition from Andhra Pradesh, combining pure dance, expressive mime, and devotional themes with unmatched energy.', 'Ages 6+,All Levels', 2),
('Mohiniyattam',  'Kerala''s lyrical and feminine classical dance, characterized by swaying, graceful movements that evoke the mythological enchantress Mohini.', 'Ages 8+,Intermediate+', 3)
ON CONFLICT DO NOTHING;

-- Testimonials
INSERT INTO testimonials (author_name, author_role, quote_text, sort_order) VALUES
('Priya Dasgupta',  'Bharatanatyam – 4 years',      'Joining this academy was the best decision of my life. The guidance here transformed not just my dance but my entire perspective on art and discipline.', 1),
('Anita Mukherjee', 'Parent of Kuchipudi student',   'The Guru''s teaching style is both disciplined and deeply nurturing. My daughter has blossomed here — in confidence, posture, and grace.', 2),
('Riya Sen',        'Mohiniyattam – 2 years',        'Performing on stage for the first time was a dream I never thought possible. This academy made it real. Forever grateful.', 3)
ON CONFLICT DO NOTHING;

-- Events
INSERT INTO events (title, location, event_date, event_day, event_month, description, status) VALUES
('Independence Day Cultural Program', 'Durgapur Town Hall',      '2025-08-15', '15', 'Aug', 'Annual celebration featuring Bharatanatyam and group Kuchipudi performances by our senior students.', 'upcoming'),
('Autumn Dance Festival 2025',        'Rabindra Bhawan, Kolkata','2025-10-02', '02', 'Oct', 'Multi-day classical dance festival showcasing our academy''s finest performers across all dance forms.', 'upcoming')
ON CONFLICT DO NOTHING;

-- ── VERIFY ───────────────────────────────────────────────────
SELECT tablename AS "Table", 
       (SELECT COUNT(*) FROM information_schema.columns 
        WHERE table_name = t.tablename) AS "Columns"
FROM pg_tables t
WHERE schemaname = 'public'
ORDER BY tablename;
