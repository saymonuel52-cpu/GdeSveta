#!/bin/bash
echo "🔍 Диагностика..."

# Проверяем app.js на синтаксические ошибки
echo "Проверка app.js..."
node --check app.js 2>&1 || echo "❌ Ошибка в app.js!"

# Смотрим размер файлов
echo ""
echo "Размеры файлов:"
wc -l app.js style.css index.html

# Проверяем наличие ключевых функций
echo ""
echo "Проверка функций в app.js:"
grep -c "function renderCalendar" app.js
grep -c "document.addEventListener.*DOMContentLoaded" app.js
grep -c "renderAll()" app.js

echo ""
echo "🔧 Исправляю обе проблемы..."

# 1. Исправляем app.js — добавляем безопасную инициализацию
cat > app.js << 'JSEOF'
// === ГДЕСВЕТА v3.1 — ИСПРАВЛЕННАЯ ===
const STORAGE_KEY = 'gdesveta_data';
const TEMPLATES_KEY = 'gdesveta_templates';
const SETTINGS_KEY = 'gdesveta_settings';

let state = {
  entries: [],
  templates: [],
  settings: {
    workStart: 9,
    workEnd: 21,
    weekends: [6],
    darkTheme: false
  },
  currentDate: new Date(),
  selectedDate: new Date().toISOString().split('T')[0],
  filter: 'all'
};

function migrateData() {
  try {
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
  } catch (e) {
    console.error('Ошибка миграции:', e);
  }
  save();
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

// Безопасная инициализация
function init() {
  console.log('✅ ГдеСвета v3.1 запускается...');
  try {
    migrateData();
    setupTabs();
    setupCalendarControls();
    setupModal();
    setupFilters();
    setupStatsActions();
    setupSettings();
    setupSearch();
    renderAll();
    console.log('✅ Инициализация завершена');
  } catch (e) {
    console.error('❌ Ошибка инициализации:', e);
  }
}

// Запуск после загрузки DOM
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

function applyTheme() {
  if (state.settings.darkTheme) {
    document.body.classList.add('dark-theme');
  } else {
    document.body.classList.remove('dark-theme');
  }
}

function setupTabs() {
  const navBtns = document.querySelectorAll('.nav-btn');
  navBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      navBtns.forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      const tabId = 'tab-' + btn.dataset.tab;
      const tab = document.getElementById(tabId);
      if (tab) tab.classList.add('active');
      if (btn.dataset.tab === 'clients') renderClients();
      if (btn.dataset.tab === 'stats') renderStats();
      if (btn.dataset.tab === 'settings') renderSettings();
    });
  });
}

function setupCalendarControls() {
  const prevBtn = document.getElementById('prevMonth');
  const nextBtn = document.getElementById('nextMonth');
  const todayBtn = document.getElementById('todayBtn');
  
  if (prevBtn) {
    prevBtn.addEventListener('click', () => {
      state.currentDate.setMonth(state.currentDate.getMonth() - 1);
      renderCalendar();
    });
  }
  
  if (nextBtn) {
    nextBtn.addEventListener('click', () => {
      state.currentDate.setMonth(state.currentDate.getMonth() + 1);
      renderCalendar();
    });
  }
  
  if (todayBtn) {
    todayBtn.addEventListener('click', () => {
      state.currentDate = new Date();
      state.selectedDate = new Date().toISOString().split('T')[0];
      renderAll();
    });
  }
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
  
  if (!grid || !monthLabel) {
    console.error('Элементы календаря не найдены');
    return;
  }
  
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
    
    html += `<div class="${classes.join(' ')}" data-date="${dateStr}">
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

function renderDayEntries() {
  const container = document.getElementById('dayEntries');
  if (!container) return;
  
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
          <button class="status-btn ${e.status==='new'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'new')"> Новая</button>
          <button class="status-btn ${e.status==='confirmed'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'confirmed')">✅ Подтв.</button>
          <button class="status-btn ${e.status==='done'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'done')">🏁 Выполн.</button>
          <button class="status-btn ${e.status==='cancelled'?'active':''}" onclick="event.stopPropagation();changeStatus(${e.id},'cancelled')">❌ Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" onclick="event.stopPropagation();editEntry(${e.id})">✏️ Изменить</button>
          <button class="btn-message" onclick="event.stopPropagation();sendMessage(${e.id})">💬 Написать</button>
          <button class="btn-dup" onclick="event.stopPropagation();duplicateEntry(${e.id})"> Копия</button>
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

function setupFilters() {
  const filterSelect = document.getElementById('serviceFilter');
  if (!filterSelect) return;
  
  const services = [...new Set(state.entries.map(e => e.service))];
  
  filterSelect.innerHTML = '<option value="all">Все услуги</option>' +
    services.map(s => `<option value="${s}">${s}</option>`).join('');
  
  filterSelect.addEventListener('change', (e) => {
    state.filter = e.target.value;
    renderDayEntries();
  });
}

function setupSearch() {
  const searchInput = document.getElementById('globalSearch');
  if (!searchInput) return;
  
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
    if (!container) return;
    
    if (filtered.length === 0) {
      container.innerHTML = `<div class="empty-state">Ничего не найдено</div>`;
      return;
    }
    
    container.innerHTML = `<h3 style="margin:15px 0 10px;">Найдено: ${filtered.length}</h3>` +
      filtered.map(e => `
        <div class="entry-card compact" data-id="${e.id}" onclick="toggleCard(${e.id})">
          <div class="entry-compact-info">
            <span class="entry-compact-time">${e.date} ${e.time}</span>
            <span class="entry-compact-name">${e.name}</span>
            <span class="entry-compact-price">${e.price}₽</span>
          </div>
        </div>
      `).join('');
  });
}

function setupModal() {
  const addBtn = document.getElementById('addAppBtnFixed');
  if (addBtn) {
    addBtn.addEventListener('click', () => openModal());
  }
  
  const closeBtns = document.querySelectorAll('.close-modal');
  closeBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      this.closest('.modal').classList.remove('active');
    });
  });
  
  const form = document.getElementById('entryForm');
  if (form) {
    form.addEventListener('submit', saveEntry);
  }
  
  const quickTimeBtns = document.querySelectorAll('.quick-time');
  quickTimeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const now = new Date();
      now.setMinutes(now.getMinutes() + parseInt(btn.dataset.min));
      const timeInput = document.getElementById('entryTime');
      if (timeInput) {
        timeInput.value = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
        updateTimeEnd();
        updateFreeSlots();
      }
    });
  });
  
  const durationBtns = document.querySelectorAll('.duration-btn');
  durationBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      durationBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const durationInput = document.getElementById('entryDuration');
      if (durationInput) {
        durationInput.value = btn.dataset.min;
        updateTimeEnd();
        updateFreeSlots();
      }
    });
  });
  
  const timeInput = document.getElementById('entryTime');
  if (timeInput) {
    timeInput.addEventListener('change', updateTimeEnd);
  }
  
  const dateInput = document.getElementById('entryDate');
  if (dateInput) {
    dateInput.addEventListener('change', updateFreeSlots);
  }
  
  const modal = document.getElementById('modal');
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target.id === 'modal') closeModal();
    });
  }
  
  updateServiceTemplates();
  updateClientsDatalist();
}

function updateServiceTemplates() {
  const select = document.getElementById('serviceTemplate');
  if (!select) return;
  
  if (state.templates.length === 0) {
    select.innerHTML = '<option value="">-- Нет шаблонов --</option>';
    return;
  }
  select.innerHTML = '<option value="">-- Выберите шаблон --</option>' +
    state.templates.map(t => `<option value="${t.id}">${t.name} (${t.duration} мин, ${t.price}₽)</option>`).join('');
}

function updateClientsDatalist() {
  const datalist = document.getElementById('clientsList');
  if (!datalist) return;
  
  const clients = [...new Set(state.entries.map(e => e.name))];
  datalist.innerHTML = clients.map(c => `<option value="${c}">`).join('');
}

function updateTimeEnd() {
  const time = document.getElementById('entryTime')?.value;
  const duration = document.getElementById('entryDuration')?.value;
  const endInfo = document.getElementById('timeEndInfo');
  
  if (time && duration && endInfo) {
    const endTime = calcEndTime(time, duration);
    endInfo.innerHTML = `⏰ ${time} → ${endTime} (${duration} мин)`;
    endInfo.style.display = 'block';
    
    const date = document.getElementById('entryDate')?.value;
    const excludeId = document.getElementById('entryId')?.value;
    const conflict = checkConflict(date, time, duration, excludeId ? parseInt(excludeId) : null);
    
    const conflictDiv = document.getElementById('conflictWarning');
    if (conflict && conflictDiv) {
      conflictDiv.innerHTML = `️ Конфликт с: ${conflict.name}`;
      conflictDiv.style.display = 'block';
    } else if (conflictDiv) {
      conflictDiv.style.display = 'none';
    }
  }
}

function updateFreeSlots() {
  const date = document.getElementById('entryDate')?.value;
  const duration = document.getElementById('entryDuration')?.value || 60;
  const excludeId = document.getElementById('entryId')?.value;
  const container = document.getElementById('freeSlotsContainer');
  
  if (!date || !container) return;
  
  if (isWeekend(date)) {
    container.innerHTML = '<div class="conflict-warning">⚠️ Выходной день</div>';
    return;
  }
  
  const slots = getFreeSlots(date, duration, excludeId ? parseInt(excludeId) : null);
  
  if (slots.length === 0) {
    container.innerHTML = '<div class="free-slots">Нет свободного времени</div>';
    return;
  }
  
  const shown = slots.slice(0, 10);
  container.innerHTML = `
    <div class="free-slots">
      <div class="free-slots-title"> Свободные слоты:</div>
      ${shown.map(s => `<span class="free-slot-btn" onclick="document.getElementById('entryTime').value='${s}';updateTimeEnd();">${s}</span>`).join('')}
    </div>
  `;
}

function openModal(entry = null) {
  const modal = document.getElementById('modal');
  const form = document.getElementById('entryForm');
  if (!modal || !form) return;
  
  form.reset();
  
  if (entry) {
    document.getElementById('modalTitle').textContent = 'Редактировать';
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
  
  const durationBtns = document.querySelectorAll('.duration-btn');
  durationBtns.forEach(b => {
    b.classList.toggle('active', b.dataset.min === document.getElementById('entryDuration').value);
  });
  
  updateTimeEnd();
  updateFreeSlots();
  modal.classList.add('active');
}

function closeModal() {
  const modal = document.getElementById('modal');
  if (modal) modal.classList.remove('active');
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
    if (!confirm(`Конфликт с ${conflict.name}. Сохранить?`)) return;
  }
  
  if (id) {
    const idx = state.entries.findIndex(x => x.id === parseInt(id));
    state.entries[idx] = entry;
  } else {
    state.entries.push(entry);
    
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
  if (!confirm('Удалить?')) return;
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
  
  const message = `Здравствуйте, ${entry.name}! Напоминаю о записи на ${formatDate(entry.date)} в ${entry.time}.`;
  
  if (entry.phone) {
    const phone = entry.phone.replace(/\D/g, '');
    const url = `sms:${phone}?body=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  } else {
    const url = `https://wa.me/?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  }
};

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
      <div class="stat-row"><span>Визитов</span><span>${totalVisits}</span></div>
      <div class="stat-row"><span>Сумма</span><span>${totalSpent}₽</span></div>
      <div class="stat-row"><span>Последний</span><span>${lastVisit ? formatDate(lastVisit) : '—'}</span></div>
    </div>
    ${clientEntries.map(e => `
      <div class="entry-card compact" style="border-left-color: ${e.color}; margin:8px 0;">
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

function renderClients() {
  const container = document.getElementById('clientsList');
  if (!container) return;
  
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
    container.innerHTML = '<div class="empty-state">Нет клиентов</div>';
    return;
  }
  
  container.innerHTML = list.map(([name, data]) => `
    <div class="client-card" onclick="showClientHistory('${name}')" style="cursor:pointer;">
      <div class="client-name">${name}</div>
      <div class="client-info">
        Визитов: ${data.visits} · Сумма: ${data.total}₽
        ${data.phone ? '<br>📞 ' + data.phone : ''}
        <br>Услуги: ${data.services.join(', ')}
        <br>Последний: ${formatDate(data.lastVisit)}
      </div>
    </div>
  `).join('');
  
  if (searchInput) {
    searchInput.oninput = renderClients;
  }
}

function renderStats() {
  const container = document.getElementById('statsContent');
  if (!container) return;
  
  const today = new Date().toISOString().split('T')[0];
  const activeEntries = state.entries.filter(e => e.status !== 'cancelled');
  const total = state.entries.length;
  const done = state.entries.filter(e => e.status === 'done').length;
  const cancelled = state.entries.filter(e => e.status === 'cancelled').length;
  const income = activeEntries.reduce((s, e) => s + e.price, 0);
  const todayIncome = activeEntries.filter(e => e.date === today).reduce((s, e) => s + e.price, 0);
  const uniqueClients = new Set(activeEntries.map(e => e.name)).size;
  const avgCheck = activeEntries.length > 0 ? Math.round(income / activeEntries.length) : 0;
  
  const serviceStats = {};
  activeEntries.forEach(e => {
    if (!serviceStats[e.service]) serviceStats[e.service] = { count: 0, income: 0 };
    serviceStats[e.service].count++;
    serviceStats[e.service].income += e.price;
  });
  
  container.innerHTML = `
    <div class="stats-box">
      <div class="stat-row"><span>Всего</span><span>${total}</span></div>
      <div class="stat-row"><span>Выполнено</span><span style="color:#4caf50">${done}</span></div>
      <div class="stat-row"><span>Отменено</span><span style="color:#f44336">${cancelled}</span></div>
      <div class="stat-row"><span>Клиентов</span><span>${uniqueClients}</span></div>
    </div>
    <div class="stats-box">
      <div class="stat-row"><span>Общий доход</span><span>${income}₽</span></div>
      <div class="stat-row"><span>Сегодня</span><span style="color:#ff6b9d">${todayIncome}₽</span></div>
      <div class="stat-row"><span>Средний чек</span><span>${avgCheck}₽</span></div>
    </div>
    <div class="stats-box">
      <h4 style="margin-bottom:10px;">По услугам:</h4>
      ${Object.entries(serviceStats).map(([service, data]) => `
        <div class="stat-row">
          <span>${service}</span>
          <span>${data.count} · ${data.income}₽</span>
        </div>
      `).join('')}
    </div>
  `;
}

function setupStatsActions() {
  const exportBtn = document.getElementById('exportBtn');
  if (exportBtn) {
    exportBtn.addEventListener('click', () => {
      const data = JSON.stringify(state.entries, null, 2);
      const blob = new Blob([data], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `gdesveta_${new Date().toISOString().split('T')[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);
    });
  }
  
  const importBtn = document.getElementById('importBtn');
  const importFile = document.getElementById('importFile');
  if (importBtn && importFile) {
    importBtn.addEventListener('click', () => importFile.click());
    importFile.addEventListener('change', (e) => {
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
              alert('Импорт выполнен');
            }
          }
        } catch (err) {
          alert('Ошибка: ' + err.message);
        }
      };
      reader.readAsText(file);
    });
  }
}

function setupSettings() {
  const darkToggle = document.getElementById('darkThemeToggle');
  if (darkToggle) {
    darkToggle.addEventListener('change', (e) => {
      state.settings.darkTheme = e.target.checked;
      save();
      applyTheme();
    });
  }
  
  const saveWorkBtn = document.getElementById('saveWorkHours');
  if (saveWorkBtn) {
    saveWorkBtn.addEventListener('click', () => {
      const start = document.getElementById('workStart')?.value;
      const end = document.getElementById('workEnd')?.value;
      const weekendsSelect = document.getElementById('weekends');
      const weekends = weekendsSelect ? Array.from(weekendsSelect.selectedOptions).map(o => parseInt(o.value)) : [];
      
      if (start && end) {
        state.settings.workStart = parseInt(start.split(':')[0]);
        state.settings.workEnd = parseInt(end.split(':')[0]);
        state.settings.weekends = weekends;
        save();
        alert('Сохранено');
        renderCalendar();
      }
    });
  }
  
  const addTemplateBtn = document.getElementById('addTemplateBtn');
  if (addTemplateBtn) {
    addTemplateBtn.addEventListener('click', () => {
      const modal = document.getElementById('templateModal');
      if (modal) modal.classList.add('active');
    });
  }
  
  const templateForm = document.getElementById('templateForm');
  if (templateForm) {
    templateForm.addEventListener('submit', (e) => {
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
      document.getElementById('templateModal').classList.remove('active');
      templateForm.reset();
      renderSettings();
      updateServiceTemplates();
    });
  }
  
  const clearBtn = document.getElementById('clearAllData');
  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      if (confirm('Удалить все данные?')) {
        if (confirm('Точно?')) {
          localStorage.removeItem(STORAGE_KEY);
          localStorage.removeItem(TEMPLATES_KEY);
          localStorage.removeItem(SETTINGS_KEY);
          location.reload();
        }
      }
    });
  }
}

function renderSettings() {
  const workStart = document.getElementById('workStart');
  const workEnd = document.getElementById('workEnd');
  if (workStart) workStart.value = `${String(state.settings.workStart).padStart(2,'0')}:00`;
  if (workEnd) workEnd.value = `${String(state.settings.workEnd).padStart(2,'0')}:00`;
  
  const weekendsSelect = document.getElementById('weekends');
  if (weekendsSelect) {
    Array.from(weekendsSelect.options).forEach(option => {
      option.selected = state.settings.weekends.includes(parseInt(option.value));
    });
  }
  
  const templatesList = document.getElementById('templatesList');
  if (templatesList) {
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
}

window.deleteTemplate = function(id) {
  if (!confirm('Удалить шаблон?')) return;
  state.templates = state.templates.filter(t => t.id !== id);
  save();
  renderSettings();
  updateServiceTemplates();
};

window.closeTemplateModal = function() {
  const modal = document.getElementById('templateModal');
  if (modal) {
    modal.classList.remove('active');
    const form = document.getElementById('templateForm');
    if (form) form.reset();
  }
};

function renderAll() {
  renderCalendar();
  renderDayEntries();
  setupFilters();
  updateClientsDatalist();
}
JSEOF
echo "✅ app.js исправлен"

# 2. Исправляем стили — увеличиваем отступ ещё больше
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #fef9f9;
  color: #333;
  padding-bottom: 160px; /* ЕЩЁ БОЛЬШЕ (было 140px) */
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
}

.nav-btn.active {
  background: white;
  color: #ff6b9d;
  font-weight: 700;
}

main { padding: 15px; }
.tab-content { display: none; }
.tab-content.active { display: block; }

.search-bar { margin-bottom: 15px; }
.search-bar input, .search-input {
  width: 100%;
  padding: 12px 15px;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  font-size: 15px;
  background: white;
}

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
}

.calendar-controls h2 {
  font-size: 17px;
  flex: 1;
  text-align: center;
  font-weight: 600;
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
  font-weight: 500;
}

.day-cell.other-month { color: #ddd; }
.day-cell.today {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: 700;
}

.day-cell.selected {
  background: #ffb3d1;
  color: white;
  font-weight: 700;
}

.day-cell.load-low { background: #fff5f7; }
.day-cell.load-medium { background: #ffe0e8; }
.day-cell.load-high { background: #ffb3c7; }
.day-cell.load-full { 
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: 700;
}

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

.load-percent {
  position: absolute;
  top: 2px;
  right: 3px;
  font-size: 8px;
  color: #ff6b9d;
  font-weight: 700;
}

.income-label {
  position: absolute;
  bottom: 2px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 7px;
  color: #ff6b9d;
  font-weight: 700;
}

.filter-bar { margin-bottom: 15px; }
.filter-bar select {
  width: 100%;
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  background: white;
  font-size: 14px;
}

.entry-card {
  background: white;
  padding: 14px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
  border-left: 5px solid #ff6b9d;
  cursor: pointer;
}

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 5px 0;
}

.entry-compact-time {
  font-weight: 700;
  font-size: 16px;
  color: #ff6b9d;
}

.entry-compact-name {
  font-weight: 600;
  font-size: 15px;
  flex: 1;
  margin-left: 15px;
}

.entry-compact-price {
  font-weight: 700;
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
}

.status-btn.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border-color: #ff6b9d;
}

.entry-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
  flex-wrap: wrap;
}

.entry-actions button {
  flex: 1;
  min-width: 100px;
  padding: 10px;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
}

.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-message { background: #c8e6c9; color: #2e7d32; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

/* КНОПКА ДОБАВЛЕНИЯ — ЕЩЁ НИЖЕ И МЕНЬШЕ */
.add-btn-fixed {
  position: fixed;
  bottom: 35px; /* ОПУЩЕНО ЕЩЁ НИЖЕ */
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 12px 25px; /* ЕЩЁ МЕНЬШЕ */
  font-size: 15px; /* ЕЩЁ МЕНЬШЕ */
  font-weight: 700;
  box-shadow: 0 6px 20px rgba(255, 107, 157, 0.5);
  cursor: pointer;
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
  font-weight: 700;
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
  padding: 14px;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  font-size: 15px;
  background: #fafafa;
}

.time-row { display: flex; gap: 6px; align-items: center; }
.time-row input { flex: 1; }

.quick-time {
  padding: 10px 14px;
  background: #e0e0e0;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
}

.duration-row { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 8px; }

.duration-btn {
  padding: 10px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  background: white;
  cursor: pointer;
}

.duration-btn.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border-color: #ff6b9d;
}

.time-end-info {
  background: #fff3e0;
  padding: 12px;
  border-radius: 12px;
  font-size: 14px;
  color: #e65100;
  margin-top: 10px;
}

.free-slots {
  background: #e8f5e9;
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
}

.free-slots-title {
  font-weight: 700;
  color: #2e7d32;
  margin-bottom: 8px;
}

.free-slot-btn {
  display: inline-block;
  padding: 8px 14px;
  margin: 3px;
  background: white;
  border: 2px solid #4caf50;
  border-radius: 20px;
  color: #2e7d32;
  cursor: pointer;
}

.conflict-warning {
  background: #ffebee;
  border-left: 4px solid #f44336;
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
  color: #c62828;
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

.client-card {
  background: white;
  padding: 15px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.client-name {
  font-weight: 700;
  font-size: 16px;
  margin-bottom: 5px;
}

.client-info {
  font-size: 13px;
  color: #666;
  line-height: 1.5;
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

.chart {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  height: 150px;
  padding: 10px;
  gap: 5px;
}

.chart-bar {
  flex: 1;
  background: linear-gradient(180deg, #ff6b9d, #ff8e53);
  border-radius: 8px 8px 0 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 5px;
}

.chart-value {
  font-size: 11px;
  font-weight: 700;
  color: white;
}

.chart-label {
  font-size: 10px;
  color: white;
}

.stats-actions { display: flex; gap: 12px; margin-top: 15px; }

.action-btn {
  flex: 1;
  padding: 14px;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  font-weight: 700;
  cursor: pointer;
}

.settings-section {
  background: white;
  padding: 20px;
  margin-bottom: 15px;
  border-radius: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.settings-section h3 {
  margin-bottom: 15px;
}

.settings-section input,
.settings-section select {
  width: 100%;
  padding: 10px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  margin: 5px 0;
}

.template-card {
  background: #fafafa;
  padding: 12px;
  margin: 8px 0;
  border-radius: 10px;
  position: relative;
}

.template-name {
  font-weight: 600;
  margin-bottom: 5px;
}

.template-info {
  font-size: 13px;
  color: #666;
}

.template-card .btn-del {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 5px 10px;
  font-size: 12px;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}
CSS
echo "✅ Стили обновлены"

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
echo "🔧 ИСПРАВЛЕНО:"
echo "  ✅ Календарь загружается сразу (безопасная инициализация)"
echo "  ✅ Кнопка опущена ещё ниже (bottom: 35px)"
echo "  ✅ Кнопка уменьшена (padding: 12px 25px, font: 15px)"
echo "  ✅ Отступ увеличен (padding-bottom: 160px)"
echo ""
echo "Теперь должно работать!"
