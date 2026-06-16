# 🎭 Nritya Kala Mandir — Dance Academy Website

A fully dynamic dance academy website with admin panel, image/video upload, SEO, and cloud storage.

---

## 📁 Project Structure

```
dance-academy/
├── frontend/
│   ├── index.html          ← Main website
│   ├── css/style.css       ← All styles
│   ├── js/main.js          ← Frontend logic
│   ├── images/             ← Put your images here
│   └── admin/
│       ├── login.html      ← Admin login
│       └── dashboard.html  ← Admin panel
├── backend/
│   ├── main.py             ← FastAPI backend
│   ├── requirements.txt    ← Python packages
│   └── .env.example        ← Environment config template
└── README.md
```

---

## 🚀 STEP 1 — Open in VS Code

1. Open VS Code
2. File → Open Folder → select `dance-academy/`
3. Install the **Live Server** extension (search "Live Server" by Ritwick Dey)

---

## 🐍 STEP 2 — Set Up Python Backend

Open the VS Code terminal (`Ctrl + `` ` ``):

```bash
# Go to backend folder
cd backend

# Create virtual environment
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install packages
pip install -r requirements.txt

# Copy env file
cp .env.example .env
# Then edit .env with your values (see Step 5 for R2 setup)

# Run the server
uvicorn main:app --reload --port 8000
```

The API will be running at: `http://localhost:8000`
API docs (auto-generated): `http://localhost:8000/docs`

---

## 🌐 STEP 3 — Open the Website

1. Right-click `frontend/index.html` in VS Code
2. Click **"Open with Live Server"**
3. Website opens at `http://127.0.0.1:5500`

**Admin panel:** `http://127.0.0.1:5500/admin/login.html`
- Dev username: `admin`
- Dev password: `admin123`

---

## 🖼️ STEP 4 — Add Your Photos

Replace placeholder images in `frontend/images/` with your real photos:
- `hero-placeholder.jpg` → Main hero image (1920×1080px)
- `guru-placeholder.jpg` → Guru/founder photo (600×750px)
- `bharatanatyam-placeholder.jpg` → Class image (800×600px)
- `kuchipudi-placeholder.jpg` → Class image
- `mohiniyattam-placeholder.jpg` → Class image
- `gallery-1.jpg` through `gallery-6.jpg` → Gallery photos

---

## ☁️ STEP 5 — Cloudflare R2 Storage Setup

1. Go to [cloudflare.com](https://cloudflare.com) → Sign up (free)
2. Dashboard → **R2 Object Storage** → Create bucket
   - Bucket name: `dance-academy-media`
   - Make it **public**
3. R2 → Manage API Tokens → Create Token
   - Permission: **Object Read & Write**
   - Copy Access Key ID and Secret Access Key
4. In your `.env` file:
   ```
   R2_ACCOUNT_ID=your_account_id_from_cloudflare
   R2_ACCESS_KEY=your_access_key
   R2_SECRET_KEY=your_secret_key
   R2_BUCKET=dance-academy-media
   R2_PUBLIC_URL=https://pub-XXXX.r2.dev  ← from R2 bucket settings
   ```

---

## 🌍 STEP 6 — Buy Domain (Namecheap)

1. Go to [namecheap.com](https://namecheap.com)
2. Search for your academy name, e.g. `nrityakalamandir.com`
3. Buy it (~$10-12/year for .com)
4. You'll set up DNS after deploying

---

## 🚢 STEP 7 — Deploy

### Frontend → Vercel (Free)
```bash
# Install Vercel CLI
npm install -g vercel

# From frontend folder
cd frontend
vercel deploy
# Follow prompts, it gives you a URL
```

### Backend → Railway ($5/month)
1. Go to [railway.app](https://railway.app) → Sign up with GitHub
2. New Project → Deploy from GitHub repo
3. Select your repo, set root to `backend/`
4. Add environment variables from your `.env`
5. Railway gives you a URL like `https://xxx.railway.app`

### Connect them
In `frontend/js/main.js` and `frontend/admin/dashboard.html`, change:
```js
const API_BASE = 'https://xxx.railway.app/api';  // your Railway URL
```

### Connect Domain
In Namecheap → DNS:
- Point `@` and `www` to Vercel's IP/CNAME
- Add API subdomain: `api.yourdomain.com` → Railway URL

---

## 🔍 STEP 8 — SEO Setup

### Google Search Console
1. Go to [search.google.com/search-console](https://search.google.com/search-console)
2. Add your domain, verify ownership
3. Submit sitemap: `https://yourdomain.com/sitemap.xml`

### Google Business Profile
1. Go to [business.google.com](https://business.google.com)
2. Add your academy (this is the #1 thing for local search!)
3. Fill in: name, address, phone, hours, photos

### Update Meta Tags in index.html
Replace all instances of:
- `yourdomain.com` → your actual domain
- `Durgapur, West Bengal` → your actual location
- Phone/email placeholders

---

## 📞 Admin Panel Features

| Feature | What you can do |
|---------|----------------|
| About Section | Edit title, body text, quote, stats |
| Guru Photo | Upload photo directly |
| Dance Classes | Add/remove classes, upload images |
| Gallery | Upload photos & videos (drag & drop) |
| Hero Banners | Upload full-screen slideshow images |
| Events | Add upcoming performances |
| Contact Info | Edit address, phone, social links |
| Enquiries | View all form submissions, export CSV |

---

## 🔐 Security Checklist Before Going Live

- [ ] Change `ADMIN_PASSWORD` in `.env` to something strong
- [ ] Change `SECRET_KEY` in `.env` to a random 64-char string
- [ ] Set `allow_origins` in `main.py` to your actual domain only
- [ ] Enable HTTPS (automatic with Vercel + Railway)
- [ ] Keep `.env` out of git (already in `.gitignore`)

---

## 📱 What's Next (Optional Enhancements)

- **Testimonials editor** in admin panel
- **WhatsApp chat button** (floating)
- **Instagram feed** embed
- **Online fee payment** integration (Razorpay)
- **Student portal** with attendance tracking
