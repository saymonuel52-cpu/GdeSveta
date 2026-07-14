#!/bin/bash
echo "🚀 Продолжаем ULTIMATE UPDATE..."

# 2. Создаём полный app.js
cat > app.js << 'JSEOF'
// === ГДЕСВЕТА v3.0 — ULTIMATE EDITION ===
const STORAGE_KEY = 'gdesveta_data';
const TEMPLATES_KEY = 'gdesveta_templates';
const SETTINGS_KEY = 'gdesveta_settings';
const WORK_START_DEFAULT = 9;
const WORK_END_DEFAULT = 21;

let state = {
  entries: [],
  templates: [],
  settings: {
    workStart: WORK_START_DEFAULT,
    workEnd: WORK_END_DEFAULT,
    weekends: [6],
    darkTheme: false
  },
  currentDate: new Date(),
  selectedDate: new Date().toISOString().split('T')[0],
  filter: 'all'
};

// === МИГРАЦИЯ ДАННЫХ ===
function migrateData() {
  const raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
  state.entries = raw.map(e => ({
    ...e,
    duration: e.duration || 60,
    status: e.status || 'new',
    color: e.color || getServiceColor(e.service)
  }));
  
  const savedTemplates = JSON.parse(localStorage.getItem(TEMPLATES_KEY) || '[]');
  state.templates = savedTemplates;
  
  const savedSettings = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
  state.settings = { ...state.settings, ...savedSettings };
  
  save();
  applyTheme();
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state.entries));
  localStorage.setItem(TEMPLATES_KEY, JSON.stringify(state.templates));
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(state.settings));
}

function getServiceColor(service) {
  const colors = {
    'Шугаринг': '#ff6b9d',
    'LPG-массаж': '#4a90e2',
    'Другое': '#7ed321'
  };
  return colors[service] || '#ff6b9d';
}

// === ИНИЦИАЛИЗАЦИЯ ===
document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ ГдеСвета v3.0 Ultimate запущена');
  migrateData();
  setupTabs();
  setupCalendarControls();
  setupModal();
  setupFilters();
  setupStatsActions();
  setupSettings();
  setupSearch();
  renderAll();
});

// === ТЕМА ===
function applyTheme() {
  if (state.settings.darkTheme) {
    document.body.classList.add('dark-theme');
    if (document.getElementById('darkThemeToggle')) {
      document.getElementById('darkThemeToggle').checked = true;
    }
  } else {
    document.body.classList.remove('dark-theme');
    if (document.getElementById('darkThemeToggle')) {
      document.getElementById('darkThemeToggle').checked = false;
    }
  }
}

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
      if (btn.dataset.tab === 'settings') renderSettings();
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

function isWeekend(dateStr) {
  const date = new Date(dateStr);
  const day = date.getDay();
  const adjustedDay = day === 0 ? 6 : day - 1;
  return state.settings.weekends.includes(adjustedDay);
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
  const loadByDate = {};
  const incomeByDate = {};
  
  state.entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (!loadByDate[e.date]) {
      loadByDate[e.date] = 0;
      incomeByDate[e.date] = 0;
    }
    loadByDate[e.date]++;
    incomeByDate[e.date] += e.price;
  });
  
  for (let i = startOffset - 1; i >= 0; i--) {
    html += `<div class="day-cell other-month">${prevMonthDays - i}</div>`;
  }
  
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
    const classes = ['day-cell'];
    
    if (dateStr === today) classes.push('today');
    if (dateStr === state.selectedDate) classes.push('selected');
    if (isWeekend(dateStr)) classes.push('weekend');
    
    const load = loadByDate[dateStr] || 0;
    const income = incomeByDate[dateStr] || 0;
    
    if (load > 0) {
      const percent = Math.min((load / 12) * 100, 100);
      if (percent <= 25) classes.push('load-low');
      else if (percent <= 50) classes.push('load-medium');
      else if (percent <= 75) classes.push('load-high');
      else classes.push('load-full');
    }
    
    html += `<div class="${classes.join(' ')}" data-date="${dateStr}" data-load="${load}" data-income="${income}">
      ${d}
      ${load > 0 ? `<div class="load-indicator">${'<div class="load-dot"></div>'.repeat(Math.min(load, 3))}</div>` : ''}
      ${load > 0 ? `<div class="load-percent">${Math.min(Math.round((load / 12) * 100), 100)}%</div>` : ''}
      ${income > 0 ? `<div class="income-label">${income}₽</div>` : ''}
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
      <div class="entry-card status-${e.status} compact" data-id="${e.id}" onclick="toggleCard(${e.id})" style="border-left-color: ${e.color || '#ff6b9d'}">
        <div class="entry-compact-info">
          <span class="entry-compact-time" style="color: ${e.color || '#ff6b9d'}">${e.time} - ${endTime}</span>
          <span class="entry-compact-name">${e.name}</span>
          <span class="entry-compact-price">${e.price}₽</span>
          <span class="expand-icon">▼</span>
        </div>
        
        <div class="entry-details">
          <div style="margin-top:8px;font-weight:600;">${e.name} <span class="status-badge status-${e.status}">${statusLabels[e.status]}</span></div>
          <div style="margin-top:5px;">${e.service}${e.zone ? ' · ' + e.zone : ''}${e.phone ? ' · 📞 ' + e.phone : ''} · ⏱️ ${e.duration} мин</div>
          ${e.notes ? `<div style="margin-top:5px;font-style:italic;color:#666;font-size:13px;">💬 ${e.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons">
          <button class="status-btn ${e.status==='new'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'new')">🆕 Новая</button>
          <button class="status-btn ${e.status==='confirmed'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'confirmed')">✅ Подтв.</button>
          <button class="status-btn ${e.status==='done'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'done')">🏁 Выполн.</button>
          <button class="status-btn ${e.status==='cancelled'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'cancelled')">❌ Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" onclick="event.stopPropagation();editEntry(${e.id})">✏️ Изменить</button>
          <button class="btn-message" onclick="event.stopPropagation();sendMessage(${e.id})">💬 Написать</button>
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

// === ВРЕМЯ ===
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
  const workStart = state.settings.workStart * 60;
  const workEnd = state.settings.workEnd * 60;
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

// === ФИЛЬТРЫ ===
function setupFilters() {
  const filterSelect = document.getElementById('serviceFilter');
  const services = [...new Set(state.entries.map(e => e.service))];
  
  filterSelect.innerHTML = '<option value="all">Все услуги</option>' +
    services.map(s => `<option value="${s}">${s}</option>`).join('');
  
  filterSelect.addEventListener('change', (e) => {
    state.filter = e.target.value;
    renderDayEntries();
  });
}

// === ПОИСК ===
function setupSearch() {
  const searchInput = document.getElementById('globalSearch');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      if (query.length < 2) {
        renderDayEntries();
        return;
      }
      
      const filtered = state.entries.filter(entry => 
        entry.name.toLowerCase().includes(query) ||
        (entry.phone && entry.phone.includes(query))
      );
      
      const container = document.getElementById('dayEntries');
      if (filtered.length === 0) {
        container.innerHTML = `<div class="empty-state">Ничего не найдено по запросу "${query}"</div>`;
        return;
      }
      
      const statusLabels = {
        new: 'Новая',
        confirmed: 'Подтверждена',
        done: 'Выполнена',
        cancelled: 'Отменена'
      };
      
      container.innerHTML = `<h3 style="margin:15px 0 10px;font-size:16px;">Результаты поиска (${filtered.length})</h3>` +
        filtered.map(e => {
          const endTime = calcEndTime(e.time, e.duration);
          return `
          <div class="entry-card status-${e.status} compact" data-id="${e.id}" onclick="toggleCard(${e.id})" style="border-left-color: ${e.color || '#ff6b9d'}">
            <div class="entry-compact-info">
              <span class="entry-compact-time" style="color: ${e.color || '#ff6b9d'}">${e.date} ${e.time} - ${endTime}</span>
              <span class="entry-compact-name">${e.name}</span>
              <span class="entry-compact-price">${e.price}₽</span>
              <span class="expand-icon">▼</span>
            </div>
            <div class="entry-details">
              <div style="margin-top:8px;">${e.service}${e.zone ? ' · ' + e.zone : ''}</div>
            </div>
          </div>
        `}).join('');
    });
  }
}

// === МОДАЛКА ===
function setupModal() {
  document.getElementById('addAppBtnFixed').addEventListener('click', () => openModal());
  document.querySelector('.close-modal').addEventListener('click', closeModal);
  document.querySelector('.cancel-btn').addEventListener('click', closeModal);
  document.getElementById('entryForm').addEventListener('submit', saveEntry);
  
  // Шаблоны услуг
  document.getElementById('serviceTemplate').addEventListener('change', (e) => {
    const templateId = parseInt(e.target.value);
    if (templateId) {
      const template = state.templates.find(t => t.id === templateId);
      if (template) {
        document.getElementById('entryService').value = template.service;
        document.getElementById('entryDuration').value = template.duration;
        document.getElementById('entryPrice').value = template.price;
        document.getElementById('entryZone').value = template.name;
        
        document.querySelectorAll('.duration-btn').forEach(b => {
          b.classList.toggle('active', b.dataset.min === template.duration.toString());
        });
        
        updateTimeEnd();
        updateFreeSlots();
      }
    }
  });
  
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
  
  updateServiceTemplates();
  updateClientsDatalist();
}

function updateServiceTemplates() {
  const select = document.getElementById('serviceTemplate');
  if (state.templates.length === 0) {
    select.innerHTML = '<option value="">-- Нет шаблонов --</option>';
    return;
  }
  select.innerHTML = '<option value="">-- Выберите шаблон --</option>' +
    state.templates.map(t => `<option value="${t.id}">${t.name} (${t.duration} мин, ${t.price}₽)</option>`).join('');
}

function updateClientsDatalist() {
  const datalist = document.getElementById('clientsList');
  const clients = [...new Set(state.entries.map(e => e.name))];
  datalist.innerHTML = clients.map(c => `<option value="${c}">`).join('');
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
      conflictDiv.innerHTML = `⚠️ <b>Конфликт!</b> Пересекается с: <b>${conflict.name}</b> (${conflict.time} - ${calcEndTime(conflict.time, conflict.duration)})`;
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
  
  if (isWeekend(date)) {
    container.innerHTML = '<div class="conflict-warning">⚠️ Это выходной день</div>';
    return;
  }
  
  const slots = getFreeSlots(date, duration, excludeId ? parseInt(excludeId) : null);
  
  if (slots.length === 0) {
    container.innerHTML = '<div class="free-slots"><div class="free-slots-title">⚠️ Нет свободного времени</div></div>';
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
    document.getElementById('repeatType').value = 'none';
    document.getElementById('statusField').style.display = 'block';
  } else {
    document.getElementById('modalTitle').textContent = 'Новая запись';
    document.getElementById('entryId').value = '';
    document.getElementById('entryDate').value = state.selectedDate;
    const now = new Date();
    document.getElementById('entryTime').value = 
      `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
    document.getElementById('entryDuration').value = 60;
    document.getElementById('repeatType').value = 'none';
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
  const repeatType = document.getElementById('repeatType').value;
  
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
    status: document.getElementById('entryStatus').value || 'new',
    color: getServiceColor(document.getElementById('entryService').value)
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
    
    // Повторяющиеся записи
    if (repeatType !== 'none') {
      const startDate = new Date(entry.date);
      const repeatCount = 8;
      
      for (let i = 1; i <= repeatCount; i++) {
        const newDate = new Date(startDate);
        if (repeatType === 'weekly') {
          newDate.setDate(startDate.getDate() + (i * 7));
        } else if (repeatType === 'biweekly') {
          newDate.setDate(startDate.getDate() + (i * 14));
        } else if (repeatType === 'monthly') {
          newDate.setMonth(startDate.getMonth() + i);
        }
        
        const newDateStr = newDate.toISOString().split('T')[0];
        const newEntry = {
          ...entry,
          id: Date.now() + i,
          date: newDateStr,
          status: 'new'
        };
        
        if (!checkConflict(newDateStr, newEntry.time, newEntry.duration)) {
          state.entries.push(newEntry);
        }
      }
    }
  }
  
  save();
  closeModal();
  renderAll();
}

// === ДЕЙСТВИЯ ===
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

window.sendMessage = function(id) {
  const entry = state.entries.find(e => e.id === id);
  if (!entry) return;
  
  const message = `Здравствуйте, ${entry.name}! Напоминаю о вашей записи на ${formatDate(entry.date)} в ${entry.time}. Жду вас!`;
  
  if (entry.phone) {
    const phone = entry.phone.replace(/\D/g, '');
    const url = `sms:${phone}?body=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  } else {
    const url = `https://wa.me/?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  }
};

// === ИСТОРИЯ КЛИЕНТА ===
window.showClientHistory = function(name) {
  const clientEntries = state.entries.filter(e => e.name === name && e.status !== 'cancelled');
  const totalVisits = clientEntries.length;
  const totalSpent = clientEntries.reduce((sum, e) => sum + e.price, 0);
  const lastVisit = clientEntries.length > 0 ? clientEntries.sort((a, b) => b.date.localeCompare(a.date))[0].date : '';
  
  const modal = document.getElementById('clientHistoryModal');
  document.getElementById('clientHistoryTitle').textContent = `История: ${name}`;
  
  const content = document.getElementById('clientHistoryContent');
  content.innerHTML = `
    <div class="stats-box">
      <div class="stat-row"><span class="stat-label">Всего визитов</span><span class="stat-value">${totalVisits}</span></div>
      <div class="stat-row"><span class="stat-label">Общая сумма</span><span class="stat-value">${totalSpent}₽</span></div>
      <div class="stat-row"><span class="stat-label">Последний визит</span><span class="stat-value">${lastVisit ? formatDate(lastVisit) : '—'}</span></div>
    </div>
    <h4 style="margin:15px 0 10px;">Все записи:</h4>
    ${clientEntries.length === 0 ? '<div class="empty-state">Нет записей</div>' :
      clientEntries.sort((a, b) => b.date.localeCompare(a.date)).map(e => `
        <div class="entry-card compact" style="border-left-color: ${e.color}; margin-bottom:8px;">
          <div class="entry-compact-info">
            <span class="entry-compact-time">${e.date} ${e.time}</span>
            <span class="entry-compact-name">${e.service}</span>
            <span class="entry-compact-price">${e.price}₽</span>
          </div>
        </div>
      `).join('')}
  `;
  
  modal.classList.add('active');
};

window.closeClientHistory = function() {
  document.getElementById('clientHistoryModal').classList.remove('active');
};

// === КЛИЕНТЫ ===
function renderClients() {
  const container = document.getElementById('clientsList');
  const searchInput = document.getElementById('clientSearch');
  const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
  
  const clients = {};
  state.entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (!clients[e.name]) {
      clients[e.name] = { visits: 0, total: 0, phone: '', lastVisit: '', services: [] };
    }
    clients[e.name].visits++;
    clients[e.name].total += e.price;
    if (e.phone) clients[e.name].phone = e.phone;
    if (!clients[e.name].lastVisit || e.date > clients[e.name].lastVisit) {
      clients[e.name].lastVisit = e.date;
    }
    if (!clients[e.name].services.includes(e.service)) {
      clients[e.name].services.push(e.service);
    }
  });
  
  let list = Object.entries(clients).sort((a, b) => b[1].visits - a[1].visits);
  
  if (searchTerm) {
    list = list.filter(([name, data]) => 
      name.toLowerCase().includes(searchTerm) ||
      data.phone.includes(searchTerm)
    );
  }
  
  if (list.length === 0) {
    container.innerHTML = '<div class="empty-state">Пока нет клиентов</div>';
    return;
  }
  
  container.innerHTML = list.map(([name, data]) => `
    <div class="client-card" onclick="showClientHistory('${name}')" style="cursor:pointer;">
      <div class="client-name">${name}</div>
      <div class="client-info">
        Визитов: ${data.visits} · Сумма: ${data.total}₽
        ${data.phone ? '<br>📞 ' + data.phone : ''}
        <br>Услуги: ${data.services.join(', ')}
        <br>Последний визит: ${formatDate(data.lastVisit)}
      </div>
    </div>
  `).join('');
  
  if (searchInput) {
    searchInput.oninput = renderClients;
  }
}

// === СТАТИСТИКА ===
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
  
  // Статистика по услугам
  const serviceStats = {};
  activeEntries.forEach(e => {
    if (!serviceStats[e.service]) serviceStats[e.service] = { count: 0, income: 0 };
    serviceStats[e.service].count++;
    serviceStats[e.service].income += e.price;
  });
  
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
    <div class="stats-box">
      <h4 style="margin-bottom:10px;">По услугам:</h4>
      ${Object.entries(serviceStats).map(([service, data]) => `
        <div class="stat-row">
          <span class="stat-label">${service}</span>
          <span class="stat-value">${data.count} · ${data.income}₽</span>
        </div>
      `).join('')}
    </div>
  `;
  
  renderIncomeChart();
}

function renderIncomeChart() {
  const container = document.getElementById('incomeChart');
  if (!container) return;
  
  const last7Days = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    last7Days.push(date.toISOString().split('T')[0]);
  }
  
  const incomeByDay = last7Days.map(date => {
    const dayIncome = state.entries
      .filter(e => e.date === date && e.status !== 'cancelled')
      .reduce((sum, e) => sum + e.price, 0);
    return { date, income: dayIncome };
  });
  
  const maxIncome = Math.max(...incomeByDay.map(d => d.income), 1);
  
  container.innerHTML = `
    <div class="stats-box">
      <h4 style="margin-bottom:15px;">Доход за последние 7 дней:</h4>
      <div class="chart">
        ${incomeByDay.map(d => {
          const height = (d.income / maxIncome) * 100;
          const dayName = new Date(d.date).toLocaleDateString('ru-RU', { weekday: 'short' });
          return `
            <div class="chart-bar" style="height: ${height}%;">
              <div class="chart-value">${d.income}₽</div>
              <div class="chart-label">${dayName}</div>
            </div>
          `;
        }).join('')}
      </div>
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
        alert(' Ошибка: ' + err.message);
      }
    };
    reader.readAsText(file);
  });
}

// === НАСТРОЙКИ ===
function setupSettings() {
  document.getElementById('darkThemeToggle').addEventListener('change', (e) => {
    state.settings.darkTheme = e.target.checked;
    save();
    applyTheme();
  });
  
  document.getElementById('saveWorkHours').addEventListener('click', () => {
    const start = document.getElementById('workStart').value;
    const end = document.getElementById('workEnd').value;
    const weekendsSelect = document.getElementById('weekends');
    const weekends = Array.from(weekendsSelect.selectedOptions).map(o => parseInt(o.value));
    
    state.settings.workStart = parseInt(start.split(':')[0]);
    state.settings.workEnd = parseInt(end.split(':')[0]);
    state.settings.weekends = weekends;
    
    save();
    alert('✅ Настройки сохранены');
    renderCalendar();
  });
  
  document.getElementById('addTemplateBtn').addEventListener('click', () => {
    document.getElementById('templateModal').classList.add('active');
  });
  
  document.getElementById('templateForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const template = {
      id: Date.now(),
      name: document.getElementById('templateName').value,
      service: document.getElementById('templateService').value,
      duration: parseInt(document.getElementById('templateDuration').value),
      price: parseInt(document.getElementById('templatePrice').value)
    };
    
    state.templates.push(template);
    save();
    closeTemplateModal();
    renderSettings();
    updateServiceTemplates();
  });
  
  document.getElementById('clearAllData').addEventListener('click', () => {
    if (confirm('⚠️ ВНИМАНИЕ! Все данные будут удалены безвозвратно. Продолжить?')) {
      if (confirm('Точно удалить ВСЕ записи, шаблоны и настройки?')) {
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(TEMPLATES_KEY);
        localStorage.removeItem(SETTINGS_KEY);
        location.reload();
      }
    }
  });
}

function renderSettings() {
  document.getElementById('workStart').value = `${String(state.settings.workStart).padStart(2,'0')}:00`;
  document.getElementById('workEnd').value = `${String(state.settings.workEnd).padStart(2,'0')}:00`;
  
  const weekendsSelect = document.getElementById('weekends');
  Array.from(weekendsSelect.options).forEach(option => {
    option.selected = state.settings.weekends.includes(parseInt(option.value));
  });
  
  const templatesList = document.getElementById('templatesList');
  if (state.templates.length === 0) {
    templatesList.innerHTML = '<div class="empty-state">Нет шаблонов</div>';
  } else {
    templatesList.innerHTML = state.templates.map(t => `
      <div class="template-card">
        <div class="template-name">${t.name}</div>
        <div class="template-info">${t.service} · ${t.duration} мин · ${t.price}₽</div>
        <button class="btn-del" onclick="deleteTemplate(${t.id})">🗑️</button>
      </div>
    `).join('');
  }
}

window.deleteTemplate = function(id) {
  if (!confirm('Удалить шаблон?')) return;
  state.templates = state.templates.filter(t => t.id !== id);
  save();
  renderSettings();
  updateServiceTemplates();
};

window.closeTemplateModal = function() {
  document.getElementById('templateModal').classList.remove('active');
  document.getElementById('templateForm').reset();
};

// === РЕНДЕР ===
function renderAll() {
  renderCalendar();
  renderDayEntries();
  setupFilters();
  updateClientsDatalist();
}
JSEOF
echo "✅ app.js создан"

echo "Продолжение в следующем шаге..."
