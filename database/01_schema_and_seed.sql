-- ═══════════════════════════════════════════════════════════════
--  NRITYA KALA MANDIR — SQL Server Database Schema
--  Run this entire script in SSMS once to set up everything
--  Compatible with: SQL Server Express 2017/2019/2022
-- ═══════════════════════════════════════════════════════════════

-- ── STEP 1: Create the database ──────────────────────────────
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'NrityaKalaMandir')
BEGIN
    CREATE DATABASE NrityaKalaMandir;
    PRINT 'Database NrityaKalaMandir created.';
END
ELSE
    PRINT 'Database NrityaKalaMandir already exists.';
GO

USE NrityaKalaMandir;
GO

-- ── STEP 2: Tables ───────────────────────────────────────────

-- ─────────────────────────────────────────
-- 1. ADMIN USERS
--    Stores login credentials for the admin panel.
--    Passwords are stored as bcrypt hashes — never plain text.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AdminUsers')
BEGIN
    CREATE TABLE AdminUsers (
        Id           INT IDENTITY(1,1) PRIMARY KEY,
        Username     NVARCHAR(100)  NOT NULL UNIQUE,
        PasswordHash NVARCHAR(255)  NOT NULL,  -- bcrypt hash
        Email        NVARCHAR(200)  NULL,
        IsActive     BIT            NOT NULL DEFAULT 1,
        LastLogin    DATETIME2      NULL,
        CreatedAt    DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Table AdminUsers created.';
END
GO

-- ─────────────────────────────────────────
-- 2. SITE CONTENT
--    Key-value store for all editable text content.
--    e.g. about section, contact info, hero images list, etc.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SiteContent')
BEGIN
    CREATE TABLE SiteContent (
        ContentKey   NVARCHAR(100)  NOT NULL PRIMARY KEY,
        ContentValue NVARCHAR(MAX)  NOT NULL,  -- JSON string
        UpdatedAt    DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UpdatedBy    NVARCHAR(100)  NULL
    );
    PRINT 'Table SiteContent created.';
END
GO

-- ─────────────────────────────────────────
-- 3. DANCE CLASSES
--    Each row is one dance form offered by the academy.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DanceClasses')
BEGIN
    CREATE TABLE DanceClasses (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        Name        NVARCHAR(150)  NOT NULL,
        Description NVARCHAR(MAX)  NOT NULL,
        ImageUrl    NVARCHAR(500)  NULL,
        Tags        NVARCHAR(300)  NULL,  -- comma-separated, e.g. "All Ages,Beginner to Advanced"
        SortOrder   INT            NOT NULL DEFAULT 0,
        IsActive    BIT            NOT NULL DEFAULT 1,
        CreatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Table DanceClasses created.';
END
GO

-- ─────────────────────────────────────────
-- 4. GALLERY
--    Stores metadata for uploaded photos and videos.
--    The actual files live in Cloudflare R2.
--    MediaUrl = the R2 public URL.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Gallery')
BEGIN
    CREATE TABLE Gallery (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        MediaUrl    NVARCHAR(500)  NOT NULL,
        MediaType   NVARCHAR(20)   NOT NULL CHECK (MediaType IN ('photos', 'videos')),
        Caption     NVARCHAR(300)  NULL DEFAULT '',
        SortOrder   INT            NOT NULL DEFAULT 0,
        IsActive    BIT            NOT NULL DEFAULT 1,
        UploadedAt  DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UploadedBy  NVARCHAR(100)  NULL
    );
    PRINT 'Table Gallery created.';
END
GO

-- ─────────────────────────────────────────
-- 5. EVENTS
--    Upcoming and past performances/shows.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Events')
BEGIN
    CREATE TABLE Events (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        Title       NVARCHAR(300)  NOT NULL,
        Location    NVARCHAR(300)  NOT NULL,
        EventDate   DATE           NOT NULL,
        EventDay    NVARCHAR(5)    NOT NULL,   -- "15" (display day)
        EventMonth  NVARCHAR(10)   NOT NULL,   -- "Aug" (display month)
        Description NVARCHAR(MAX)  NULL,
        Status      NVARCHAR(20)   NOT NULL DEFAULT 'upcoming'
                    CHECK (Status IN ('upcoming', 'past')),
        ImageUrl    NVARCHAR(500)  NULL,
        CreatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Table Events created.';
END
GO

-- ─────────────────────────────────────────
-- 6. ENQUIRIES
--    Form submissions from the contact/enrollment form.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Enquiries')
BEGIN
    CREATE TABLE Enquiries (
        Id           INT IDENTITY(1,1) PRIMARY KEY,
        FirstName    NVARCHAR(100)  NOT NULL,
        LastName     NVARCHAR(100)  NOT NULL,
        Email        NVARCHAR(200)  NOT NULL,
        Phone        NVARCHAR(30)   NULL,
        DanceForm    NVARCHAR(100)  NULL,
        Message      NVARCHAR(MAX)  NULL,
        IsRead       BIT            NOT NULL DEFAULT 0,
        CreatedAt    DATETIME2      NOT NULL DEFAULT GETUTCDATE(),

        -- Basic index for fast unread-count queries
        INDEX IX_Enquiries_IsRead (IsRead),
        INDEX IX_Enquiries_CreatedAt (CreatedAt DESC)
    );
    PRINT 'Table Enquiries created.';
END
GO

-- ─────────────────────────────────────────
-- 7. TESTIMONIALS
--    Student/parent reviews shown on the website.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Testimonials')
BEGIN
    CREATE TABLE Testimonials (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        AuthorName  NVARCHAR(150)  NOT NULL,
        AuthorRole  NVARCHAR(200)  NULL,  -- e.g. "Bharatanatyam – 4 years"
        AvatarUrl   NVARCHAR(500)  NULL,
        QuoteText   NVARCHAR(MAX)  NOT NULL,
        SortOrder   INT            NOT NULL DEFAULT 0,
        IsActive    BIT            NOT NULL DEFAULT 1,
        CreatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Table Testimonials created.';
END
GO

-- ─────────────────────────────────────────
-- 8. HERO BANNERS
--    Full-screen slideshow images for the homepage hero.
--    Separate table (not key-value) for cleaner ordering.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HeroBanners')
BEGIN
    CREATE TABLE HeroBanners (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        ImageUrl    NVARCHAR(500)  NOT NULL,
        AltText     NVARCHAR(300)  NULL DEFAULT 'Hero Banner',
        SortOrder   INT            NOT NULL DEFAULT 0,
        IsActive    BIT            NOT NULL DEFAULT 1,
        UploadedAt  DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
    PRINT 'Table HeroBanners created.';
END
GO

-- ─────────────────────────────────────────
-- 9. AUTH TOKENS
--    Tracks active admin session tokens.
--    Token is invalidated on logout or after 12 hours.
-- ─────────────────────────────────────────
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuthTokens')
BEGIN
    CREATE TABLE AuthTokens (
        Id          INT IDENTITY(1,1) PRIMARY KEY,
        Token       NVARCHAR(128)  NOT NULL UNIQUE,
        AdminUserId INT            NOT NULL REFERENCES AdminUsers(Id) ON DELETE CASCADE,
        ExpiresAt   DATETIME2      NOT NULL,
        CreatedAt   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),

        INDEX IX_AuthTokens_Token (Token),
        INDEX IX_AuthTokens_ExpiresAt (ExpiresAt)
    );
    PRINT 'Table AuthTokens created.';
END
GO


-- ══════════════════════════════════════════════════════════════
--  STEP 3: Seed default data
-- ══════════════════════════════════════════════════════════════

-- Default admin user
-- Password is: admin123  (bcrypt hash below)
-- IMPORTANT: Change this password immediately after first login
IF NOT EXISTS (SELECT 1 FROM AdminUsers WHERE Username = 'admin')
BEGIN
    INSERT INTO AdminUsers (Username, PasswordHash, Email, IsActive)
    VALUES (
        'admin',
        '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewFnT.pDHxCkSi6S',
        'admin@yourdomain.com',
        1
    );
    PRINT 'Default admin user created. Username: admin | Password: admin123';
END
GO

-- Default site content
IF NOT EXISTS (SELECT 1 FROM SiteContent WHERE ContentKey = 'about')
BEGIN
    INSERT INTO SiteContent (ContentKey, ContentValue) VALUES (
        'about',
        N'{
            "title": "A Legacy of Grace & Devotion",
            "body": "<p>Founded in the heart of Durgapur, Nritya Kala Mandir has been nurturing the art of Indian classical dance for over 19 years. Our institute is a sanctuary where tradition meets passion.</p><p>Our Guru is a graded artist of Doordarshan Kendra Kolkata, having performed across prestigious Indian festivals and internationally in Germany, Netherlands, and Sweden.</p>",
            "quote": "Let your life lightly dance on the edges of Time like dew on the tip of a leaf.",
            "years": "19+",
            "students": "500+",
            "perfs": "100+"
        }'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM SiteContent WHERE ContentKey = 'contact')
BEGIN
    INSERT INTO SiteContent (ContentKey, ContentValue) VALUES (
        'contact',
        N'{
            "address": "Durgapur, West Bengal - 713201",
            "phone": "+91-XXXXXXXXXX",
            "email": "info@yourdomain.com",
            "hours": "Mon-Sat: 4:00 PM - 8:00 PM",
            "facebook": "",
            "instagram": "",
            "youtube": ""
        }'
    );
END
GO

-- Default dance classes
IF NOT EXISTS (SELECT 1 FROM DanceClasses WHERE Name = 'Bharatanatyam')
BEGIN
    INSERT INTO DanceClasses (Name, Description, Tags, SortOrder) VALUES
    ('Bharatanatyam',
     'One of India''s oldest classical dance forms, rooted in Tamil Nadu''s temple traditions. A rigorous and expressive art of rhythm and devotion.',
     'All Ages,Beginner to Advanced', 1),
    ('Kuchipudi',
     'A vibrant dance-drama tradition from Andhra Pradesh, combining pure dance, expressive mime, and devotional themes with unmatched energy.',
     'Ages 6+,All Levels', 2),
    ('Mohiniyattam',
     'Kerala''s lyrical and feminine classical dance, characterized by swaying, graceful movements that evoke the mythological enchantress Mohini.',
     'Ages 8+,Intermediate+', 3);
    PRINT 'Default dance classes inserted.';
END
GO

-- Default testimonials
IF NOT EXISTS (SELECT 1 FROM Testimonials WHERE AuthorName = 'Priya Dasgupta')
BEGIN
    INSERT INTO Testimonials (AuthorName, AuthorRole, QuoteText, SortOrder) VALUES
    ('Priya Dasgupta',   'Bharatanatyam – 4 years',
     'Joining this academy was the best decision of my life. The guidance here transformed not just my dance but my entire perspective on art and discipline.', 1),
    ('Anita Mukherjee',  'Parent of Kuchipudi student',
     'The Guru''s teaching style is both disciplined and deeply nurturing. My daughter has blossomed here — in confidence, posture, and grace.', 2),
    ('Riya Sen',         'Mohiniyattam – 2 years',
     'Performing on stage for the first time was a dream I never thought possible. This academy made it real. Forever grateful.', 3);
    PRINT 'Default testimonials inserted.';
END
GO

-- Default upcoming events
IF NOT EXISTS (SELECT 1 FROM Events WHERE Title = 'Independence Day Cultural Program')
BEGIN
    INSERT INTO Events (Title, Location, EventDate, EventDay, EventMonth, Description, Status) VALUES
    ('Independence Day Cultural Program',
     'Durgapur Town Hall',
     '2025-08-15', '15', 'Aug',
     'Annual celebration featuring Bharatanatyam and group Kuchipudi performances by our senior students.',
     'upcoming'),
    ('Autumn Dance Festival 2025',
     'Rabindra Bhawan, Kolkata',
     '2025-10-02', '02', 'Oct',
     'Multi-day classical dance festival showcasing our academy''s finest performers across all dance forms.',
     'upcoming');
    PRINT 'Default events inserted.';
END
GO


-- ══════════════════════════════════════════════════════════════
--  STEP 4: Useful Views
-- ══════════════════════════════════════════════════════════════

-- View: dashboard stats (used by admin overview panel)
GO
CREATE OR ALTER VIEW vw_DashboardStats AS
    SELECT
        (SELECT COUNT(*) FROM Enquiries)                              AS TotalEnquiries,
        (SELECT COUNT(*) FROM Enquiries WHERE IsRead = 0)            AS UnreadEnquiries,
        (SELECT COUNT(*) FROM Gallery WHERE IsActive = 1)            AS TotalMedia,
        (SELECT COUNT(*) FROM Events WHERE Status = 'upcoming')      AS UpcomingEvents,
        (SELECT COUNT(*) FROM DanceClasses WHERE IsActive = 1)       AS ActiveClasses,
        (SELECT COUNT(*) FROM Testimonials WHERE IsActive = 1)       AS ActiveTestimonials;
GO

-- View: recent enquiries for the overview panel
CREATE OR ALTER VIEW vw_RecentEnquiries AS
    SELECT TOP 10
        Id, FirstName, LastName, Email, Phone,
        DanceForm, Message, IsRead, CreatedAt
    FROM Enquiries
    ORDER BY CreatedAt DESC;
GO

-- View: active gallery ordered correctly
CREATE OR ALTER VIEW vw_ActiveGallery AS
    SELECT Id, MediaUrl, MediaType, Caption, SortOrder, UploadedAt
    FROM Gallery
    WHERE IsActive = 1
    ORDER BY (SELECT NULL);  -- actual order applied by query
GO


-- ══════════════════════════════════════════════════════════════
--  STEP 5: Stored Procedures (cleaner than inline SQL in Python)
-- ══════════════════════════════════════════════════════════════

-- Get all public content in one call (used by frontend)
GO
CREATE OR ALTER PROCEDURE sp_GetPublicContent
AS
BEGIN
    SET NOCOUNT ON;

    -- Site content (about, contact)
    SELECT ContentKey, ContentValue FROM SiteContent;

    -- Active classes
    SELECT Id, Name, Description, ImageUrl, Tags, SortOrder
    FROM DanceClasses
    WHERE IsActive = 1
    ORDER BY SortOrder;

    -- Active gallery
    SELECT Id, MediaUrl, MediaType, Caption, SortOrder
    FROM Gallery
    WHERE IsActive = 1
    ORDER BY SortOrder;

    -- Events
    SELECT Id, Title, Location, EventDate, EventDay, EventMonth, Description, Status
    FROM Events
    ORDER BY EventDate;

    -- Active testimonials
    SELECT Id, AuthorName, AuthorRole, AvatarUrl, QuoteText
    FROM Testimonials
    WHERE IsActive = 1
    ORDER BY SortOrder;

    -- Active hero banners
    SELECT Id, ImageUrl, AltText
    FROM HeroBanners
    WHERE IsActive = 1
    ORDER BY SortOrder;
END
GO

-- Submit enquiry
CREATE OR ALTER PROCEDURE sp_InsertEnquiry
    @FirstName  NVARCHAR(100),
    @LastName   NVARCHAR(100),
    @Email      NVARCHAR(200),
    @Phone      NVARCHAR(30),
    @DanceForm  NVARCHAR(100),
    @Message    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Enquiries (FirstName, LastName, Email, Phone, DanceForm, Message)
    VALUES (@FirstName, @LastName, @Email, @Phone, @DanceForm, @Message);
    SELECT SCOPE_IDENTITY() AS NewId;
END
GO

-- Mark enquiry as read
CREATE OR ALTER PROCEDURE sp_MarkEnquiryRead
    @EnquiryId INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Enquiries SET IsRead = 1 WHERE Id = @EnquiryId;
END
GO

-- Upsert site content
CREATE OR ALTER PROCEDURE sp_UpsertContent
    @Key      NVARCHAR(100),
    @Value    NVARCHAR(MAX),
    @UpdatedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM SiteContent WHERE ContentKey = @Key)
        UPDATE SiteContent
        SET ContentValue = @Value, UpdatedAt = GETUTCDATE(), UpdatedBy = @UpdatedBy
        WHERE ContentKey = @Key;
    ELSE
        INSERT INTO SiteContent (ContentKey, ContentValue, UpdatedBy)
        VALUES (@Key, @Value, @UpdatedBy);
END
GO

-- Add gallery item
CREATE OR ALTER PROCEDURE sp_AddGalleryItem
    @MediaUrl   NVARCHAR(500),
    @MediaType  NVARCHAR(20),
    @Caption    NVARCHAR(300) = '',
    @UploadedBy NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NextOrder INT;
    SELECT @NextOrder = ISNULL(MAX(SortOrder), 0) + 1 FROM Gallery;
    INSERT INTO Gallery (MediaUrl, MediaType, Caption, SortOrder, UploadedBy)
    VALUES (@MediaUrl, @MediaType, @Caption, @NextOrder, @UploadedBy);
    SELECT SCOPE_IDENTITY() AS NewId, @MediaUrl AS Url;
END
GO

-- Add event
CREATE OR ALTER PROCEDURE sp_AddEvent
    @Title       NVARCHAR(300),
    @Location    NVARCHAR(300),
    @EventDate   DATE,
    @EventDay    NVARCHAR(5),
    @EventMonth  NVARCHAR(10),
    @Description NVARCHAR(MAX),
    @Status      NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Events (Title, Location, EventDate, EventDay, EventMonth, Description, Status)
    VALUES (@Title, @Location, @EventDate, @EventDay, @EventMonth, @Description, @Status);
    SELECT SCOPE_IDENTITY() AS NewId;
END
GO

-- Save dance class (upsert)
CREATE OR ALTER PROCEDURE sp_UpsertDanceClass
    @Id          INT = NULL,
    @Name        NVARCHAR(150),
    @Description NVARCHAR(MAX),
    @ImageUrl    NVARCHAR(500) = NULL,
    @Tags        NVARCHAR(300) = NULL,
    @SortOrder   INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @Id IS NOT NULL AND EXISTS (SELECT 1 FROM DanceClasses WHERE Id = @Id)
        UPDATE DanceClasses
        SET Name=@Name, Description=@Description, ImageUrl=@ImageUrl,
            Tags=@Tags, SortOrder=@SortOrder, UpdatedAt=GETUTCDATE()
        WHERE Id = @Id;
    ELSE
        INSERT INTO DanceClasses (Name, Description, ImageUrl, Tags, SortOrder)
        VALUES (@Name, @Description, @ImageUrl, @Tags, @SortOrder);
END
GO

-- Validate admin token
CREATE OR ALTER PROCEDURE sp_ValidateToken
    @Token NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.Id, a.Username
    FROM AuthTokens t
    JOIN AdminUsers a ON t.AdminUserId = a.Id
    WHERE t.Token = @Token
      AND t.ExpiresAt > GETUTCDATE()
      AND a.IsActive = 1;
END
GO

-- Create auth token on login
CREATE OR ALTER PROCEDURE sp_CreateAuthToken
    @AdminUserId INT,
    @Token       NVARCHAR(128),
    @ExpiresAt   DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    -- Clean old tokens for this user
    DELETE FROM AuthTokens WHERE AdminUserId = @AdminUserId AND ExpiresAt < GETUTCDATE();
    -- Insert new
    INSERT INTO AuthTokens (Token, AdminUserId, ExpiresAt) VALUES (@Token, @AdminUserId, @ExpiresAt);
    -- Update last login
    UPDATE AdminUsers SET LastLogin = GETUTCDATE() WHERE Id = @AdminUserId;
END
GO

-- Invalidate token on logout
CREATE OR ALTER PROCEDURE sp_InvalidateToken
    @Token NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM AuthTokens WHERE Token = @Token;
END
GO


-- ══════════════════════════════════════════════════════════════
--  VERIFICATION — Run these to confirm everything was created
-- ══════════════════════════════════════════════════════════════
SELECT
    t.name AS TableName,
    p.rows AS RowCount
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
ORDER BY t.name;

SELECT 'Dashboard Stats' AS Check;
SELECT * FROM vw_DashboardStats;

SELECT 'Dance Classes' AS Check;
SELECT * FROM DanceClasses;

SELECT 'Events' AS Check;
SELECT * FROM Events;

PRINT '✓ Database setup complete. Connect Python backend using the connection string in .env';
GO
