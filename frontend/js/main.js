/* ═══════════════════════════════════════════════
   NRITYA KALA MANDIR — main.js
   Handles: nav, hero, gallery, lightbox, forms, API
   ═══════════════════════════════════════════════ */

const API_BASE = 'http://localhost:8000/api';

/* ──────────────────────────────
   NAV — scroll + mobile toggle
────────────────────────────── */
const navbar      = document.getElementById('navbar');
const navToggle   = document.getElementById('navToggle');
const navLinks    = document.getElementById('navLinks');
const allNavLinks = document.querySelectorAll('.nav-link:not(.nav-admin)');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 60);
  updateActiveNavLink();
});

if (navToggle) navToggle.addEventListener('click', () => navLinks.classList.toggle('open'));

if (navLinks) {
  navLinks.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => navLinks.classList.remove('open'));
  });
}

function updateActiveNavLink() {
  const sections = ['home','about','classes','gallery','events','contact'];
  let current = 'home';
  sections.forEach(id => {
    const el = document.getElementById(id);
    if (el && window.scrollY >= el.offsetTop - 120) current = id;
  });
  allNavLinks.forEach(l => {
    l.classList.toggle('active', l.getAttribute('href') === `#${current}`);
  });
}

/* ──────────────────────────────
   HERO BACKGROUND SLIDER
────────────────────────────── */
let heroIndex = 0;
const heroBg  = document.getElementById('heroSlides'); // was 'heroBgSlider'

function initHeroSlider(images) {
  if (!heroBg || !images || images.length === 0) return;
  heroBg.innerHTML = '';
  images.forEach((src, i) => {
    const div = document.createElement('div');
    div.className = 'hero-slide' + (i === 0 ? ' active' : '');
    div.style.backgroundImage = `url('${src}')`;
    heroBg.appendChild(div);
  });
  setInterval(() => {
    const slides = heroBg.querySelectorAll('.hero-slide');
    if (!slides.length) return;
    slides[heroIndex].classList.remove('active');
    heroIndex = (heroIndex + 1) % slides.length;
    slides[heroIndex].classList.add('active');
  }, 5000);
}

/* ──────────────────────────────
   GALLERY — tabs + lightbox
────────────────────────────── */
const galleryGrid = document.getElementById('galleryGrid');
const lightbox    = document.getElementById('lightbox');
const lbContent   = document.getElementById('lbContent');  // was 'lightboxContent'
const lbClose     = document.getElementById('lbClose');    // was 'lightboxClose'
const lbPrev      = document.getElementById('lbPrev');     // was 'lightboxPrev'
const lbNext      = document.getElementById('lbNext');     // was 'lightboxNext'
const galleryTabs = document.querySelectorAll('.gtab');    // was '.gallery-tab'

let galleryItems  = [];
let lightboxIndex = 0;
let currentTab    = 'photos';

galleryTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    galleryTabs.forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    currentTab = tab.dataset.tab;
    renderGallery();
  });
});

function renderGallery(data) {
  if (data) galleryItems = data;
  if (!galleryGrid) return;
  const filtered = galleryItems.filter(item => item.type === currentTab);
  if (filtered.length === 0) return;

  galleryGrid.innerHTML = filtered.map((item, i) => {
    if (item.type === 'photos') {
      return `<div class="gitem fade-in" data-index="${i}" tabindex="0" role="button" aria-label="View ${item.caption || 'photo'}">
        <img src="${item.url}" alt="${item.caption || 'Gallery image'}" loading="lazy"/>
        <div class="gitem-overlay"><span>View</span></div>
      </div>`;
    } else {
      return `<div class="gitem fade-in" data-index="${i}" tabindex="0" role="button" aria-label="Play ${item.caption || 'video'}">
        <video src="${item.url}" style="width:100%;height:100%;object-fit:cover;" muted preload="metadata"></video>
        <div class="gitem-overlay"><span>▶ Play</span></div>
      </div>`;
    }
  }).join('');

  galleryGrid.querySelectorAll('.gitem').forEach(el => {
    el.addEventListener('click', () => openLightbox(parseInt(el.dataset.index)));
    el.addEventListener('keydown', e => { if (e.key === 'Enter') openLightbox(parseInt(el.dataset.index)); });
  });

  observeFadeIns();
}

function openLightbox(index) {
  const filtered = galleryItems.filter(item => item.type === currentTab);
  lightboxIndex = index;
  if (lightbox) { lightbox.classList.add('open'); document.body.style.overflow = 'hidden'; }
  showLightboxItem(filtered[index]);
}

function showLightboxItem(item) {
  if (!item || !lbContent) return;
  if (item.type === 'photos') {
    lbContent.innerHTML = `<img src="${item.url}" alt="${item.caption || ''}" />`;
  } else {
    lbContent.innerHTML = `<video src="${item.url}" controls autoplay style="max-width:90vw;max-height:85vh;border-radius:4px;"></video>`;
  }
}

function closeLightbox() {
  if (lightbox) { lightbox.classList.remove('open'); document.body.style.overflow = ''; }
  if (lbContent) lbContent.innerHTML = '';
}

if (lbClose)  lbClose.addEventListener('click', closeLightbox);
if (lightbox) lightbox.addEventListener('click', e => { if (e.target === lightbox) closeLightbox(); });

if (lbPrev) lbPrev.addEventListener('click', () => {
  const filtered = galleryItems.filter(i => i.type === currentTab);
  lightboxIndex = (lightboxIndex - 1 + filtered.length) % filtered.length;
  showLightboxItem(filtered[lightboxIndex]);
});

if (lbNext) lbNext.addEventListener('click', () => {
  const filtered = galleryItems.filter(i => i.type === currentTab);
  lightboxIndex = (lightboxIndex + 1) % filtered.length;
  showLightboxItem(filtered[lightboxIndex]);
});

document.addEventListener('keydown', e => {
  if (!lightbox || !lightbox.classList.contains('open')) return;
  if (e.key === 'Escape')     closeLightbox();
  if (e.key === 'ArrowLeft')  lbPrev && lbPrev.click();
  if (e.key === 'ArrowRight') lbNext && lbNext.click();
});

/* ──────────────────────────────
   CONTACT FORM
────────────────────────────── */
const contactForm = document.getElementById('contactForm');
const formOk      = document.getElementById('formOk'); // was 'formSuccess'

if (contactForm) {
  contactForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const btn = contactForm.querySelector('button[type="submit"]');
    btn.textContent = 'Sending...';
    btn.disabled = true;

    const data = {
      firstName: contactForm.firstName.value,
      lastName:  contactForm.lastName.value,
      email:     contactForm.email.value,
      phone:     contactForm.phone.value,
      danceForm: contactForm.danceForm.value,
      message:   contactForm.message.value,
    };

    try {
      const res = await fetch(`${API_BASE}/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });
      if (res.ok) {
        contactForm.reset();
        if (formOk) { formOk.style.display = 'block'; setTimeout(() => formOk.style.display = 'none', 6000); }
      } else {
        alert('Something went wrong. Please try again.');
      }
    } catch {
      // Backend not connected — show success anyway in dev
      contactForm.reset();
      if (formOk) formOk.style.display = 'block';
    }

    btn.textContent = 'Send Message';
    btn.disabled = false;
  });
}

/* ──────────────────────────────
   SCROLL REVEAL
────────────────────────────── */
function observeFadeIns() {
  const els = document.querySelectorAll('.fade-in:not(.visible)');
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); }
    });
  }, { threshold: 0.12 });
  els.forEach(el => obs.observe(el));
}

document.querySelectorAll(
  '.about-grid, .class-card, .event-card, .testi-card, .gitem, .stat-item'
).forEach(el => el.classList.add('fade-in'));

/* ──────────────────────────────
   LOAD DYNAMIC CONTENT FROM API
────────────────────────────── */
async function loadSiteContent() {
  try {
    const res  = await fetch(`${API_BASE}/content`);
    if (!res.ok) return;
    const data = await res.json();

    // About section
    if (data.about) {
      const m = {
        aboutTitle:   document.getElementById('aboutTitle'),
        aboutBody:    document.getElementById('aboutBody'),
        aboutQuoteP:  document.querySelector('.about-quote p'),
        guruImage:    document.getElementById('guruImage'),
        statYears:    document.getElementById('statYears'),
        statStudents: document.getElementById('statStudents'),
        statPerfs:    document.getElementById('statPerfs'),  // was 'statPerformances'
      };
      if (data.about.title    && m.aboutTitle)   m.aboutTitle.textContent    = data.about.title;
      if (data.about.body     && m.aboutBody)    m.aboutBody.innerHTML       = data.about.body;
      if (data.about.quote    && m.aboutQuoteP)  m.aboutQuoteP.textContent   = data.about.quote;
      if (data.about.image    && m.guruImage)    m.guruImage.src             = data.about.image;
      if (data.about.years    && m.statYears)    m.statYears.textContent     = data.about.years;
      if (data.about.students && m.statStudents) m.statStudents.textContent  = data.about.students;
      if (data.about.perfs    && m.statPerfs)    m.statPerfs.textContent     = data.about.perfs;
    }

    // Contact details
    if (data.contact) {
      const contactAddress = document.getElementById('contactAddress');
      const contactPhone   = document.getElementById('contactPhone');
      const contactEmail   = document.getElementById('contactEmail');
      const contactHours   = document.getElementById('contactHours');

      if (data.contact.address && contactAddress) contactAddress.textContent = data.contact.address;
      if (data.contact.phone   && contactPhone) {
        contactPhone.textContent = data.contact.phone;
        contactPhone.href = `tel:${data.contact.phone}`;
      }
      if (data.contact.email   && contactEmail) {
        contactEmail.textContent = data.contact.email;
        contactEmail.href = `mailto:${data.contact.email}`;
      }
      if (data.contact.hours   && contactHours) contactHours.textContent = data.contact.hours;

      const socials = {
        socialFB: data.contact.facebook,
        socialIG: data.contact.instagram,
        socialYT: data.contact.youtube,
        footerFB: data.contact.facebook,
        footerIG: data.contact.instagram,
        footerYT: data.contact.youtube,
      };
      Object.entries(socials).forEach(([id, val]) => {
        const el = document.getElementById(id);
        if (el && val) el.href = val;
      });
    }

    // Hero images
    if (data.heroImages && data.heroImages.length) {
      initHeroSlider(data.heroImages);
    }

    // Gallery
    if (data.gallery && data.gallery.length) {
      renderGallery(data.gallery);
    }

    // Classes — use class-img-wrap / class-body to match CSS
    if (data.classes && data.classes.length) {
      const grid = document.getElementById('classesGrid');
      if (grid) {
        grid.innerHTML = data.classes.map(c => {
          const img  = c.image_url || c.image || ''; // handle both field names
          const tags = (c.tags || []).map(t => `<span>${t}</span>`).join('');
          return `
          <div class="class-card fade-in">
            <div class="class-img-wrap">
              <img src="${img}" alt="${c.name}" loading="lazy"/>
              <div class="class-img-overlay">
                <a href="#contact" class="btn btn-white btn-sm">Enroll</a>
              </div>
            </div>
            <div class="class-body">
              <h3>${c.name}</h3>
              <p>${c.description}</p>
              <div class="class-tags">${tags}</div>
            </div>
          </div>`;
        }).join('');
      }
    }

    // Events — match HTML structure (event-date-box, eday, emon, event-badge)
    if (data.events && data.events.length) {
      const list = document.getElementById('eventsList');
      if (list) {
        list.innerHTML = data.events.map(ev => `
        <div class="event-card fade-in">
          <div class="event-date-box">
            <span class="eday">${ev.day}</span>
            <span class="emon">${ev.month}</span>
          </div>
          <div class="event-info">
            <h3>${ev.title}</h3>
            <p class="eloc">📍 ${ev.location}</p>
            <p class="edesc">${ev.description || ''}</p>
          </div>
          <span class="event-badge ${ev.status}">${ev.status.charAt(0).toUpperCase() + ev.status.slice(1)}</span>
        </div>`).join('');
      }
    }

    observeFadeIns();
  } catch (err) {
    console.info('API not connected. Showing static content.', err);
  }
}

/* ──────────────────────────────
   INIT
────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  observeFadeIns();
  loadSiteContent();
});