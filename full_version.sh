#!/bin/bash
echo "🚀 Создаю полноценную версию с категориями..."

# 1. index.html
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета</title>
  <link rel="stylesheet" href="style.css?v=6">
</head>
<body>
  <header>
    <h1>📅 ГдеСвета</h1>
    <nav>
      <button class="nav-btn active" data-tab="calendar">Календарь</button>
      <button class="nav-btn" data-tab="work">Работа</button>
      <button class="nav-btn" data-tab="family">Семья</button>
      <button class="nav-btn" data-tab="stats">Статистика</button>
    </nav>
  </header>

  <main>
    <div id="tab-calendar" class="tab-content active">
      <div class="calendar-controls">
        <button id="prevMonth">‹</button>
        <h2 id="currentMonth"></h2>
        <button id="nextMonth">›</button>
        <button id="todayBtn" class="small-btn">Сегодня</button>
      </div>
      <div id="calendar" class="calendar-grid"></div>
      <div id="dayEntries"></div>
    </div>

    <div id="tab-work" class="tab-content">
      <h2>💼 Работа</h2>
      <div id="workEntries"></div>
    </div>

    <div id="tab-family" class="tab-content">
      <h2>🏠 Семья</h2>
      <div id="familyEntries"></div>
    </div>

    <div id="tab-stats" class="tab-content">
      <h2>📊 Статистика</h2>
      <div id="statsContent"></div>
    </div>
  </main>

  <button class="add-btn-fixed" onclick="openAddModal()">+ Добавить запись</button>

  <div id="modal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal()">&times;</span>
      <h3 id="modalTitle">Новая запись</h3>
      <form id="entryForm" onsubmit="saveEntry(event)">
        <input type="hidden" id="entryId">
        
        <label>Категория *</label>
        <select id="entryCategory" required>
          <option value="work">💼 Работа</option>
          <option value="family"> Семья</option>
        </select>

        <label>Название *</label>
        <input type="text" id="entryName" required placeholder="Напр. Шугаринг или Врач">

        <label>Телефон (для работы)</label>
        <input type="tel" id="entryPhone" placeholder="+7 (999) 999-99-99">

        <label>Дата *</label>
        <input type="date" id="entryDate" required>

        <label>Время *</label>
        <input type="time" id="entryTime" required>

        <label>Длительность (мин)</label>
        <div class="duration-row">
          <button type="button" class="duration-btn" data-min="30">30</button>
          <button type="button" class="duration-btn active" data-min="60">60</button>
          <button type="button" class="duration-btn" data-min="90">90</button>
          <button type="button" class="duration-btn" data-min="120">120</button>
        </div>
        <input type="hidden" id="entryDuration" value="60">

        <label>Услуга/Тип</label>
        <select id="entryService">
          <option>Шугаринг</option>
          <option>LPG-массаж</option>
          <option>Врач</option>
          <option>Школа/Сад</option>
          <option>Покупки</option>
          <option>Другое</option>
        </select>

        <label>Заметки</label>
        <textarea id="entryNotes" rows="2"></textarea>

        <label>Цена (для работы)</label>
        <input type="number" id="entryPrice" value="0">

        <div id="statusField" style="display:none">
          <label>Статус</label>
          <select id="entryStatus">
            <option value="new">Новая</option>
            <option value="done">Выполнено</option>
            <option value="cancelled">Отменено</option>
          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="closeModal()">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <script src="app.js?v=6"></script>
</body>
</html>
HTML

# 2. style.css
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #fef9f9;
  color: #333;
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
}

header {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  padding: 20px 15px;
  position: sticky;
  top: 0;
  z-index: 100;
  border-radius: 0 0 20px 20px;
}

header h1 {
  text-align: center;
  font-size: 22px;
  margin-bottom: 12px;
}

nav { display: flex; gap: 8px; }

.nav-btn {
  flex: 1;
  padding: 10px 8px;
  border: none;
  background: rgba(255,255,255,0.25);
  color: white;
  border-radius: 20px;
  font-size: 13px;
  cursor: pointer;
}

.nav-btn.active {
  background: white;
  color: #ff6b9d;
  font-weight: bold;
}

main { padding: 15px; }
.tab-content { display: none; }
.tab-content.active { display: block; }

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
  background: #ff6b9d;
  border: none;
  color: white;
  padding: 8px 14px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: bold;
}

.calendar-controls h2 {
  font-size: 17px;
  flex: 1;
  text-align: center;
}

.small-btn { font-size: 12px !important; padding: 6px 12px !important; }

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
  color: #666;
  padding: 8px 5px;
  font-weight: bold;
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
  background: #fafafa;
}

.day-cell.today {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: bold;
}

.day-cell.selected {
  background: #ffb3d1;
  color: white;
}

.day-cell.has-work { border-left: 3px solid #ff6b9d; }
.day-cell.has-family { border-right: 3px solid #4a90e2; }

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

.day-cell.today .load-dot { background: white; }

.entry-card {
  background: white;
  padding: 14px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  border-left: 5px solid #ff6b9d;
  cursor: pointer;
}

.entry-card.category-family { border-left-color: #4a90e2; }
.entry-card.status-done { opacity: 0.7; }
.entry-card.status-cancelled { opacity: 0.5; text-decoration: line-through; }

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.entry-compact-time {
  font-weight: bold;
  color: #ff6b9d;
  font-size: 16px;
}

.entry-card.category-family .entry-compact-time { color: #4a90e2; }

.entry-compact-name {
  font-weight: 600;
  font-size: 15px;
  flex: 1;
  margin-left: 15px;
}

.entry-compact-price {
  font-weight: bold;
  font-size: 15px;
}

.expand-icon {
  margin-left: 10px;
  color: #666;
  font-size: 12px;
  transition: transform 0.3s;
}

.entry-card.expanded .expand-icon { transform: rotate(180deg); }

.entry-card.compact .entry-details,
.entry-card.compact .status-buttons,
.entry-card.compact .entry-actions { display: none; }

.entry-card.expanded .entry-details,
.entry-card.expanded .status-buttons,
.entry-card.expanded .entry-actions {
  display: block;
}

.entry-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #e0e0e0;
  font-size: 14px;
  color: #666;
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: bold;
  margin-left: 8px;
}

.status-new { background: #e3f2fd; color: #1976d2; }
.status-done { background: #e8f5e9; color: #388e3c; }
.status-cancelled { background: #ffebee; color: #d32f2f; }

.status-buttons {
  display: flex;
  gap: 6px;
  margin-top: 12px;
}

.status-btn {
  flex: 1;
  padding: 8px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 12px;
  background: white;
  cursor: pointer;
}

.status-btn.active {
  background: #ff6b9d;
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
}

.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

.add-btn-fixed {
  position: fixed;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 15px 30px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 6px 20px rgba(255,107,157,0.5);
  z-index: 9999;
}

.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 10000;
  align-items: flex-end;
  justify-content: center;
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
}

.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 28px;
  cursor: pointer;
  color: #666;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #e0e0e0;
}

.modal-content h3 {
  margin-bottom: 20px;
  font-size: 22px;
  padding-right: 40px;
}

.modal-content label {
  display: block;
  margin: 15px 0 6px;
  font-size: 13px;
  color: #666;
  font-weight: 600;
}

.modal-content input,
.modal-content select,
.modal-content textarea {
  width: 100%;
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 15px;
}

.duration-row { display: flex; gap: 6px; margin-top: 8px; }

.duration-btn {
  padding: 10px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  background: white;
  cursor: pointer;
}

.duration-btn.active {
  background: #ff6b9d;
  color: white;
  border-color: #ff6b9d;
}

.form-actions {
  display: flex;
  gap: 12px;
  margin-top: 25px;
}

.save-btn {
  flex: 2;
  padding: 16px;
  background: #ff6b9d;
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: bold;
  cursor: pointer;
}

.cancel-btn {
  flex: 1;
  padding: 16px;
  background: #e0e0e0;
  border: none;
  border-radius: 12px;
  cursor: pointer;
}

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
  border-bottom: 1px solid #e0e0e0;
}

.stat-row:last-child { border: none; }

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #999;
}

h2 {
  margin-bottom: 15px;
  color: #333;
}
CSS

# 3. app.js
cat > app.js << 'JSEOF'
// === ГДЕСВЕТА v4.0 — С КАТЕГОРИЯМИ ===
const STORAGE_KEY = 'gdesveta_data';

let entries = [];
let currentDate = new Date();
let selectedDate = new Date().toISOString().split('T')[0];

// Загрузка данных
function loadData() {
  const raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
  entries = raw.map(e => ({
    ...e,
    duration: e.duration || 60,
    status: e.status || 'new',
    category: e.category || 'work'
  }));
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

// Инициализация
document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ ГдеСвета v4.0 запущена');
  loadData();
  setupTabs();
  setupCalendarControls();
  setupDurationButtons();
  renderAll();
});

// Вкладки
function setupTabs() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
      
      if (btn.dataset.tab === 'work') renderCategoryEntries('work');
      if (btn.dataset.tab === 'family') renderCategoryEntries('family');
      if (btn.dataset.tab === 'stats') renderStats();
    });
  });
}

// Управление календарём
function setupCalendarControls() {
  document.getElementById('prevMonth').addEventListener('click', () => {
    currentDate.setMonth(currentDate.getMonth() - 1);
    renderCalendar();
  });
  document.getElementById('nextMonth').addEventListener('click', () => {
    currentDate.setMonth(currentDate.getMonth() + 1);
    renderCalendar();
  });
  document.getElementById('todayBtn').addEventListener('click', () => {
    currentDate = new Date();
    selectedDate = new Date().toISOString().split('T')[0];
    renderAll();
  });
}

// Кнопки длительности
function setupDurationButtons() {
  document.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('entryDuration').value = btn.dataset.min;
    });
  });
}

// Рендер календаря
function renderCalendar() {
  const grid = document.getElementById('calendar');
  const monthLabel = document.getElementById('currentMonth');
  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();
  
  const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
  monthLabel.textContent = monthNames[month] + ' ' + year;
  
  const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
  let html = dayNames.map(d => '<div class="day-header">' + d + '</div>').join('');
  
  const firstDay = new Date(year, month, 1);
  const startOffset = (firstDay.getDay() + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const prevMonthDays = new Date(year, month, 0).getDate();
  
  const today = new Date().toISOString().split('T')[0];
  const hasWork = {};
  const hasFamily = {};
  
  entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (e.category === 'work') hasWork[e.date] = true;
    if (e.category === 'family') hasFamily[e.date] = true;
  });
  
  for (let i = startOffset - 1; i >= 0; i--) {
    html += '<div class="day-cell other-month">' + (prevMonthDays - i) + '</div>';
  }
  
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = year + '-' + String(month+1).padStart(2,'0') + '-' + String(d).padStart(2,'0');
    const classes = ['day-cell'];
    
    if (dateStr === today) classes.push('today');
    if (dateStr === selectedDate) classes.push('selected');
    if (hasWork[dateStr]) classes.push('has-work');
    if (hasFamily[dateStr]) classes.push('has-family');
    
    const entryCount = entries.filter(e => e.date === dateStr && e.status !== 'cancelled').length;
    
    html += '<div class="' + classes.join(' ') + '" onclick="selectDate(\'' + dateStr + '\')">' + d;
    if (entryCount > 0) {
      html += '<div class="load-indicator">' + '<div class="load-dot"></div>'.repeat(Math.min(entryCount, 3)) + '</div>';
    }
    html += '</div>';
  }
  
  grid.innerHTML = html;
}

function selectDate(date) {
  selectedDate = date;
  renderCalendar();
  renderDayEntries();
}

// Рендер записей на день (все категории)
function renderDayEntries() {
  const container = document.getElementById('dayEntries');
  const dayEntries = entries.filter(e => e.date === selectedDate && e.status !== 'cancelled');
  dayEntries.sort((a, b) => a.time.localeCompare(b.time));
  
  if (dayEntries.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет записей на ' + formatDate(selectedDate) + '</div>';
    return;
  }
  
  container.innerHTML = '<h3>' + formatDate(selectedDate) + '</h3>' + 
    dayEntries.map(e => createEntryCard(e)).join('');
}

// Рендер записей по категории
function renderCategoryEntries(category) {
  const container = document.getElementById(category + 'Entries');
  const categoryEntries = entries.filter(e => e.category === category && e.status !== 'cancelled');
  categoryEntries.sort((a, b) => a.date.localeCompare(b.date) || a.time.localeCompare(b.time));
  
  if (categoryEntries.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет записей</div>';
    return;
  }
  
  container.innerHTML = categoryEntries.map(e => createEntryCard(e)).join('');
}

// Создание карточки записи
function createEntryCard(e) {
  const endTime = calcEndTime(e.time, e.duration);
  const categoryIcon = e.category === 'work' ? '' : '🏠';
  const statusLabels = { new: 'Новая', done: 'Выполнено', cancelled: 'Отменено' };
  
  return `
    <div class="entry-card category-${e.category} status-${e.status} compact" data-id="${e.id}" onclick="toggleCard(${e.id})">
      <div class="entry-compact-info">
        <span class="entry-compact-time">${e.time} - ${endTime}</span>
        <span class="entry-compact-name">${categoryIcon} ${e.name}</span>
        ${e.price > 0 ? '<span class="entry-compact-price">' + e.price + '₽</span>' : ''}
        <span class="expand-icon">▼</span>
      </div>
      
      <div class="entry-details">
        <div><b>${e.name}</b> <span class="status-badge status-${e.status}">${statusLabels[e.status]}</span></div>
        <div style="margin-top:5px;">${e.service}${e.notes ? ' · ' + e.notes : ''}${e.phone ? ' · 📞 ' + e.phone : ''} · ⏱️ ${e.duration} мин</div>
      </div>
      
      <div class="status-buttons">
        <button class="status-btn ${e.status==='new'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'new')">Новая</button>
        <button class="status-btn ${e.status==='done'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'done')">Выполнено</button>
        <button class="status-btn ${e.status==='cancelled'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'cancelled')">Отмена</button>
      </div>
      
      <div class="entry-actions">
        <button class="btn-edit" onclick="event.stopPropagation();editEntry(${e.id})">✏️ Изменить</button>
        <button class="btn-dup" onclick="event.stopPropagation();duplicateEntry(${e.id})">📋 Копия</button>
        <button class="btn-del" onclick="event.stopPropagation();deleteEntry(${e.id})">🗑️ Удалить</button>
      </div>
    </div>
  `;
}

function toggleCard(id) {
  const card = document.querySelector('.entry-card[data-id="' + id + '"]');
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
  return String(h).padStart(2,'0') + ':' + String(m).padStart(2,'0');
}

function calcEndTime(startTime, duration) {
  if (!startTime || !duration) return '';
  return minutesToTime(timeToMinutes(startTime) + parseInt(duration));
}

// Модальное окно
function openAddModal() {
  console.log('🔘 Кнопка нажата!');
  const modal = document.getElementById('modal');
  const form = document.getElementById('entryForm');
  form.reset();
  
  document.getElementById('modalTitle').textContent = 'Новая запись';
  document.getElementById('entryId').value = '';
  document.getElementById('entryDate').value = selectedDate;
  document.getElementById('entryDuration').value = 60;
  document.getElementById('statusField').style.display = 'none';
  
  const now = new Date();
  document.getElementById('entryTime').value = 
    String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0');
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === '60');
  });
  
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
    category: document.getElementById('entryCategory').value,
    name: document.getElementById('entryName').value,
    phone: document.getElementById('entryPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value) || 60,
    service: document.getElementById('entryService').value,
    notes: document.getElementById('entryNotes').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    status: document.getElementById('entryStatus').value || 'new'
  };
  
  // Проверка конфликтов
  const conflict = entries.find(x => 
    x.id !== entry.id && 
    x.date === entry.date && 
    x.time === entry.time && 
    x.status !== 'cancelled'
  );
  
  if (conflict) {
    if (!confirm('️ На это время уже есть запись: ' + conflict.name + '. Сохранить всё равно?')) {
      return;
    }
  }
  
  if (id) {
    const idx = entries.findIndex(x => x.id === parseInt(id));
    entries[idx] = entry;
  } else {
    entries.push(entry);
  }
  
  save();
  closeModal();
  renderAll();
  alert('✅ Запись сохранена!');
}

function editEntry(id) {
  const entry = entries.find(e => e.id === id);
  if (!entry) return;
  
  const modal = document.getElementById('modal');
  const form = document.getElementById('entryForm');
  form.reset();
  
  document.getElementById('modalTitle').textContent = 'Редактировать запись';
  document.getElementById('entryId').value = entry.id;
  document.getElementById('entryCategory').value = entry.category;
  document.getElementById('entryName').value = entry.name;
  document.getElementById('entryPhone').value = entry.phone || '';
  document.getElementById('entryDate').value = entry.date;
  document.getElementById('entryTime').value = entry.time;
  document.getElementById('entryDuration').value = entry.duration;
  document.getElementById('entryService').value = entry.service;
  document.getElementById('entryNotes').value = entry.notes || '';
  document.getElementById('entryPrice').value = entry.price;
  document.getElementById('entryStatus').value = entry.status || 'new';
  document.getElementById('statusField').style.display = 'block';
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === entry.duration.toString());
  });
  
  modal.classList.add('active');
}

function duplicateEntry(id) {
  const entry = entries.find(e => e.id === id);
  if (!entry) return;
  const newEntry = { ...entry, id: Date.now(), name: entry.name + ' (копия)', status: 'new' };
  entries.push(newEntry);
  save();
  renderAll();
}

function deleteEntry(id) {
  if (!confirm('Удалить запись?')) return;
  entries = entries.filter(e => e.id !== id);
  save();
  renderAll();
}

function changeStatus(id, status) {
  const entry = entries.find(e => e.id === id);
  if (entry) {
    entry.status = status;
    save();
    renderAll();
  }
}

// Статистика
function renderStats() {
  const container = document.getElementById('statsContent');
  const today = new Date().toISOString().split('T')[0];
  const activeEntries = entries.filter(e => e.status !== 'cancelled');
  const workEntries = activeEntries.filter(e => e.category === 'work');
  const familyEntries = activeEntries.filter(e => e.category === 'family');
  
  const totalIncome = workEntries.reduce((s, e) => s + e.price, 0);
  const todayIncome = workEntries.filter(e => e.date === today).reduce((s, e) => s + e.price, 0);
  
  container.innerHTML = `
    <div class="stats-box">
      <div class="stat-row"><span>Всего записей</span><span><b>${entries.length}</b></span></div>
      <div class="stat-row"><span> Работа</span><span><b>${workEntries.length}</b></span></div>
      <div class="stat-row"><span>🏠 Семья</span><span><b>${familyEntries.length}</b></span></div>
      <div class="stat-row"><span>Выполнено</span><span><b>${entries.filter(e => e.status === 'done').length}</b></span></div>
    </div>
    <div class="stats-box">
      <div class="stat-row"><span>Общий доход</span><span><b>${totalIncome}₽</b></span></div>
      <div class="stat-row"><span>Доход сегодня</span><span><b style="color:#ff6b9d">${todayIncome}₽</b></span></div>
    </div>
  `;
}

function renderAll() {
  renderCalendar();
  renderDayEntries();
}
JSEOF

echo "✅ Все файлы созданы"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "🎉 ПОЛНАЯ ВЕРСИЯ v4.0 ГОТОВА!"
echo ""
echo "✨ Что есть:"
echo "  📅 Календарь с визуализацией (работа - слева, семья - справа)"
echo "  💼 Вкладка 'Работа' - только рабочие записи"
echo "   Вкладка 'Семья' - только семейные дела"
echo "  📊 Статистика по категориям"
echo "  ✅ Статусы (Новая/Выполнено/Отменено)"
echo "  ️ Длительность процедур"
echo "  ⚠️ Проверка конфликтов"
echo "  📱 Компактные карточки (нажми чтобы раскрыть)"
echo ""
echo "🎯 Как работает:"
echo "  • На календаре видны ВСЕ записи"
echo "  • Редактировать можно только из своей вкладки"
echo "  • При добавлении выбираешь категорию"
