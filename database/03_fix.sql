-- ═══════════════════════════════════════════════════════
--  NRITYA KALA MANDIR — Fix Script
--  Run this in SSMS to fix the 4 errors from setup
-- ═══════════════════════════════════════════════════════

USE NrityaKalaMandir;
GO

-- Fix 1: Remove ORDER BY from vw_ActiveGallery (not allowed in views)
CREATE OR ALTER VIEW vw_ActiveGallery AS
    SELECT Id, MediaUrl, MediaType, Caption, SortOrder, UploadedAt
    FROM Gallery
    WHERE IsActive = 1;
GO

-- Fix 2: Verification query — RowCount is a reserved word, use [RowCount]
SELECT
    t.name          AS TableName,
    p.rows          AS [RowCount]
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
ORDER BY t.name;
GO

-- Fix 3: Check labels — SELECT string literals need an alias, not a bare label
SELECT 'Dashboard Stats' AS [Check];
SELECT * FROM vw_DashboardStats;

SELECT 'Dance Classes' AS [Check];
SELECT * FROM DanceClasses;

SELECT 'Events' AS [Check];
SELECT * FROM Events;

PRINT '✓ All fixes applied. Database is ready.';
GO
