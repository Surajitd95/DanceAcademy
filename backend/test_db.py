"""
Nritya Kala Mandir — PostgreSQL Connection Test
Run: python test_db.py
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "nritya_kala_mandir")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "")

print("=" * 55)
print("  Nritya Kala Mandir — PostgreSQL Connection Test")
print("=" * 55)
print(f"\n  Host    : {DB_HOST}:{DB_PORT}")
print(f"  Database: {DB_NAME}")
print(f"  User    : {DB_USER}\n")

try:
    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
        user=DB_USER, password=DB_PASS, connect_timeout=5
    )
    cur = conn.cursor()

    cur.execute("SELECT version();")
    version = cur.fetchone()[0].split(',')[0]
    print(f"✓ Connected! {version}\n")

    # Check tables
    cur.execute("""
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename;
    """)
    tables = [r[0] for r in cur.fetchall()]
    expected = ['admin_users','auth_tokens','dance_classes','enquiries',
                'events','gallery','hero_banners','site_content','testimonials']
    print(f"✓ Tables found: {len(tables)}/9")
    for t in expected:
        status = "✓" if t in tables else "❌"
        print(f"  {status} {t}")

    # Check seed data
    cur.execute("SELECT username FROM admin_users WHERE is_active = TRUE")
    admins = cur.fetchall()
    print(f"\n✓ Admin users : {len(admins)}")
    for a in admins:
        print(f"  - {a[0]}")

    cur.execute("SELECT COUNT(*) FROM dance_classes")
    print(f"✓ Dance classes: {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM events")
    print(f"✓ Events       : {cur.fetchone()[0]}")

    conn.close()
    print("\n" + "=" * 55)
    print("  ✓ ALL GOOD — run: uvicorn main:app --reload")
    print("=" * 55)

except psycopg2.OperationalError as e:
    print(f"❌ Connection failed:\n  {e}")
    print("\nTroubleshooting:")
    print("  1. Make sure PostgreSQL service is running")
    print("     → Win+R → services.msc → PostgreSQL → Start")
    print("  2. Check DB_PASSWORD in your .env file")
    print("  3. Make sure you created the database 'nritya_kala_mandir' in pgAdmin")
