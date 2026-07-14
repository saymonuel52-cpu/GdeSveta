#!/bin/bash
echo "🎨 Улучшаю интерфейс и добавляю загруженность..."

cp style.css style.css.backup.ui.$(date +%s)
cp app.js app.js.backup.ui.$(date +%s)
echo "💾 Бэкапы созданы"

# 1. Обновляем стили
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: linear-gradient(180deg, #fef9f9 0%, #f5f5f7 100%);
  color: #333;
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
  min-height: 100vh;
}

header {
  background: linear-gradient(135deg, #ff6b9d 0%, #ff8e53 100%);
  color: white;
  padding: 20px 15px;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 4px 20px rgba(255, 107, 157, 0.3);
  border-radius: 0 0 20px 20px;
}

header h1 {
  text-align: center;
  font-size: 22px;
  margin-bottom: 12px;
  font-weight: 700;
  letter-spacing: 0.5px;
}

nav { display: flex; gap: 8px; }

.nav-btn {
  flex: 1;
  padding: 10px 8px;
  border: none;
  background: rgba(255,255,255,0.25);
  color: white;
  border-radius: 25px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.nav-btn.active {
  background: white;
  color: #ff6b9d;
  font-weight: 700;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.nav-btn:active { transform: scale(0.95); }

main { padding: 15px; }
.tab-content { display: none; animation: fadeIn 0.3s ease; }
.tab-content.active { display: block; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* === КАЛЕНДАРЬ === */
.calendar-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 15px;
  background: white;
  padding: 12px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.calendar-controls button {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  border: none;
  font-size: 18px;
  color: white;
  cursor: pointer;
  padding: 8px 14px;
  border-radius: 10px;
  font-weight: bold;
  transition: all 0.2s;
}

.calendar-controls button:active { transform: scale(0.95); }

.calendar-controls h2 {
  font-size: 17px;
  flex: 1;
  text-align: center;
  font-weight: 600;
  color: #333;
}

.small-btn {
  font-size: 12px !important;
  padding: 6px 12px !important;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  background: white;
  padding: 12px;
  border-radius: 15px;
  margin-bottom: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.day-header {
  text-align: center;
  font-size: 11px;
  color: #999;
  padding: 8px 5px;
  font-weight: 600;
}

.day-cell {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  cursor: pointer;
  font-size: 14px;
  position: relative;
  transition: all 0.2s ease;
  font-weight: 500;
}

.day-cell:active { transform: scale(0.9); }

.day-cell.other-month { color: #ddd; }

.day-cell.today {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: 700;
  box-shadow: 0 2px 8px rgba(255, 107, 157, 0.4);
}

.day-cell.selected {
  background: #ffb3d1;
  color: white;
  font-weight: 700;
}

/* Загруженность дня - цветовая индикация */
.day-cell.load-low { background: #fff5f7; }
.day-cell.load-medium { background: #ffe0e8; }
.day-cell.load-high { background: #ffb3c7; color: #333; }
.day-cell.load-full { 
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: 700;
}

.day-cell.today.load-low,
.day-cell.today.load-medium,
.day-cell.today.load-high,
.day-cell.today.load-full {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
}

/* Индикатор загруженности - точки */
.load-indicator {
  display: flex;
  gap: 2px;
  margin-top: 3px;
  position: absolute;
  bottom: 4px;
}

.load-dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: #ff6b9d;
}

.day-cell.today .load-dot,
.day-cell.load-full .load-dot {
  background: white;
}

/* Процент загруженности */
.load-percent {
  position: absolute;
  top: 2px;
  right: 3px;
  font-size: 8px;
  color: #ff6b9d;
  font-weight: 700;
}

.day-cell.today .load-percent,
.day-cell.load-full .load-percent {
  color: white;
}

/* === ФИЛЬТР === */
.filter-bar { margin-bottom: 15px; }
.filter-bar select {
  width: 100%;
  padding: 12px;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  background: white;
  font-size: 14px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.03);
}

/* === ЗАПИСИ === */
.entry-card {
  background: white;
  padding: 14px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.06);
  border-left: 5px solid #ff6b9d;
  cursor: pointer;
  transition: all 0.3s ease;
}

.entry-card:active { transform: scale(0.98); }

.entry-card.status-new { border-left-color: #2196f3; }
.entry-card.status-confirmed { border-left-color: #4caf50; }
.entry-card.status-done { border-left-color: #9e9e9e; opacity: 0.7; }
.entry-card.status-cancelled { border-left-color: #f44336; opacity: 0.5; }

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 5px 0;
}

.entry-compact-time {
  font-weight: 700;
  color: #ff6b9d;
  font-size: 16px;
  letter-spacing: 0.5px;
}

.entry-compact-name {
  font-weight: 600;
  font-size: 15px;
  flex: 1;
  margin-left: 15px;
  color: #333;
}

.entry-compact-price {
  font-weight: 700;
  color: #333;
  font-size: 15px;
}

.expand-icon {
  margin-left: 10px;
  color: #999;
  font-size: 12px;
  transition: transform 0.3s;
}

.entry-card.expanded .expand-icon { transform: rotate(180deg); }

.entry-card.compact .entry-details,
.entry-card.compact .status-buttons,
.entry-card.compact .entry-actions,
.entry-card.compact .entry-notes {
  display: none;
}

.entry-card.expanded .entry-details,
.entry-card.expanded .status-buttons,
.entry-card.expanded .entry-actions,
.entry-card.expanded .entry-notes {
  display: block;
  animation: slideDown 0.3s ease;
}

@keyframes slideDown {
  from { opacity: 0; max-height: 0; }
  to { opacity: 1; max-height: 500px; }
}

.entry-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #f0f0f0;
}

.entry-details div:first-child {
  font-weight: 600;
  font-size: 15px;
  margin-bottom: 5px;
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  margin-left: 8px;
}

.status-new { background: #e3f2fd; color: #1976d2; }
.status-confirmed { background: #e8f5e9; color: #388e3c; }
.status-done { background: #f5f5f5; color: #616161; }
.status-cancelled { background: #ffebee; color: #d32f2f; }

.status-buttons {
  display: flex;
  gap: 6px;
  margin-top: 12px;
  flex-wrap: wrap;
}

.status-btn {
  flex: 1;
  min-width: 70px;
  padding: 8px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 500;
}

.status-btn:active { transform: scale(0.95); }
.status-btn.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border-color: #ff6b9d;
}

.entry-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
}

.entry-actions button {
  flex: 1;
  padding: 10px;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.entry-actions button:active { transform: scale(0.95); }
.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

/* === КНОПКА ДОБАВЛЕНИЯ === */
.add-btn-fixed {
  position: fixed;
  bottom: 25px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 16px 35px;
  font-size: 17px;
  font-weight: 700;
  box-shadow: 0 6px 20px rgba(255, 107, 157, 0.5);
  cursor: pointer;
  transition: all 0.3s ease;
  letter-spacing: 0.5px;
}

.add-btn-fixed:active {
  transform: translateX(-50%) scale(0.95);
  box-shadow: 0 4px 15px rgba(255, 107, 157, 0.6);
}

/* === МОДАЛКА === */
.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 10000;
  align-items: flex-end;
  justify-content: center;
  backdrop-filter: blur(5px);
}

.modal.active { display: flex; }

.modal-content {
  background: white;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  border-radius: 25px 25px 0 0;
  padding: 25px 20px;
  overflow-y: auto;
  position: relative;
  animation: slideUp 0.3s ease;
}

@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 28px;
  cursor: pointer;
  color: #999;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f5f5f5;
  transition: all 0.2s;
}

.close-modal:active { background: #e0e0e0; transform: scale(0.9); }

.modal-content h3 {
  margin-bottom: 20px;
  color: #333;
  font-size: 22px;
  font-weight: 700;
  padding-right: 40px;
}

.modal-content label {
  display: block;
  margin: 15px 0 6px;
  font-size: 13px;
  color: #666;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.modal-content input,
.modal-content select,
.modal-content textarea {
  width: 100%;
  padding: 14px;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  font-size: 15px;
  font-family: inherit;
  background: #fafafa;
  transition: all 0.2s;
}

.modal-content input:focus,
.modal-content select:focus,
.modal-content textarea:focus {
  outline: none;
  border-color: #ff6b9d;
  background: white;
  box-shadow: 0 0 0 3px rgba(255, 107, 157, 0.1);
}

.time-row { display: flex; gap: 6px; align-items: center; }
.time-row input { flex: 1; }

.quick-time {
  padding: 10px 14px;
  background: #f5f5f5;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.quick-time:active { background: #ff6b9d; color: white; }

.duration-row { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 8px; }

.duration-btn {
  padding: 10px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  background: white;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s;
}

.duration-btn:active { transform: scale(0.95); }
.duration-btn.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border-color: #ff6b9d;
}

.time-end-info {
  background: linear-gradient(135deg, #fff3e0, #ffe0b2);
  padding: 12px;
  border-radius: 12px;
  font-size: 14px;
  color: #e65100;
  margin-top: 10px;
  font-weight: 500;
}

.free-slots {
  background: linear-gradient(135deg, #e8f5e9, #c8e6c9);
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
}

.free-slots-title {
  font-weight: 700;
  color: #2e7d32;
  margin-bottom: 8px;
  font-size: 14px;
}

.free-slot-btn {
  display: inline-block;
  padding: 8px 14px;
  margin: 3px;
  background: white;
  border: 2px solid #4caf50;
  border-radius: 20px;
  color: #2e7d32;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.free-slot-btn:active {
  background: #4caf50;
  color: white;
  transform: scale(0.95);
}

.conflict-warning {
  background: linear-gradient(135deg, #ffebee, #ffcdd2);
  border-left: 4px solid #f44336;
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
  color: #c62828;
  font-size: 14px;
  font-weight: 500;
}

.form-actions {
  display: flex;
  gap: 12px;
  margin-top: 25px;
  padding-bottom: 20px;
}

.save-btn {
  flex: 2;
  padding: 16px;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 15px rgba(255, 107, 157, 0.3);
}

.save-btn:active {
  transform: scale(0.95);
  box-shadow: 0 2px 10px rgba(255, 107, 157, 0.4);
}

.cancel-btn {
  flex: 1;
  padding: 16px;
  background: #f5f5f5;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-btn:active { background: #e0e0e0; transform: scale(0.95); }

/* === КЛИЕНТЫ === */
.client-card {
  background: white;
  padding: 15px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  transition: all 0.2s;
}

.client-card:active { transform: scale(0.98); }

.client-name {
  font-weight: 700;
  font-size: 16px;
  color: #333;
  margin-bottom: 5px;
}

.client-info {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
}

/* === СТАТИСТИКА === */
.stats-box {
  background: white;
  padding: 18px;
  margin-bottom: 12px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f5f5f5;
}

.stat-row:last-child { border: none; }
.stat-label { color: #666; font-size: 14px; }
.stat-value { font-weight: 700; color: #333; font-size: 15px; }

.stats-actions { display: flex; gap: 12px; margin-top: 15px; }

.action-btn {
  flex: 1;
  padding: 14px;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-btn:active {
  background: #ff6b9d;
  color: white;
  border-color: #ff6b9d;
  transform: scale(0.95);
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #999;
  font-size: 15px;
}
CSS
echo "✅ Стили обновлены"

# 2. Обновляем app.js с загруженностью
cat > app.js << 'JS'
// === ГДЕСВЕТА v2.2 — ЗАГРУЖЕННОСТЬ ДНЕЙ + УЛУЧШЕННЫЙ UI ===
const STORAGE_KEY = 'gdesveta_data';
const WORK_START = 9;
const WORK_END = 21;
const MAX_SLOTS_PER_DAY = 24; // Максимум записей в день для расчёта %

let state = {
  entries: [],
  currentDate: new Date(),
  selectedDate: new Date().toISOString().split('T')[0],
  filter: 'all'
};

function migrateData() {
  const raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
  state.entries = raw.map(e => ({
    ...e,
    duration: e.duration || 60,
    status: e.status || 'new'
  }));
  save();
}

function save() { localStorage.setItem(STORAGE_KEY, JSON.stringify(state.entries)); }

document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ ГдеСвета v2.2 запущена');
  migrateData();
  setupTabs();
  setupCalendarControls();
  setupModal();
  setupFilters();
  setupStatsActions();
  renderAll();
});

function setupTabs() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
      if (btn.dataset.tab === 'clients') renderClients();
      if (btn.dataset.tab === 'stats') renderStats();
    });
  });
}

function setupCalendarControls() {
  document.getElementById('prevMonth').addEventListener('click', () => {
    state.currentDate.setMonth(state.currentDate.getMonth() - 1);
    renderCalendar();
  });
  document.getElementById('nextMonth').addEventListener('click', () => {
    state.currentDate.setMonth(state.currentDate.getMonth() + 1);
    renderCalendar();
  });
  document.getElementById('todayBtn').addEventListener('click', () => {
    state.currentDate = new Date();
    state.selectedDate = new Date().toISOString().split('T')[0];
    renderAll();
  });
}

function renderCalendar() {
  const grid = document.getElementById('calendar');
  const monthLabel = document.getElementById('currentMonth');
  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();
  
  const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
  monthLabel.textContent = `${monthNames[month]} ${year}`;
  
  const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
  let html = dayNames.map(d => `<div class="day-header">${d}</div>`).join('');
  
  const firstDay = new Date(year, month, 1);
  const startOffset = (firstDay.getDay() + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const prevMonthDays = new Date(year, month, 0).getDate();
  
  const today = new Date().toISOString().split('T')[0];
  
  // Считаем загруженность по дням
  const loadByDate = {};
  state.entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (!loadByDate[e.date]) loadByDate[e.date] = 0;
    loadByDate[e.date]++;
  });
  
  for (let i = startOffset - 1; i >= 0; i--) {
    html += `<div class="day-cell other-month">${prevMonthDays - i}</div>`;
  }
  
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const classes = ['day-cell'];
    
    if (dateStr === today) classes.push('today');
    if (dateStr === state.selectedDate) classes.push('selected');
    
    // Добавляем класс загруженности
    const load = loadByDate[dateStr] || 0;
    if (load > 0) {
      const percent = Math.min((load / MAX_SLOTS_PER_DAY) * 100, 100);
      if (percent <= 25) classes.push('load-low');
      else if (percent <= 50) classes.push('load-medium');
      else if (percent <= 75) classes.push('load-high');
      else classes.push('load-full');
    }
    
    html += `<div class="${classes.join(' ')}" data-date="${dateStr}" data-load="${load}">
      ${d}
      ${load > 0 ? `<div class="load-indicator">${'<div class="load-dot"></div>'.repeat(Math.min(load, 3))}</div>` : ''}
      ${load > 0 ? `<div class="load-percent">${Math.min(Math.round((load / MAX_SLOTS_PER_DAY) * 100), 100)}%</div>` : ''}
    </div>`;
  }
  
  grid.innerHTML = html;
  grid.querySelectorAll('.day-cell[data-date]').forEach(cell => {
    cell.addEventListener('click', () => {
      state.selectedDate = cell.dataset.date;
      renderCalendar();
      renderDayEntries();
    });
  });
}

function renderDayEntries() {
  const container = document.getElementById('dayEntries');
  let entries = state.entries.filter(e => e.date === state.selectedDate);
  if (state.filter !== 'all') entries = entries.filter(e => e.service === state.filter);
  entries.sort((a, b) => a.time.localeCompare(b.time));
  
  if (entries.length === 0) {
    container.innerHTML = `<div class="empty-state">Нет записей на ${formatDate(state.selectedDate)}</div>`;
    return;
  }
  
  const statusLabels = {
    new: 'Новая',
    confirmed: 'Подтверждена',
    done: 'Выполнена',
    cancelled: 'Отменена'
  };
  
  container.innerHTML = `<h3 style="margin:15px 0 10px;font-size:16px;">${formatDate(state.selectedDate)}</h3>` + 
    entries.map(e => {
      const endTime = calcEndTime(e.time, e.duration);
      return `
      <div class="entry-card status-${e.status} compact" data-id="${e.id}" onclick="toggleCard(${e.id})">
        <div class="entry-compact-info">
          <span class="entry-compact-time">${e.time} - ${endTime}</span>
          <span class="entry-compact-name">${e.name}</span>
          <span class="entry-compact-price">${e.price}₽</span>
          <span class="expand-icon">▼</span>
        </div>
        
        <div class="entry-details">
          <div style="margin-top:8px;font-weight:600;">${e.name} <span class="status-badge status-${e.status}">${statusLabels[e.status]}</span></div>
          <div style="margin-top:5px;">${e.service}${e.zone ? ' · ' + e.zone : ''}${e.phone ? ' · 📞 ' + e.phone : ''} · ⏱️ ${e.duration} мин</div>
        </div>
        
        ${e.notes ? `<div class="entry-notes" style="margin-top:8px;font-style:italic;color:#666;font-size:13px;">💬 ${e.notes}</div>` : ''}
        
        <div class="status-buttons">
          <button class="status-btn ${e.status==='new'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'new')"> Новая</button>
          <button class="status-btn ${e.status==='confirmed'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'confirmed')">✅ Подтв.</button>
          <button class="status-btn ${e.status==='done'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'done')">🏁 Выполн.</button>
          <button class="status-btn ${e.status==='cancelled'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'cancelled')">❌ Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" onclick="event.stopPropagation();editEntry(${e.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="event.stopPropagation();duplicateEntry(${e.id})">📋 Копия</button>
          <button class="btn-del" onclick="event.stopPropagation();deleteEntry(${e.id})">🗑️ Удалить</button>
        </div>
      </div>
    `}).join('');
}

function toggleCard(id) {
  const card = document.querySelector(`.entry-card[data-id="${id}"]`);
  if (card) {
    card.classList.toggle('expanded');
    card.classList.toggle('compact');
  }
}

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', weekday: 'short' });
}

function timeToMinutes(t) {
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
}

function minutesToTime(mins) {
  const h = Math.floor(mins / 60) % 24;
  const m = mins % 60;
  return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
}

function calcEndTime(startTime, duration) {
  if (!startTime || !duration) return '';
  const mins = timeToMinutes(startTime) + parseInt(duration);
  return minutesToTime(mins);
}

function checkConflict(date, time, duration, excludeId = null) {
  const start = timeToMinutes(time);
  const end = start + parseInt(duration);
  
  return state.entries.find(e => {
    if (e.id === excludeId) return false;
    if (e.date !== date) return false;
    if (e.status === 'cancelled') return false;
    
    const eStart = timeToMinutes(e.time);
    const eEnd = eStart + parseInt(e.duration || 60);
    
    return (start < eEnd && end > eStart);
  });
}

function getFreeSlots(date, duration = 60, excludeId = null) {
  const dayEntries = state.entries
    .filter(e => e.date === date && e.status !== 'cancelled' && e.id !== excludeId)
    .sort((a, b) => timeToMinutes(a.time) - timeToMinutes(b.time));
  
  const slots = [];
  const workStart = WORK_START * 60;
  const workEnd = WORK_END * 60;
  const step = 30;
  
  for (let t = workStart; t + duration <= workEnd; t += step) {
    const conflict = dayEntries.find(e => {
      const eStart = timeToMinutes(e.time);
      const eEnd = eStart + parseInt(e.duration || 60);
      return (t < eEnd && t + duration > eStart);
    });
    if (!conflict) {
      slots.push(minutesToTime(t));
    }
  }
  return slots;
}

function setupFilters() {
  document.getElementById('serviceFilter').addEventListener('change', (e) => {
    state.filter = e.target.value;
    renderDayEntries();
  });
}

function setupModal() {
  document.getElementById('addAppBtnFixed').addEventListener('click', () => openModal());
  document.querySelector('.close-modal').addEventListener('click', closeModal);
  document.querySelector('.cancel-btn').addEventListener('click', closeModal);
  document.getElementById('entryForm').addEventListener('submit', saveEntry);
  
  document.querySelectorAll('.quick-time').forEach(btn => {
    btn.addEventListener('click', () => {
      const now = new Date();
      now.setMinutes(now.getMinutes() + parseInt(btn.dataset.min));
      document.getElementById('entryTime').value = 
        `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
      updateTimeEnd();
      updateFreeSlots();
    });
  });
  
  document.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('entryDuration').value = btn.dataset.min;
      updateTimeEnd();
      updateFreeSlots();
    });
  });
  
  document.getElementById('entryTime').addEventListener('change', updateTimeEnd);
  document.getElementById('entryDate').addEventListener('change', updateFreeSlots);
  
  document.getElementById('modal').addEventListener('click', (e) => {
    if (e.target.id === 'modal') closeModal();
  });
}

function updateTimeEnd() {
  const time = document.getElementById('entryTime').value;
  const duration = document.getElementById('entryDuration').value;
  const endInfo = document.getElementById('timeEndInfo');
  
  if (time && duration) {
    const endTime = calcEndTime(time, duration);
    endInfo.innerHTML = `⏰ Начало: <b>${time}</b> → Окончание: <b>${endTime}</b> (${duration} мин)`;
    endInfo.style.display = 'block';
    
    const date = document.getElementById('entryDate').value;
    const excludeId = document.getElementById('entryId').value;
    const conflict = checkConflict(date, time, duration, excludeId ? parseInt(excludeId) : null);
    
    const conflictDiv = document.getElementById('conflictWarning');
    if (conflict) {
      conflictDiv.innerHTML = `️ <b>Конфликт!</b> Пересекается с: <b>${conflict.name}</b> (${conflict.time} - ${calcEndTime(conflict.time, conflict.duration)})`;
      conflictDiv.style.display = 'block';
    } else {
      conflictDiv.style.display = 'none';
    }
  } else {
    endInfo.style.display = 'none';
    document.getElementById('conflictWarning').style.display = 'none';
  }
}

function updateFreeSlots() {
  const date = document.getElementById('entryDate').value;
  const duration = document.getElementById('entryDuration').value || 60;
  const excludeId = document.getElementById('entryId').value;
  const container = document.getElementById('freeSlotsContainer');
  
  const slots = getFreeSlots(date, duration, excludeId ? parseInt(excludeId) : null);
  
  if (slots.length === 0) {
    container.innerHTML = '<div class="free-slots"><div class="free-slots-title">️ Нет свободного времени</div></div>';
    return;
  }
  
  const shown = slots.slice(0, 10);
  container.innerHTML = `
    <div class="free-slots">
      <div class="free-slots-title">🟢 Свободные слоты (${duration} мин):</div>
      ${shown.map(s => `<span class="free-slot-btn" onclick="document.getElementById('entryTime').value='${s}';updateTimeEnd();">${s}</span>`).join('')}
      ${slots.length > 10 ? `<div style="margin-top:5px;font-size:11px;color:#666;">...и ещё ${slots.length - 10}</div>` : ''}
    </div>
  `;
}

function openModal(entry = null) {
  const modal = document.getElementById('modal');
  const form = document.getElementById('entryForm');
  form.reset();
  
  if (entry) {
    document.getElementById('modalTitle').textContent = 'Редактировать запись';
    document.getElementById('entryId').value = entry.id;
    document.getElementById('entryName').value = entry.name;
    document.getElementById('entryPhone').value = entry.phone || '';
    document.getElementById('entryDate').value = entry.date;
    document.getElementById('entryTime').value = entry.time;
    document.getElementById('entryService').value = entry.service;
    document.getElementById('entryZone').value = entry.zone || '';
    document.getElementById('entryPrice').value = entry.price;
    document.getElementById('entryNotes').value = entry.notes || '';
    document.getElementById('entryStatus').value = entry.status || 'new';
    document.getElementById('entryDuration').value = entry.duration || 60;
    document.getElementById('statusField').style.display = 'block';
  } else {
    document.getElementById('modalTitle').textContent = 'Новая запись';
    document.getElementById('entryId').value = '';
    document.getElementById('entryDate').value = state.selectedDate;
    const now = new Date();
    document.getElementById('entryTime').value = 
      `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
    document.getElementById('entryDuration').value = 60;
    document.getElementById('statusField').style.display = 'none';
  }
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === document.getElementById('entryDuration').value);
  });
  
  updateTimeEnd();
  updateFreeSlots();
  modal.classList.add('active');
}

function closeModal() {
  document.getElementById('modal').classList.remove('active');
}

function saveEntry(e) {
  e.preventDefault();
  const id = document.getElementById('entryId').value;
  const entry = {
    id: id ? parseInt(id) : Date.now(),
    name: document.getElementById('entryName').value,
    phone: document.getElementById('entryPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value) || 60,
    service: document.getElementById('entryService').value,
    zone: document.getElementById('entryZone').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    notes: document.getElementById('entryNotes').value,
    status: document.getElementById('entryStatus').value || 'new'
  };
  
  const conflict = checkConflict(entry.date, entry.time, entry.duration, entry.id);
  if (conflict) {
    if (!confirm(`⚠️ КОНФЛИКТ!\n\nПересекается с:\n${conflict.name}\n${conflict.time} - ${calcEndTime(conflict.time, conflict.duration)}\n\nСохранить всё равно?`)) {
      return;
    }
  }
  
  if (id) {
    const idx = state.entries.findIndex(x => x.id === parseInt(id));
    state.entries[idx] = entry;
  } else {
    state.entries.push(entry);
  }
  save();
  closeModal();
  renderAll();
}

window.editEntry = function(id) {
  const entry = state.entries.find(e => e.id === id);
  if (entry) openModal(entry);
};

window.duplicateEntry = function(id) {
  const entry = state.entries.find(e => e.id === id);
  if (!entry) return;
  const newEntry = { ...entry, id: Date.now(), name: entry.name + ' (копия)', status: 'new' };
  state.entries.push(newEntry);
  save();
  renderAll();
};

window.deleteEntry = function(id) {
  if (!confirm('Удалить запись?')) return;
  state.entries = state.entries.filter(e => e.id !== id);
  save();
  renderAll();
};

window.changeStatus = function(id, status) {
  const entry = state.entries.find(e => e.id === id);
  if (entry) {
    entry.status = status;
    save();
    renderDayEntries();
  }
};

function renderClients() {
  const container = document.getElementById('clientsList');
  const clients = {};
  state.entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (!clients[e.name]) clients[e.name] = { visits: 0, total: 0, phone: '', lastVisit: '' };
    clients[e.name].visits++;
    clients[e.name].total += e.price;
    if (e.phone) clients[e.name].phone = e.phone;
    if (!clients[e.name].lastVisit || e.date > clients[e.name].lastVisit) {
      clients[e.name].lastVisit = e.date;
    }
  });
  
  const list = Object.entries(clients).sort((a, b) => b[1].visits - a[1].visits);
  if (list.length === 0) {
    container.innerHTML = '<div class="empty-state">Пока нет клиентов</div>';
    return;
  }
  
  container.innerHTML = list.map(([name, data]) => `
    <div class="client-card">
      <div class="client-name">${name}</div>
      <div class="client-info">
        Визитов: ${data.visits} · Сумма: ${data.total}₽
        ${data.phone ? ' · 📞 ' + data.phone : ''}
        <br>Последний визит: ${formatDate(data.lastVisit)}
      </div>
    </div>
  `).join('');
}

function renderStats() {
  const container = document.getElementById('statsContent');
  const today = new Date().toISOString().split('T')[0];
  const activeEntries = state.entries.filter(e => e.status !== 'cancelled');
  const total = state.entries.length;
  const done = state.entries.filter(e => e.status === 'done').length;
  const cancelled = state.entries.filter(e => e.status === 'cancelled').length;
  const income = activeEntries.reduce((s, e) => s + e.price, 0);
  const todayIncome = activeEntries.filter(e => e.date === today).reduce((s, e) => s + e.price, 0);
  const uniqueClients = new Set(activeEntries.map(e => e.name)).size;
  const avgCheck = activeEntries.length > 0 ? Math.round(income / activeEntries.length) : 0;
  
  container.innerHTML = `
    <div class="stats-box">
      <div class="stat-row"><span class="stat-label">Всего записей</span><span class="stat-value">${total}</span></div>
      <div class="stat-row"><span class="stat-label">Выполнено</span><span class="stat-value" style="color:#4caf50">${done}</span></div>
      <div class="stat-row"><span class="stat-label">Отменено</span><span class="stat-value" style="color:#f44336">${cancelled}</span></div>
      <div class="stat-row"><span class="stat-label">Уникальных клиентов</span><span class="stat-value">${uniqueClients}</span></div>
    </div>
    <div class="stats-box">
      <div class="stat-row"><span class="stat-label">Общий доход</span><span class="stat-value">${income}₽</span></div>
      <div class="stat-row"><span class="stat-label">Доход сегодня</span><span class="stat-value" style="color:#ff6b9d">${todayIncome}₽</span></div>
      <div class="stat-row"><span class="stat-label">Средний чек</span><span class="stat-value">${avgCheck}₽</span></div>
    </div>
  `;
}

function setupStatsActions() {
  document.getElementById('exportBtn').addEventListener('click', () => {
    const data = JSON.stringify(state.entries, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `gdesveta_backup_${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  });
  
  document.getElementById('importBtn').addEventListener('click', () => {
    document.getElementById('importFile').click();
  });
  
  document.getElementById('importFile').addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const data = JSON.parse(ev.target.result);
        if (Array.isArray(data)) {
          if (confirm(`Импортировать ${data.length} записей?`)) {
            state.entries = data;
            save();
            renderAll();
            alert('✅ Импорт выполнен');
          }
        }
      } catch (err) {
        alert('❌ Ошибка: ' + err.message);
      }
    };
    reader.readAsText(file);
  });
}

function renderAll() {
  renderCalendar();
  renderDayEntries();
}
JS
echo "✅ app.js обновлён"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "🌐 Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "✅ v2.2 ГОТОВА!"
echo "✨ Визуальная загруженность дней на календаре"
echo "✨ Улучшенный дизайн с градиентами и анимациями"
