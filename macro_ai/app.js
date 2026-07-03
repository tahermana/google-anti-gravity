/* ============================================================
   MACRO AI — app.js
   Full SPA logic: navigation, ring chart, charts, modal, etc.
   ============================================================ */

/* ─── STATE ─── */
const state = {
  goal: 2000,
  eaten: 1160,
  burned: 320,
  protein: { current: 82, target: 150 },
  carbs:   { current: 145, target: 200 },
  fat:     { current: 38, target: 83 },
  water: 1.2,
  steps: 7241,
  meals: [
    { name: 'Oatmeal with banana', type: 'Breakfast', time: '8:15 AM', kcal: 380, emoji: '🥣', bg: '#1a3a6b', protein: 12, carbs: 68, fat: 6 },
    { name: 'Black coffee',        type: 'Breakfast', time: '8:30 AM', kcal: 5,   emoji: '☕', bg: '#2a1a1a', protein: 0, carbs: 0, fat: 0 },
    { name: 'Grilled chicken salad', type: 'Lunch', time: '1:00 PM', kcal: 420, emoji: '🥗', bg: '#1a3a1a', protein: 45, carbs: 22, fat: 14 },
    { name: 'Whole grain bread',   type: 'Lunch', time: '1:05 PM', kcal: 180, emoji: '🍞', bg: '#3a2a1a', protein: 6, carbs: 34, fat: 2 },
    { name: 'Mixed nuts',          type: 'Snack', time: '3:30 PM', kcal: 175, emoji: '🥜', bg: '#3a1a1a', protein: 5, carbs: 7, fat: 15 },
  ]
};

/* ─── GREETING ─── */
function setGreeting() {
  const hour = new Date().getHours();
  const el = document.getElementById('greeting-text');
  if (!el) return;
  if (hour < 12) el.textContent = 'Good morning,';
  else if (hour < 18) el.textContent = 'Good afternoon,';
  else el.textContent = 'Good evening,';
}

/* ─── RING CHART (SVG Dashoffset) ─── */
function updateRing() {
  const circumference = 2 * Math.PI * 50; // ~314.16
  const kcalLeft = Math.max(0, state.goal - state.eaten + state.burned);

  document.getElementById('kcal-left').textContent  = kcalLeft.toLocaleString();
  document.getElementById('val-goal').textContent   = state.goal.toLocaleString();
  document.getElementById('val-eaten').textContent  = state.eaten.toLocaleString();
  document.getElementById('val-burned').textContent = state.burned.toLocaleString();

  const eatenPct  = Math.min(state.eaten / state.goal, 1);
  const burnedPct = Math.min(state.burned / state.goal, 1);

  // eaten arc offset (full circle minus arc)
  const eatenArc = eatenPct * circumference;
  document.getElementById('ring-eaten-arc').style.strokeDashoffset = circumference - eatenArc;

  // burned arc stacked on top
  const burnedArc = burnedPct * circumference;
  document.getElementById('ring-burned-arc').style.strokeDashoffset = circumference - burnedArc;
}

/* ─── MACROS ─── */
function updateMacros() {
  document.getElementById('m-protein').textContent = state.protein.current + 'g';
  document.getElementById('m-carbs').textContent   = state.carbs.current + 'g';
  document.getElementById('m-fat').textContent     = state.fat.current + 'g';
}

/* ─── NAVIGATION ─── */
const pages   = document.querySelectorAll('.page');
const navBtns = document.querySelectorAll('.nav-btn');

function navigateTo(pageId) {
  pages.forEach(p => p.classList.remove('active'));
  navBtns.forEach(b => b.classList.remove('active'));

  const targetPage = document.getElementById('page-' + pageId);
  const targetBtn  = document.querySelector(`[data-page="${pageId}"]`);

  if (targetPage) targetPage.classList.add('active');
  if (targetBtn)  targetBtn.classList.add('active');

  // lazy-init charts
  if (pageId === 'log')   { initWeeklyChart(); initMacroPie(); initCalendar(); }
  if (pageId === 'stats') { initWeightChart(); }
}

navBtns.forEach(btn => {
  btn.addEventListener('click', () => navigateTo(btn.dataset.page));
});

// Profile avatar shortcut
document.getElementById('btn-profile-nav')?.addEventListener('click', () => navigateTo('profile'));
document.getElementById('btn-scan')?.addEventListener('click', () => navigateTo('scan'));

/* ─── ADD MEAL MODAL ─── */
const modalOverlay = document.getElementById('add-meal-modal');
const modalClose   = document.getElementById('modal-close');
const modalSubmit  = document.getElementById('modal-submit');

document.getElementById('btn-add-meal')?.addEventListener('click', () => {
  modalOverlay.classList.remove('hidden');
});

modalClose?.addEventListener('click', closeModal);
modalOverlay?.addEventListener('click', e => {
  if (e.target === modalOverlay) closeModal();
});

function closeModal() {
  modalOverlay.classList.add('hidden');
}

modalSubmit?.addEventListener('click', () => {
  const name   = document.getElementById('meal-name-input').value.trim();
  const kcal   = parseInt(document.getElementById('meal-kcal-input').value) || 0;
  const type   = document.getElementById('meal-type-select').value;
  const protein = parseInt(document.getElementById('meal-protein-input').value) || 0;
  const carbs   = parseInt(document.getElementById('meal-carbs-input').value) || 0;
  const fat     = parseInt(document.getElementById('meal-fat-input').value) || 0;

  if (!name) { showToast('Please enter a food name'); return; }

  const emojis = { Breakfast: '🍳', Lunch: '🥙', Dinner: '🍽️', Snack: '🍎' };
  const bgs    = { Breakfast: '#1a3a1a', Lunch: '#1a2a3a', Dinner: '#2a1a3a', Snack: '#3a2a1a' };

  const meal = {
    name, type, kcal, protein, carbs, fat,
    time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    emoji: emojis[type] || '🍴',
    bg: bgs[type] || '#2a2a2a'
  };

  state.meals.push(meal);
  state.eaten     += kcal;
  state.protein.current += protein;
  state.carbs.current   += carbs;
  state.fat.current     += fat;

  renderMeals();
  updateRing();
  updateMacros();
  closeModal();
  clearModalInputs();
  showToast(`✓ ${name} added`);
});

function clearModalInputs() {
  ['meal-name-input','meal-kcal-input','meal-protein-input','meal-carbs-input','meal-fat-input'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
}

/* ─── RENDER MEALS ─── */
function renderMeals() {
  const container = document.getElementById('meals-list');
  if (!container) return;

  const groups = {};
  const typeOrder = ['Breakfast','Lunch','Dinner','Snack'];
  const typeEmoji = { Breakfast: '🌅', Lunch: '☀️', Dinner: '🌙', Snack: '🍎' };

  state.meals.forEach(m => {
    if (!groups[m.type]) groups[m.type] = [];
    groups[m.type].push(m);
  });

  container.innerHTML = '';

  typeOrder.forEach(type => {
    if (!groups[type]) return;
    const groupDiv = document.createElement('div');
    groupDiv.className = 'meal-group';

    const label = document.createElement('span');
    label.className = 'meal-time-label';
    label.textContent = `${typeEmoji[type] || '🍴'} ${type}`;
    groupDiv.appendChild(label);

    groups[type].forEach(meal => {
      const item = document.createElement('div');
      item.className = 'meal-item';
      item.innerHTML = `
        <div class="meal-icon" style="background:${meal.bg}">${meal.emoji}</div>
        <div class="meal-info">
          <p class="meal-name">${meal.name}</p>
          <p class="meal-meta">${meal.type} · ${meal.time}</p>
        </div>
        <span class="meal-kcal">${meal.kcal} kcal</span>
      `;
      groupDiv.appendChild(item);
    });

    container.appendChild(groupDiv);
  });
}

/* ─── SCAN PAGE ─── */
let scanDone = false;

document.getElementById('btn-fake-scan')?.addEventListener('click', () => {
  if (scanDone) return;
  const btn = document.getElementById('btn-fake-scan');
  btn.textContent = '⏳ Scanning...';
  btn.disabled = true;

  setTimeout(() => {
    document.getElementById('scan-result').classList.remove('hidden');
    btn.textContent = '📷 Scan now';
    btn.disabled = false;
    scanDone = true;
  }, 1800);
});

document.getElementById('btn-add-scanned')?.addEventListener('click', () => {
  state.meals.push({
    name: 'Grilled Chicken Breast', type: 'Dinner',
    time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    kcal: 165, emoji: '🍗', bg: '#1a3a1a', protein: 31, carbs: 0, fat: 4
  });
  state.eaten += 165;
  state.protein.current += 31;
  state.fat.current += 4;

  renderMeals();
  updateRing();
  updateMacros();

  document.getElementById('scan-result').classList.add('hidden');
  scanDone = false;

  navigateTo('home');
  showToast('✓ Grilled Chicken Breast added');
});

document.getElementById('btn-manual-search')?.addEventListener('click', () => {
  document.getElementById('add-meal-modal').classList.remove('hidden');
  navigateTo('home');
});

/* ─── CALENDAR ─── */
let calInit = false;
function initCalendar() {
  if (calInit) return;
  calInit = true;

  const container = document.getElementById('cal-days');
  if (!container) return;

  const today = new Date();
  const days  = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  for (let i = 6; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);

    const div = document.createElement('div');
    div.className = 'cal-day' + (i === 0 ? ' today' : '') + (Math.random() > 0.4 && i !== 0 ? ' logged' : '');
    div.innerHTML = `
      <span class="cal-day-name">${days[d.getDay()]}</span>
      <span class="cal-day-num">${d.getDate()}</span>
      <span class="cal-dot"></span>
    `;
    container.appendChild(div);
  }
}

/* ─── CHARTS ─── */
let weeklyChartInst = null;
let macroPieInst    = null;
let weightChartInst = null;

const chartDefaults = {
  color: '#8e8e9a',
  font: { family: 'Inter' }
};

function initWeeklyChart() {
  const canvas = document.getElementById('weekly-chart');
  if (!canvas || weeklyChartInst) return;

  const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  const data   = [1920, 2100, 1750, 1980, 2050, 1840, 1160];

  weeklyChartInst = new Chart(canvas, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Calories',
        data,
        backgroundColor: data.map((v, i) =>
          i === 6 ? 'rgba(230,57,70,0.85)' : 'rgba(230,57,70,0.3)'
        ),
        borderColor: 'rgba(230,57,70,0.8)',
        borderWidth: 1,
        borderRadius: 6,
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { bodyColor: '#f0f0f5', titleColor: '#8e8e9a', backgroundColor: '#1c1c21' }
      },
      scales: {
        x: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#8e8e9a', font: { family: 'Inter' } } },
        y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#8e8e9a', font: { family: 'Inter' } } }
      }
    }
  });
}

function initMacroPie() {
  const canvas = document.getElementById('macro-pie');
  if (!canvas || macroPieInst) return;

  macroPieInst = new Chart(canvas, {
    type: 'doughnut',
    data: {
      labels: ['Protein', 'Carbs', 'Fat'],
      datasets: [{
        data: [30, 53, 17],
        backgroundColor: ['#e63946', '#f4a261', '#e9c46a'],
        borderColor: '#161619',
        borderWidth: 3,
        hoverOffset: 6
      }]
    },
    options: {
      responsive: false,
      plugins: {
        legend: { display: false },
        tooltip: { bodyColor: '#f0f0f5', backgroundColor: '#1c1c21' }
      },
      cutout: '65%'
    }
  });
}

function initWeightChart() {
  const canvas = document.getElementById('weight-chart');
  if (!canvas || weightChartInst) return;

  const labels = ['May 1','May 8','May 15','May 22','May 29','Today'];
  const data   = [80.2, 79.8, 79.1, 78.6, 78.2, 77.8];

  weightChartInst = new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        label: 'Weight (kg)',
        data,
        borderColor: '#e63946',
        backgroundColor: 'rgba(230,57,70,0.1)',
        borderWidth: 2.5,
        pointBackgroundColor: '#e63946',
        pointRadius: 4,
        tension: 0.4,
        fill: true
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: { bodyColor: '#f0f0f5', titleColor: '#8e8e9a', backgroundColor: '#1c1c21' }
      },
      scales: {
        x: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#8e8e9a', font: { family:'Inter', size:11 } } },
        y: { grid: { color: 'rgba(255,255,255,0.04)' }, ticks: { color: '#8e8e9a', font: { family:'Inter', size:11 } } }
      }
    }
  });
}

/* ─── TOGGLES ─── */
document.querySelectorAll('.toggle').forEach(t => {
  t.addEventListener('click', () => t.classList.toggle('active'));
});

/* ─── TOAST ─── */
function showToast(msg) {
  let toast = document.querySelector('.toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2800);
}

/* ─── INIT ─── */
function init() {
  setGreeting();
  updateRing();
  updateMacros();

  // Animate ring on load
  setTimeout(() => {
    document.getElementById('ring-eaten-arc').style.transition = 'stroke-dashoffset 1.4s cubic-bezier(0.4,0,0.2,1)';
    document.getElementById('ring-burned-arc').style.transition = 'stroke-dashoffset 1.4s cubic-bezier(0.4,0,0.2,1)';
  }, 100);
}

document.addEventListener('DOMContentLoaded', init);
