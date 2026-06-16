/* ═══════════════════════════════════════════════
   NRITYA KALA MANDIR — main.js
   Handles: nav, hero, gallery, lightbox, forms, API
   ═══════════════════════════════════════════════ */

const API_BASE = 'http://localhost:8000/api'; // Change to your deployed API URL

/* ──────────────────────────────
   NAV — scroll + mobile toggle
────────────────────────────── */
const navbar    = document.getElementById('navbar');
const navToggle = document.getElementById('navToggle');
const navLinks  = document.getElementById('navLinks');
const allNavLinks = document.querySelectorAll('.nav-link:not(.nav-admin)');

window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 60);
  updateActiveNavLink();
});

navToggle.addEventListener('click', () => {
  navLinks.classList.toggle('open');
});

// Close mobile nav on link click
navLinks.querySelectorAll('a').forEach(a => {
  a.addEventListener('click', () => navLinks.classList.remove('open'));
});

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
let heroImages  = [];
let heroIndex   = 0;
const heroBg    = document.getElementById('heroBgSlider');

function initHeroSlider(images) {
  if (!images || images.length === 0) return;
  heroImages = images;
  heroBg.innerHTML = '';
  images.forEach((src, i) => {
    const div = document.createElement('div');
    div.className = 'hero-slide' + (i === 0 ? ' active' : '');
    div.style.backgroundImage = `url('${src}')`;
    heroBg.appendChild(div);
  });
  setInterval(() => {
    const slides = heroBg.querySelectorAll('.hero-slide');
    slides[heroIndex].classList.remove('active');
    heroIndex = (heroIndex + 1) % slides.length;
    slides[heroIndex].classList.add('active');
  }, 5000);
}

/* ──────────────────────────────
   GALLERY — tabs + lightbox
────────────────────────────── */
const galleryGrid  = document.getElementById('galleryGrid');
const lightbox     = document.getElementById('lightbox');
const lightboxContent = document.getElementById('lightboxContent');
const lightboxClose = document.getElementById('lightboxClose');
const lightboxPrev = document.getElementById('lightboxPrev');
const lightboxNext = document.getElementById('lightboxNext');
const galleryTabs  = document.querySelectorAll('.gallery-tab');

let galleryItems   = [];
let lightboxIndex  = 0;
let currentTab     = 'photos';

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
  const filtered = galleryItems.filter(item => item.type === currentTab);

  if (filtered.length === 0) {
    // Show placeholder items
    return;
  }

  galleryGrid.innerHTML = filtered.map((item, i) => {
    if (item.type === 'photos') {
      return `<div class="gallery-item photo-item fade-in" data-index="${i}" tabindex="0" role="button" aria-label="View ${item.caption || 'photo'}">
        <img src="${item.url}" alt="${item.caption || 'Gallery image'}" loading="lazy"/>
        <div class="gallery-item-overlay"><span>View</span></div>
      </div>`;
    } else {
      return `<div class="gallery-item video-item fade-in" data-index="${i}" tabindex="0" role="button" aria-label="Play ${item.caption || 'video'}">
        <div class="video-thumb" style="background:#0D0F1A;height:100%;display:flex;align-items:center;justify-content:center;">
          <video src="${item.url}" style="width:100%;height:100%;object-fit:cover;" muted preload="metadata"></video>
          <div class="play-icon" style="position:absolute;font-size:3rem;color:rgba(201,168,76,0.9);pointer-events:none;">▶</div>
        </div>
        <div class="gallery-item-overlay"><span>Play</span></div>
      </div>`;
    }
  }).join('');

  // Bind click
  galleryGrid.querySelectorAll('.gallery-item').forEach(el => {
    el.addEventListener('click', () => openLightbox(parseInt(el.dataset.index)));
    el.addEventListener('keydown', e => { if (e.key === 'Enter') openLightbox(parseInt(el.dataset.index)); });
  });

  observeFadeIns();
}

function openLightbox(index) {
  const filtered = galleryItems.filter(item => item.type === currentTab);
  lightboxIndex = index;
  lightbox.classList.add('open');
  document.body.style.overflow = 'hidden';
  showLightboxItem(filtered[index]);
}

function showLightboxItem(item) {
  if (!item) return;
  if (item.type === 'photos') {
    lightboxContent.innerHTML = `<img src="${item.url}" alt="${item.caption || ''}" />`;
  } else {
    lightboxContent.innerHTML = `<video src="${item.url}" controls autoplay style="max-width:90vw;max-height:85vh;border-radius:4px;"></video>`;
  }
}

function closeLightbox() {
  lightbox.classList.remove('open');
  document.body.style.overflow = '';
  lightboxContent.innerHTML = '';
}

lightboxClose.addEventListener('click', closeLightbox);
lightbox.addEventListener('click', e => { if (e.target === lightbox) closeLightbox(); });

lightboxPrev.addEventListener('click', () => {
  const filtered = galleryItems.filter(i => i.type === currentTab);
  lightboxIndex = (lightboxIndex - 1 + filtered.length) % filtered.length;
  showLightboxItem(filtered[lightboxIndex]);
});
lightboxNext.addEventListener('click', () => {
  const filtered = galleryItems.filter(i => i.type === currentTab);
  lightboxIndex = (lightboxIndex + 1) % filtered.length;
  showLightboxItem(filtered[lightboxIndex]);
});
document.addEventListener('keydown', e => {
  if (!lightbox.classList.contains('open')) return;
  if (e.key === 'Escape') closeLightbox();
  if (e.key === 'ArrowLeft') lightboxPrev.click();
  if (e.key === 'ArrowRight') lightboxNext.click();
});

/* ──────────────────────────────
   CONTACT FORM
────────────────────────────── */
const contactForm   = document.getElementById('contactForm');
const formSuccess   = document.getElementById('formSuccess');

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
      formSuccess.style.display = 'block';
      setTimeout(() => formSuccess.style.display = 'none', 6000);
    } else {
      alert('Something went wrong. Please try again.');
    }
  } catch {
    // Backend not connected yet — show success anyway in dev
    contactForm.reset();
    formSuccess.style.display = 'block';
  }

  btn.textContent = 'Send Message';
  btn.disabled = false;
});

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

// Add fade-in to key elements
document.querySelectorAll(
  '.about-grid, .class-card, .event-card, .testimonial-card, .gallery-item, .stat-card'
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
      if (data.about.title)   document.getElementById('aboutTitle').textContent   = data.about.title;
      if (data.about.body)    document.getElementById('aboutBody').innerHTML       = data.about.body;
      if (data.about.quote)   document.querySelector('.about-quote p').textContent = data.about.quote;
      if (data.about.image)   document.getElementById('guruImage').src             = data.about.image;
      if (data.about.years)   document.getElementById('statYears').textContent      = data.about.years;
      if (data.about.students)document.getElementById('statStudents').textContent   = data.about.students;
      if (data.about.perfs)   document.getElementById('statPerformances').textContent = data.about.perfs;
    }

    // Contact details
    if (data.contact) {
      if (data.contact.address) document.getElementById('contactAddress').textContent = data.contact.address;
      if (data.contact.phone)   {
        document.getElementById('contactPhone').textContent = data.contact.phone;
        document.getElementById('contactPhone').href = `tel:${data.contact.phone}`;
      }
      if (data.contact.email)   {
        document.getElementById('contactEmail').textContent = data.contact.email;
        document.getElementById('contactEmail').href = `mailto:${data.contact.email}`;
      }
      if (data.contact.hours)   document.getElementById('contactHours').textContent = data.contact.hours;
      if (data.contact.facebook)  document.getElementById('socialFB').href = data.contact.facebook;
      if (data.contact.instagram) document.getElementById('socialIG').href = data.contact.instagram;
      if (data.contact.youtube)   document.getElementById('socialYT').href = data.contact.youtube;
    }

    // Hero images
    if (data.heroImages && data.heroImages.length) {
      initHeroSlider(data.heroImages);
    }

    // Gallery
    if (data.gallery && data.gallery.length) {
      renderGallery(data.gallery);
    }

    // Classes
    if (data.classes && data.classes.length) {
      document.getElementById('classesGrid').innerHTML = data.classes.map(c => `
        <div class="class-card fade-in">
          <div class="class-card-image">
            <img src="${c.image}" alt="${c.name}" loading="lazy"/>
            <div class="class-card-overlay"><a href="#contact" class="btn btn-gold btn-sm">Enroll</a></div>
          </div>
          <div class="class-card-body">
            <h3 class="class-name">${c.name}</h3>
            <p class="class-desc">${c.description}</p>
            <div class="class-meta">
              ${c.tags.map(t => `<span class="class-tag">${t}</span>`).join('')}
            </div>
          </div>
        </div>
      `).join('');
    }

    // Events
    if (data.events && data.events.length) {
      document.getElementById('eventsList').innerHTML = data.events.map(ev => `
        <div class="event-card fade-in">
          <div class="event-date">
            <span class="event-day">${ev.day}</span>
            <span class="event-month">${ev.month}</span>
          </div>
          <div class="event-info">
            <h3 class="event-title">${ev.title}</h3>
            <p class="event-location">📍 ${ev.location}</p>
            <p class="event-desc">${ev.description}</p>
          </div>
          <div class="event-status ${ev.status}">${ev.status.charAt(0).toUpperCase() + ev.status.slice(1)}</div>
        </div>
      `).join('');
    }

    observeFadeIns();
  } catch {
    // API not running — site displays with static placeholder content
    console.info('API not connected. Showing static content.');
  }
}

/* ──────────────────────────────
   INIT
────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  observeFadeIns();
  loadSiteContent();
});
