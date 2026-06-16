"""
Nritya Kala Mandir — Password Hash Utility
Run this to generate a bcrypt hash for any password.
Then paste the hash into AdminUsers table in SSMS.

Usage:
    python hash_password.py
"""

import bcrypt

def hash_password(password: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

if __name__ == "__main__":
    print("=" * 55)
    print("  Nritya Kala Mandir — Password Hash Generator")
    print("=" * 55)
    password = input("\nEnter new password: ").strip()
    if not password:
        print("❌ Password cannot be empty.")
        exit(1)

    hashed = hash_password(password)
    print(f"\n✓ Bcrypt Hash (copy this):\n")
    print(f"  {hashed}")
    print(f"\nRun this SQL in SSMS to update admin password:")
    print(f"""
  UPDATE AdminUsers
  SET PasswordHash = '{hashed}'
  WHERE Username = 'admin';
""")

    # Verify it works
    verify = verify_password(password, hashed)
    print(f"✓ Verification: {'PASS' if verify else 'FAIL'}")
    print("=" * 55)
