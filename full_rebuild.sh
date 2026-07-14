#!/bin/bash
echo "🔨 Полная пересборка проекта «ГдеСвета»..."

# 1. Сохраняем старые файлы как резервные копии
cp app.js app.js.backup.$(date +%s) 2>/dev/null
cp index.html index.html.backup.$(date +%s) 2>/dev/null
cp style.css style.css.backup.$(date +%s) 2>/dev/null
echo "💾 Резервные копии созданы"

# 2. Создаём полноценный index.html
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Expires" content="0">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета</title>
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="style.css?v=3">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <nav>
        <button class="nav-btn active" data-tab="calendar">Календарь</button>
        <button class="nav-btn" data-tab="clients">Клиенты</button>
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
        <div class="filter-bar">
          <select id="serviceFilter">
            <option value="all">Все услуги</option>
            <option value="Шугаринг">Шугаринг</option>
            <option value="LPG-массаж">LPG-массаж</option>
            <option value="Другое">Другое</option>
          </select>
        </div>
        <div id="dayEntries"></div>
      </div>

      <div id="tab-clients" class="tab-content">
        <h2>👥 Клиенты</h2>
        <div id="clientsList"></div>
      </div>

      <div id="tab-stats" class="tab-content">
        <h2>📊 Статистика</h2>
        <div id="statsContent"></div>
        <div class="stats-actions">
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>
  </div>

  <button id="addAppBtnFixed" class="add-btn-fixed">+ Добавить запись</button>

  <div id="modal" class="modal">
    <div class="modal-content">
      <span class="close-modal">&times;</span>
      <h3 id="modalTitle">Новая запись</h3>
      <form id="entryForm">
        <input type="hidden" id="entryId">
        <label>Имя клиента *</label>
        <input type="text" id="entryName" required>

        <label>Телефон</label>
        <input type="tel" id="entryPhone">

        <label>Дата *</label>
        <input type="date" id="entryDate" required>

        <label>Время *</label>
        <div class="time-row">
          <input type="time" id="entryTime" required>
          <button type="button" class="quick-time" data-min="0">Сейчас</button>
          <button type="button" class="quick-time" data-min="30">+30</button>
          <button type="button" class="quick-time" data-min="60">+1ч</button>
        </div>

        <label>Услуга</label>
        <select id="entryService">
          <option>Шугаринг</option>
          <option>LPG-массаж</option>
          <option>Другое</option>
        </select>

        <label>Зона</label>
        <input type="text" id="entryZone" placeholder="напр. ноги, руки">

        <label>Цена (₽)</label>
        <input type="number" id="entryPrice" value="1000">

        <label>Заметки</label>
        <textarea id="entryNotes" rows="2"></textarea>

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
          <button type="button" class="cancel-btn">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <script src="app.js?v=3"></script>
</body>
</html>
HTML
echo "✅ index.html создан"

# 3. Создаём полноценный style.css
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f5f5f7;
  color: #333;
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
}
header { background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; padding: 15px; position: sticky; top: 0; z-index: 100; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
header h1 { text-align: center; font-size: 20px; margin-bottom: 10px; }
nav { display: flex; gap: 5px; }
.nav-btn { flex: 1; padding: 8px; border: none; background: rgba(255,255,255,0.2); color: white; border-radius: 20px; font-size: 13px; cursor: pointer; transition: all 0.2s; }
.nav-btn.active { background: white; color: #ff6b9d; font-weight: bold; }
main { padding: 15px; }
.tab-content { display: none; }
.tab-content.active { display: block; }

.calendar-controls { display: flex; align-items: center; justify-content: space-between; margin-bottom: 15px; background: white; padding: 10px; border-radius: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.calendar-controls button { background: none; border: none; font-size: 22px; color: #ff6b9d; cursor: pointer; padding: 5px 12px; }
.calendar-controls h2 { font-size: 16px; flex: 1; text-align: center; }
.small-btn { font-size: 12px !important; background: #ff6b9d !important; color: white !important; border-radius: 15px !important; padding: 5px 10px !important; }

.calendar-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 3px; background: white; padding: 10px; border-radius: 10px; margin-bottom: 15px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.day-header { text-align: center; font-size: 11px; color: #999; padding: 5px; font-weight: bold; }
.day-cell { aspect-ratio: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; border-radius: 8px; cursor: pointer; font-size: 13px; position: relative; transition: all 0.2s; }
.day-cell:hover { background: #f0f0f0; }
.day-cell.other-month { color: #ccc; }
.day-cell.today { background: #ff6b9d; color: white; font-weight: bold; }
.day-cell.selected { background: #ffb3d1; color: white; }
.day-cell.has-entries::after { content: ''; position: absolute; bottom: 3px; width: 5px; height: 5px; background: #ff6b9d; border-radius: 50%; }
.day-cell.today.has-entries::after { background: white; }

.filter-bar { margin-bottom: 15px; }
.filter-bar select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px; background: white; font-size: 14px; }

.entry-card { background: white; padding: 12px; margin-bottom: 8px; border-radius: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); border-left: 4px solid #ff6b9d; }
.entry-card.done { border-left-color: #4caf50; opacity: 0.7; }
.entry-card.cancelled { border-left-color: #f44336; opacity: 0.5; text-decoration: line-through; }
.entry-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }
.entry-time { font-weight: bold; color: #ff6b9d; font-size: 15px; }
.entry-name { font-weight: 600; margin-bottom: 3px; }
.entry-details { font-size: 13px; color: #666; }
.entry-actions { display: flex; gap: 5px; margin-top: 8px; }
.entry-actions button { flex: 1; padding: 6px; border: none; border-radius: 6px; font-size: 12px; cursor: pointer; }
.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

.add-btn-fixed {
  position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white; border: none; border-radius: 50px;
  padding: 15px 30px; font-size: 16px; font-weight: bold;
  box-shadow: 0 4px 15px rgba(255, 107, 157, 0.5);
  cursor: pointer; display: block;
}
.add-btn-fixed:active { transform: translateX(-50%) scale(0.95); }

.modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 10000; padding: 20px; overflow-y: auto; }
.modal.active { display: flex; align-items: flex-start; justify-content: center; }
.modal-content { background: white; padding: 20px; border-radius: 15px; width: 100%; max-width: 480px; position: relative; margin-top: 20px; }
.close-modal { position: absolute; top: 10px; right: 15px; font-size: 28px; cursor: pointer; color: #999; }
.modal-content h3 { margin-bottom: 15px; color: #333; }
.modal-content label { display: block; margin: 10px 0 5px; font-size: 13px; color: #666; }
.modal-content input, .modal-content select, .modal-content textarea {
  width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px; font-family: inherit;
}
.time-row { display: flex; gap: 5px; align-items: center; }
.time-row input { flex: 1; }
.quick-time { padding: 8px 10px; background: #f0f0f0; border: none; border-radius: 6px; font-size: 12px; cursor: pointer; }
.form-actions { display: flex; gap: 10px; margin-top: 20px; }
.save-btn { flex: 2; padding: 12px; background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; }
.cancel-btn { flex: 1; padding: 12px; background: #f0f0f0; border: none; border-radius: 8px; cursor: pointer; }

.client-card { background: white; padding: 12px; margin-bottom: 8px; border-radius: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.client-name { font-weight: bold; font-size: 15px; }
.client-info { font-size: 13px; color: #666; margin-top: 3px; }

.stats-box { background: white; padding: 15px; margin-bottom: 10px; border-radius: 10px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.stat-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #f0f0f0; }
.stat-row:last-child { border: none; }
.stat-label { color: #666; font-size: 14px; }
.stat-value { font-weight: bold; color: #333; }
.stats-actions { display: flex; gap: 10px; margin-top: 15px; }
.action-btn { flex: 1; padding: 12px; background: white; border: 1px solid #ddd; border-radius: 8px; font-weight: bold; cursor: pointer; }

.empty-state { text-align: center; padding: 30px; color: #999; }
CSS
echo "✅ style.css создан"

# 4. Создаём полноценный app.js
cat > app.js << 'JS'
// === ГДЕСВЕТА — ОСНОВНОЙ СКРИПТ ===
const STORAGE_KEY = 'gdesveta_data';
let state = {
  entries: JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'),
  currentDate: new Date(),
  selectedDate: new Date().toISOString().split('T')[0],
  filter: 'all'
};

function save() { localStorage.setItem(STORAGE_KEY, JSON.stringify(state.entries)); }

// === ИНИЦИАЛИЗАЦИЯ ===
document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ ГдеСвета запущена');
  setupTabs();
  setupCalendarControls();
  setupModal();
  setupFilters();
  setupStatsActions();
  renderAll();
});

// === ВКЛАДКИ ===
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

// === КАЛЕНДАРЬ ===
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
  const entriesByDate = {};
  state.entries.forEach(e => {
    if (!entriesByDate[e.date]) entriesByDate[e.date] = 0;
    entriesByDate[e.date]++;
  });
  
  for (let i = startOffset - 1; i >= 0; i--) {
    html += `<div class="day-cell other-month">${prevMonthDays - i}</div>`;
  }
  
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const classes = ['day-cell'];
    if (dateStr === today) classes.push('today');
    if (dateStr === state.selectedDate) classes.push('selected');
    if (entriesByDate[dateStr]) classes.push('has-entries');
    html += `<div class="${classes.join(' ')}" data-date="${dateStr}">${d}</div>`;
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

// === ЗАПИСИ НА ДЕНЬ ===
function renderDayEntries() {
  const container = document.getElementById('dayEntries');
  let entries = state.entries.filter(e => e.date === state.selectedDate);
  if (state.filter !== 'all') entries = entries.filter(e => e.service === state.filter);
  entries.sort((a, b) => a.time.localeCompare(b.time));
  
  if (entries.length === 0) {
    container.innerHTML = `<div class="empty-state">Нет записей на ${formatDate(state.selectedDate)}</div>`;
    return;
  }
  
  container.innerHTML = `<h3 style="margin:15px 0 10px;font-size:16px;">${formatDate(state.selectedDate)}</h3>` + 
    entries.map(e => `
      <div class="entry-card ${e.status || ''}">
        <div class="entry-header">
          <span class="entry-time">${e.time}</span>
          <span>${e.price}₽</span>
        </div>
        <div class="entry-name">${e.name}</div>
        <div class="entry-details">${e.service}${e.zone ? ' · ' + e.zone : ''}${e.phone ? ' · ' + e.phone : ''}</div>
        ${e.notes ? `<div class="entry-details" style="margin-top:4px;font-style:italic;">💬 ${e.notes}</div>` : ''}
        <div class="entry-actions">
          <button class="btn-edit" onclick="editEntry(${e.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="duplicateEntry(${e.id})">📋 Копия</button>
          <button class="btn-del" onclick="deleteEntry(${e.id})">🗑️ Удалить</button>
        </div>
      </div>
    `).join('');
}

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return d.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', weekday: 'short' });
}

// === ФИЛЬТРЫ ===
function setupFilters() {
  document.getElementById('serviceFilter').addEventListener('change', (e) => {
    state.filter = e.target.value;
    renderDayEntries();
  });
}

// === МОДАЛЬНОЕ ОКНО ===
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
    });
  });
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
    document.getElementById('statusField').style.display = 'block';
  } else {
    document.getElementById('modalTitle').textContent = 'Новая запись';
    document.getElementById('entryId').value = '';
    document.getElementById('entryDate').value = state.selectedDate;
    const now = new Date();
    document.getElementById('entryTime').value = 
      `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
    document.getElementById('statusField').style.display = 'none';
  }
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
    service: document.getElementById('entryService').value,
    zone: document.getElementById('entryZone').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    notes: document.getElementById('entryNotes').value,
    status: document.getElementById('entryStatus').value || 'new'
  };
  
  // Проверка конфликтов
  const conflict = state.entries.find(x => 
    x.date === entry.date && x.time === entry.time && x.id !== entry.id
  );
  if (conflict) {
    if (!confirm(`⚠️ На это время уже есть запись (${conflict.name}). Сохранить всё равно?`)) return;
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

// === ДЕЙСТВИЯ С ЗАПИСЯМИ ===
window.editEntry = function(id) {
  const entry = state.entries.find(e => e.id === id);
  if (entry) openModal(entry);
};

window.duplicateEntry = function(id) {
  const entry = state.entries.find(e => e.id === id);
  if (!entry) return;
  const newEntry = { ...entry, id: Date.now(), name: entry.name + ' (копия)' };
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

// === КЛИЕНТЫ ===
function renderClients() {
  const container = document.getElementById('clientsList');
  const clients = {};
  state.entries.forEach(e => {
    if (!clients[e.name]) clients[e.name] = { visits: 0, total: 0, phone: '' };
    clients[e.name].visits++;
    clients[e.name].total += e.price;
    if (e.phone) clients[e.name].phone = e.phone;
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
      </div>
    </div>
  `).join('');
}

// === СТАТИСТИКА ===
function renderStats() {
  const container = document.getElementById('statsContent');
  const today = new Date().toISOString().split('T')[0];
  const total = state.entries.length;
  const done = state.entries.filter(e => e.status === 'done').length;
  const cancelled = state.entries.filter(e => e.status === 'cancelled').length;
  const income = state.entries.filter(e => e.status !== 'cancelled').reduce((s, e) => s + e.price, 0);
  const todayIncome = state.entries.filter(e => e.date === today && e.status !== 'cancelled').reduce((s, e) => s + e.price, 0);
  const uniqueClients = new Set(state.entries.map(e => e.name)).size;
  
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
          if (confirm(`Импортировать ${data.length} записей? Текущие будут заменены.`)) {
            state.entries = data;
            save();
            renderAll();
            alert('✅ Импорт выполнен');
          }
        }
      } catch (err) {
        alert('❌ Ошибка импорта: ' + err.message);
      }
    };
    reader.readAsText(file);
  });
}

// === РЕНДЕР ВСЕГО ===
function renderAll() {
  renderCalendar();
  renderDayEntries();
}
JS
echo "✅ app.js создан (полнофункциональный)"

# 5. Обновляем manifest.json
cat > manifest.json << 'MANIFEST'
{
  "name": "ГдеСвета",
  "short_name": "ГдеСвета",
  "description": "Календарь для мастера шугаринга и LPG",
  "start_url": "./",
  "display": "standalone",
  "background_color": "#f5f5f7",
  "theme_color": "#ff6b9d",
  "orientation": "portrait"
}
MANIFEST

# 6. Отключаем Service Worker
cat > service-worker.js << 'SW'
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(clients.claim()));
self.addEventListener('fetch', () => {});
SW

# 7. Перезапускаем сервер
pkill -f "python.*http.server" 2>/dev/null
sleep 1
cd ~/GdeSvet
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# 8. Открываем браузер
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "🌐 Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "🎉 ПРОЕКТ ПОЛНОСТЬЮ ВОССТАНОВЛЕН!"
echo "✨ Работает: календарь, записи, клиенты, статистика, экспорт/импорт"
echo "💾 Старые файлы сохранены с расширением .backup.*"
