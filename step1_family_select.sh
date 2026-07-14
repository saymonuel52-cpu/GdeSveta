#!/bin/bash
echo "🔧 ШАГ 1: Добавляю выбор члена семьи..."

# 1. Обновляем index.html — добавляем поле выбора члена семьи
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="style.css?v=8">
</head>
<body>
  <header>
    <h1> ГдеСвета</h1>
    <nav>
      <button class="nav-btn active" data-tab="calendar">📅</button>
      <button class="nav-btn" data-tab="work">💼</button>
      <button class="nav-btn" data-tab="family">👨👩‍👧</button>
      <button class="nav-btn" data-tab="notes">📝</button>
      <button class="nav-btn" data-tab="stats"></button>
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
      <div class="legend">
        <span class="legend-item"><span class="legend-color work"></span>Работа</span>
        <span class="legend-item"><span class="legend-color family"></span>Семья</span>
        <span class="legend-item"><span class="legend-color dog"></span>Собака</span>
        <span class="legend-item"><span class="legend-color note"></span>Заметки</span>
      </div>
      <div id="dayEntries"></div>
    </div>

    <div id="tab-work" class="tab-content">
      <div class="tab-header">
        <h2> Работа</h2>
        <button class="tab-action-btn" onclick="showPriceList()"> Прайс</button>
      </div>
      <div class="filter-bar">
        <select id="workFilter">
          <option value="all">Все клиенты</option>
          <option value="today">Сегодня</option>
          <option value="week">Неделя</option>
          <option value="month">Месяц</option>
        </select>
      </div>
      <div id="workEntries"></div>
    </div>

    <div id="tab-family" class="tab-content">
      <div class="tab-header">
        <h2>👨‍‍👧 Семья</h2>
        <button class="tab-action-btn" onclick="showFamilyMembers()">👥 Члены семьи</button>
      </div>
      <div class="family-filters">
        <button class="family-filter active" data-filter="all">Все</button>
        <button class="family-filter" data-filter="school">🏫 Школа</button>
        <button class="family-filter" data-filter="circle">🎨 Кружки</button>
        <button class="family-filter" data-filter="doctor"> Врачи</button>
        <button class="family-filter" data-filter="dog">🐕 Собака</button>
      </div>
      <div id="familyEntries"></div>
    </div>

    <div id="tab-notes" class="tab-content">
      <div class="tab-header">
        <h2>📝 Заметки</h2>
        <button class="tab-action-btn" onclick="openNoteModal()">+ Новая</button>
      </div>
      <div class="note-filters">
        <button class="note-filter active" data-filter="all">Все</button>
        <button class="note-filter" data-filter="important">⭐ Важное</button>
        <button class="note-filter" data-filter="shopping">🛒 Покупки</button>
        <button class="note-filter" data-filter="ideas">💡 Идеи</button>
      </div>
      <div id="notesList"></div>
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

  <button class="add-btn-fixed" onclick="openQuickAdd()">+ Добавить</button>

  <div id="quickAddModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal('quickAddModal')">&times;</span>
      <h3>Что добавляем?</h3>
      <div class="quick-add-grid">
        <button class="quick-add-btn work" onclick="openEntryModal('work')">
          <span class="quick-add-icon">💼</span>
          <span>Работа</span>
        </button>
        <button class="quick-add-btn family" onclick="openEntryModal('family')">
          <span class="quick-add-icon">👨‍👩‍👧</span>
          <span>Семья</span>
        </button>
        <button class="quick-add-btn dog" onclick="openEntryModal('dog')">
          <span class="quick-add-icon">🐕</span>
          <span>Собака</span>
        </button>
        <button class="quick-add-btn note" onclick="openNoteModal()">
          <span class="quick-add-icon">📝</span>
          <span>Заметка</span>
        </button>
      </div>
    </div>
  </div>

  <div id="entryModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal('entryModal')">&times;</span>
      <h3 id="entryModalTitle">Новая запись</h3>
      <form id="entryForm" onsubmit="saveEntry(event)">
        <input type="hidden" id="entryId">
        <input type="hidden" id="entryCategory">
        
        <!-- НОВОЕ ПОЛЕ: Выбор члена семьи -->
        <label id="familyMemberLabel" style="display:none">Член семьи *</label>
        <select id="familyMemberSelect" style="display:none" onchange="onFamilyMemberSelect()">
          <option value="">-- Выберите --</option>
        </select>

        <label>Название *</label>
        <input type="text" id="entryName" required placeholder="Имя клиента или событие">

        <label id="phoneLabel" style="display:none">Телефон</label>
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

        <label id="serviceLabel">Услуга/Тип</label>
        <select id="entryService">
          <option>Шугаринг</option>
          <option>LPG-массаж</option>
          <option>Школа</option>
          <option>Садик</option>
          <option>Кружок</option>
          <option>Секция</option>
          <option>Врач</option>
          <option>Ветеринар</option>
          <option>Груминг</option>
          <option>Прогулка</option>
          <option>Другое</option>
        </select>

        <label id="zoneLabel">Зона/Место</label>
        <input type="text" id="entryZone" placeholder="напр. ноги, школа №5">

        <label>Заметки</label>
        <textarea id="entryNotes" rows="2"></textarea>

        <label id="priceLabel" style="display:none">Цена (₽)</label>
        <input type="number" id="entryPrice" value="0">

        <div id="statusField" style="display:none">
          <label>Статус</label>
          <select id="entryStatus">
            <option value="new">Новая</option>
            <option value="confirmed">Подтверждена</option>
            <option value="done">Выполнено</option>
            <option value="cancelled">Отменено</option>
          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="closeModal('entryModal')">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <div id="noteModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal('noteModal')">&times;</span>
      <h3 id="noteModalTitle">Новая заметка</h3>
      <form id="noteForm" onsubmit="saveNote(event)">
        <input type="hidden" id="noteId">
        <label>Заголовок *</label>
        <input type="text" id="noteTitle" required placeholder="О чём заметка?">
        <label>Текст</label>
        <textarea id="noteText" rows="5" placeholder="Подробности..."></textarea>
        <label>Категория</label>
        <select id="noteCategory">
          <option value="general">📋 Обычная</option>
          <option value="important">⭐ Важная</option>
          <option value="shopping"> Покупки</option>
          <option value="ideas">💡 Идея</option>
          <option value="reminder">⏰ Напоминание</option>
        </select>
        <label>Дата (необязательно)</label>
        <input type="date" id="noteDate">
        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="closeModal('noteModal')">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <div id="priceModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal('priceModal')">&times;</span>
      <h3>💰 Прайс-лист</h3>
      <div id="priceList"></div>
      <button class="action-btn" onclick="addPriceItem()" style="margin-top:15px;width:100%">+ Добавить услугу</button>
    </div>
  </div>

  <div id="familyModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeModal('familyModal')">&times;</span>
      <h3>👥 Члены семьи</h3>
      <div id="familyMembersList"></div>
      <button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить члена семьи</button>
    </div>
  </div>

  <script src="app.js?v=8"></script>
</body>
</html>
HTML

echo "✅ index.html обновлён — добавлено поле выбора члена семьи"

# 2. Обновляем app.js — добавляем логику выбора члена семьи
cat > app.js << 'JSEOF'
// === ГДЕСВЕТА v5.1 — ШАГ 1: ВЫБОР ЧЛЕНА СЕМЬИ ===
const STORAGE_KEY = 'gdesveta_v5';

let state = {
  entries: [],
  notes: [],
  priceList: [],
  familyMembers: [],
  currentDate: new Date(),
  selectedDate: new Date().toISOString().split('T')[0],
  currentTab: 'calendar',
  familyFilter: 'all',
  noteFilter: 'all',
  workFilter: 'all'
};

function loadData() {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved) {
    const data = JSON.parse(saved);
    state.entries = data.entries || [];
    state.notes = data.notes || [];
    state.priceList = data.priceList || [];
    state.familyMembers = data.familyMembers || [];
  }
  
  if (state.familyMembers.length === 0) {
    state.familyMembers = [
      { id: 1, name: 'Старший ребёнок', role: 'child', age: 10, school: 'Школа №5', circles: ['Футбол', 'Английский'] },
      { id: 2, name: 'Средний ребёнок', role: 'child', age: 8, school: 'Школа №5', circles: ['Танцы', 'Рисование'] },
      { id: 3, name: 'Малыш', role: 'child', age: 1, school: 'Садик "Солнышко"', circles: [] },
      { id: 4, name: 'Муж', role: 'adult', circles: [] },
      { id: 5, name: 'Бобик', role: 'dog', breed: 'Лабрадор', circles: ['Груминг раз в 3 мес'] }
    ];
  }
  
  if (state.priceList.length === 0) {
    state.priceList = [
      { id: 1, name: 'Ноги полностью', service: 'Шугаринг', duration: 60, price: 1500 },
      { id: 2, name: 'Бикини классическое', service: 'Шугаринг', duration: 30, price: 800 },
      { id: 3, name: 'Подмышки', service: 'Шугаринг', duration: 15, price: 400 },
      { id: 4, name: 'LPG всего тела', service: 'LPG-массаж', duration: 60, price: 2000 },
      { id: 5, name: 'LPG ноги', service: 'LPG-массаж', duration: 45, price: 1200 }
    ];
  }
  
  save();
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({
    entries: state.entries,
    notes: state.notes,
    priceList: state.priceList,
    familyMembers: state.familyMembers
  }));
}

document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ ГдеСвета v5.1 — Шаг 1: Выбор члена семьи');
  loadData();
  setupTabs();
  setupCalendarControls();
  setupDurationButtons();
  setupFilters();
  renderAll();
});

function setupTabs() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      state.currentTab = btn.dataset.tab;
      document.getElementById('tab-' + state.currentTab).classList.add('active');
      
      if (state.currentTab === 'work') renderWorkEntries();
      if (state.currentTab === 'family') renderFamilyEntries();
      if (state.currentTab === 'notes') renderNotes();
      if (state.currentTab === 'stats') renderStats();
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

function setupDurationButtons() {
  document.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById('entryDuration').value = btn.dataset.min;
    });
  });
}

function setupFilters() {
  document.getElementById('workFilter').addEventListener('change', (e) => {
    state.workFilter = e.target.value;
    renderWorkEntries();
  });
  
  document.querySelectorAll('.family-filter').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.family-filter').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.familyFilter = btn.dataset.filter;
      renderFamilyEntries();
    });
  });
  
  document.querySelectorAll('.note-filter').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.note-filter').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.noteFilter = btn.dataset.filter;
      renderNotes();
    });
  });
}

function renderCalendar() {
  const grid = document.getElementById('calendar');
  const monthLabel = document.getElementById('currentMonth');
  const year = state.currentDate.getFullYear();
  const month = state.currentDate.getMonth();
  
  const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
  monthLabel.textContent = monthNames[month] + ' ' + year;
  
  const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
  let html = dayNames.map(d => '<div class="day-header">' + d + '</div>').join('');
  
  const firstDay = new Date(year, month, 1);
  const startOffset = (firstDay.getDay() + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const prevMonthDays = new Date(year, month, 0).getDate();
  
  const today = new Date().toISOString().split('T')[0];
  const hasCategory = { work: {}, family: {}, dog: {}, note: {} };
  
  state.entries.forEach(e => {
    if (e.status === 'cancelled') return;
    if (hasCategory[e.category]) hasCategory[e.category][e.date] = true;
  });
  
  state.notes.forEach(n => {
    if (n.date) hasCategory.note[n.date] = true;
  });
  
  for (let i = startOffset - 1; i >= 0; i--) {
    html += '<div class="day-cell other-month">' + (prevMonthDays - i) + '</div>';
  }
  
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = year + '-' + String(month+1).padStart(2,'0') + '-' + String(d).padStart(2,'0');
    const classes = ['day-cell'];
    
    if (dateStr === today) classes.push('today');
    if (dateStr === state.selectedDate) classes.push('selected');
    if (hasCategory.work[dateStr]) classes.push('has-work');
    if (hasCategory.family[dateStr]) classes.push('has-family');
    if (hasCategory.dog[dateStr]) classes.push('has-dog');
    if (hasCategory.note[dateStr]) classes.push('has-note');
    
    html += '<div class="' + classes.join(' ') + '" onclick="selectDate(\'' + dateStr + '\')">' + d + '</div>';
  }
  
  grid.innerHTML = html;
}

function selectDate(date) {
  state.selectedDate = date;
  renderCalendar();
  renderDayEntries();
}

function renderDayEntries() {
  const container = document.getElementById('dayEntries');
  const dayEntries = state.entries.filter(e => e.date === state.selectedDate && e.status !== 'cancelled');
  const dayNotes = state.notes.filter(n => n.date === state.selectedDate);
  
  dayEntries.sort((a, b) => a.time.localeCompare(b.time));
  
  if (dayEntries.length === 0 && dayNotes.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет записей на ' + formatDate(state.selectedDate) + '</div>';
    return;
  }
  
  let html = '<h3 style="margin:15px 0 10px;">' + formatDate(state.selectedDate) + '</h3>';
  
  dayNotes.forEach(n => {
    html += createNoteCard(n, true);
  });
  
  dayEntries.forEach(e => {
    html += createEntryCard(e);
  });
  
  container.innerHTML = html;
}

function createEntryCard(e) {
  const endTime = calcEndTime(e.time, e.duration);
  const statusLabels = { new: 'Новая', confirmed: 'Подтв.', done: 'Выполнено', cancelled: 'Отмена' };
  const categoryIcons = { work: '💼', family: '‍👩‍👧', dog: '🐕', note: '' };
  
  return '<div class="entry-card category-' + e.category + ' status-' + e.status + ' compact" data-id="' + e.id + '" onclick="toggleCard(' + e.id + ')">' +
    '<div class="entry-compact-info">' +
      '<span class="entry-compact-time">' + e.time + '-' + endTime + '</span>' +
      '<span class="entry-compact-name">' + categoryIcons[e.category] + ' ' + e.name + '</span>' +
      (e.price > 0 ? '<span class="entry-compact-price">' + e.price + '₽</span>' : '') +
      '<span class="expand-icon">▼</span>' +
    '</div>' +
    '<div class="entry-details">' +
      '<div><b>' + e.name + '</b> <span class="status-badge status-' + e.status + '">' + statusLabels[e.status] + '</span></div>' +
      '<div style="margin-top:5px;">' + e.service + (e.zone ? ' · ' + e.zone : '') + (e.phone ? ' · 📞 ' + e.phone : '') + ' · ⏱️ ' + e.duration + ' мин</div>' +
      (e.notes ? '<div style="margin-top:5px;font-style:italic;">💬 ' + e.notes + '</div>' : '') +
    '</div>' +
    '<div class="status-buttons">' +
      '<button class="status-btn ' + (e.status==='new'?'active':'') + '" onclick="event.stopPropagation();changeStatus(' + e.id + ',\'new\')">Новая</button>' +
      '<button class="status-btn ' + (e.status==='confirmed'?'active':'') + '" onclick="event.stopPropagation();changeStatus(' + e.id + ',\'confirmed\')">Подтв.</button>' +
      '<button class="status-btn ' + (e.status==='done'?'active':'') + '" onclick="event.stopPropagation();changeStatus(' + e.id + ',\'done\')">Выполн.</button>' +
      '<button class="status-btn ' + (e.status==='cancelled'?'active':'') + '" onclick="event.stopPropagation();changeStatus(' + e.id + ',\'cancelled\')">Отмена</button>' +
    '</div>' +
    '<div class="entry-actions">' +
      '<button class="btn-edit" onclick="event.stopPropagation();editEntry(' + e.id + ')">✏️ Изменить</button>' +
      '<button class="btn-dup" onclick="event.stopPropagation();duplicateEntry(' + e.id + ')">📋 Копия</button>' +
      '<button class="btn-del" onclick="event.stopPropagation();deleteEntry(' + e.id + ')">🗑️ Удалить</button>' +
    '</div>' +
  '</div>';
}

function createNoteCard(n, compact) {
  const categoryIcons = { general: '', important: '⭐', shopping: '', ideas: '💡', reminder: '⏰' };
  return '<div class="note-card ' + n.category + '">' +
    '<div class="note-title">' + categoryIcons[n.category] + ' ' + n.title + '</div>' +
    (n.text ? '<div class="note-text">' + n.text + '</div>' : '') +
    '<div class="note-meta">' +
      '<span>' + (n.date ? formatDate(n.date) : 'Без даты') + '</span>' +
      '<span>' + categoryIcons[n.category] + '</span>' +
    '</div>' +
    '<div class="note-actions">' +
      '<button class="btn-edit" onclick="editNote(' + n.id + ')">✏️</button>' +
      '<button class="btn-del" onclick="deleteNote(' + n.id + ')">🗑️</button>' +
    '</div>' +
  '</div>';
}

function toggleCard(id) {
  const card = document.querySelector('.entry-card[data-id="' + id + '"]');
  if (card) {
    card.classList.toggle('expanded');
    card.classList.toggle('compact');
  }
}

function renderWorkEntries() {
  const container = document.getElementById('workEntries');
  let workEntries = state.entries.filter(e => e.category === 'work' && e.status !== 'cancelled');
  
  const today = new Date().toISOString().split('T')[0];
  const weekLater = new Date();
  weekLater.setDate(weekLater.getDate() + 7);
  const weekLaterStr = weekLater.toISOString().split('T')[0];
  const monthLater = new Date();
  monthLater.setMonth(monthLater.getMonth() + 1);
  const monthLaterStr = monthLater.toISOString().split('T')[0];
  
  if (state.workFilter === 'today') {
    workEntries = workEntries.filter(e => e.date === today);
  } else if (state.workFilter === 'week') {
    workEntries = workEntries.filter(e => e.date >= today && e.date <= weekLaterStr);
  } else if (state.workFilter === 'month') {
    workEntries = workEntries.filter(e => e.date >= today && e.date <= monthLaterStr);
  }
  
  workEntries.sort((a, b) => a.date.localeCompare(b.date) || a.time.localeCompare(b.time));
  
  if (workEntries.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет рабочих записей</div>';
    return;
  }
  
  container.innerHTML = workEntries.map(e => createEntryCard(e)).join('');
}

function renderFamilyEntries() {
  const container = document.getElementById('familyEntries');
  let familyEntries = state.entries.filter(e => (e.category === 'family' || e.category === 'dog') && e.status !== 'cancelled');
  
  if (state.familyFilter !== 'all') {
    const filterMap = {
      school: ['Школа', 'Садик'],
      circle: ['Кружок', 'Секция'],
      doctor: ['Врач'],
      dog: ['Ветеринар', 'Груминг', 'Прогулка']
    };
    const allowed = filterMap[state.familyFilter] || [];
    familyEntries = familyEntries.filter(e => allowed.includes(e.service));
  }
  
  familyEntries.sort((a, b) => a.date.localeCompare(b.date) || a.time.localeCompare(b.time));
  
  if (familyEntries.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет семейных событий</div>';
    return;
  }
  
  container.innerHTML = familyEntries.map(e => createEntryCard(e)).join('');
}

function renderNotes() {
  const container = document.getElementById('notesList');
  let notes = state.notes;
  
  if (state.noteFilter !== 'all') {
    notes = notes.filter(n => n.category === state.noteFilter);
  }
  
  notes.sort((a, b) => (b.date || '').localeCompare(a.date || ''));
  
  if (notes.length === 0) {
    container.innerHTML = '<div class="empty-state">Нет заметок</div>';
    return;
  }
  
  container.innerHTML = notes.map(n => createNoteCard(n)).join('');
}

// === НОВАЯ ФУНКЦИЯ: Обновление списка членов семьи ===
function updateFamilyMemberSelect() {
  const select = document.getElementById('familyMemberSelect');
  const label = document.getElementById('familyMemberLabel');
  
  if (state.familyMembers.length === 0) {
    select.style.display = 'none';
    label.style.display = 'none';
    return;
  }
  
  label.style.display = 'block';
  select.style.display = 'block';
  
  select.innerHTML = '<option value="">-- Выберите члена семьи --</option>' +
    state.familyMembers.map(m => {
      const roleIcon = m.role === 'child' ? '👶' : m.role === 'dog' ? '🐕' : '';
      return '<option value="' + m.id + '">' + roleIcon + ' ' + m.name + '</option>';
    }).join('');
}

// === НОВАЯ ФУНКЦИЯ: При выборе члена семьи ===
function onFamilyMemberSelect() {
  const memberId = parseInt(document.getElementById('familyMemberSelect').value);
  if (!memberId) return;
  
  const member = state.familyMembers.find(m => m.id === memberId);
  if (!member) return;
  
  // Автозаполнение полей
  document.getElementById('entryName').value = member.name;
  
  // Если есть школа/садик — подставляем в зону
  if (member.school) {
    document.getElementById('entryZone').value = member.school;
  }
  
  // Если есть кружки — предлагаем выбрать
  if (member.circles && member.circles.length > 0) {
    const circlesText = member.circles.join(', ');
    if (confirm('У ' + member.name + ' есть кружки: ' + circlesText + '. Записать на кружок?')) {
      const circle = prompt('Какой кружок?\n' + circlesText, member.circles[0]);
      if (circle) {
        document.getElementById('entryService').value = 'Кружок';
        document.getElementById('entryZone').value = circle;
      }
    }
  }
}

function openQuickAdd() {
  document.getElementById('quickAddModal').classList.add('active');
}

function openEntryModal(category) {
  closeModal('quickAddModal');
  const modal = document.getElementById('entryModal');
  const form = document.getElementById('entryForm');
  form.reset();
  
  document.getElementById('entryModalTitle').textContent = category === 'work' ? '💼 Новая запись (работа)' : 
    category === 'dog' ? '🐕 Событие (собака)' : '👨👩‍👧 Событие (семья)';
  document.getElementById('entryId').value = '';
  document.getElementById('entryCategory').value = category;
  document.getElementById('entryDate').value = state.selectedDate;
  document.getElementById('entryDuration').value = 60;
  document.getElementById('statusField').style.display = 'none';
  
  const now = new Date();
  document.getElementById('entryTime').value = 
    String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0');
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === '60');
  });
  
  const isWork = category === 'work';
  document.getElementById('phoneLabel').style.display = isWork ? 'block' : 'none';
  document.getElementById('priceLabel').style.display = isWork ? 'block' : 'none';
  document.getElementById('zoneLabel').textContent = isWork ? 'Зона' : 'Место';
  
  // НОВОЕ: Показываем выбор члена семьи для семейных записей
  if (category === 'family' || category === 'dog') {
    updateFamilyMemberSelect();
  } else {
    document.getElementById('familyMemberLabel').style.display = 'none';
    document.getElementById('familyMemberSelect').style.display = 'none';
  }
  
  modal.classList.add('active');
}

function openNoteModal() {
  closeModal('quickAddModal');
  const modal = document.getElementById('noteModal');
  const form = document.getElementById('noteForm');
  form.reset();
  
  document.getElementById('noteModalTitle').textContent = '📝 Новая заметка';
  document.getElementById('noteId').value = '';
  document.getElementById('noteDate').value = state.selectedDate;
  
  modal.classList.add('active');
}

function closeModal(id) {
  document.getElementById(id).classList.remove('active');
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
    zone: document.getElementById('entryZone').value,
    notes: document.getElementById('entryNotes').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    status: document.getElementById('entryStatus').value || 'new',
    familyMemberId: document.getElementById('familyMemberSelect').value ? 
      parseInt(document.getElementById('familyMemberSelect').value) : null
  };
  
  if (entry.category === 'work') {
    const conflict = state.entries.find(x => 
      x.id !== entry.id && 
      x.category === 'work' &&
      x.date === entry.date && 
      x.time === entry.time && 
      x.status !== 'cancelled'
    );
    
    if (conflict) {
      if (!confirm('⚠️ На это время уже есть запись: ' + conflict.name + '. Сохранить всё равно?')) {
        return;
      }
    }
  }
  
  if (id) {
    const idx = state.entries.findIndex(x => x.id === parseInt(id));
    state.entries[idx] = entry;
  } else {
    state.entries.push(entry);
  }
  
  save();
  closeModal('entryModal');
  renderAll();
  alert('✅ Запись сохранена!');
}

function editEntry(id) {
  const entry = state.entries.find(e => e.id === id);
  if (!entry) return;
  
  openEntryModal(entry.category);
  
  document.getElementById('entryModalTitle').textContent = '✏️ Редактировать запись';
  document.getElementById('entryId').value = entry.id;
  document.getElementById('entryName').value = entry.name;
  document.getElementById('entryPhone').value = entry.phone || '';
  document.getElementById('entryDate').value = entry.date;
  document.getElementById('entryTime').value = entry.time;
  document.getElementById('entryDuration').value = entry.duration;
  document.getElementById('entryService').value = entry.service;
  document.getElementById('entryZone').value = entry.zone || '';
  document.getElementById('entryNotes').value = entry.notes || '';
  document.getElementById('entryPrice').value = entry.price;
  document.getElementById('entryStatus').value = entry.status || 'new';
  document.getElementById('statusField').style.display = 'block';
  
  // Восстанавливаем выбор члена семьи
  if (entry.familyMemberId) {
    updateFamilyMemberSelect();
    document.getElementById('familyMemberSelect').value = entry.familyMemberId;
  }
  
  document.querySelectorAll('.duration-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.min === entry.duration.toString());
  });
}

function duplicateEntry(id) {
  const entry = state.entries.find(e => e.id === id);
  if (!entry) return;
  const newEntry = { ...entry, id: Date.now(), name: entry.name + ' (копия)', status: 'new' };
  state.entries.push(newEntry);
  save();
  renderAll();
}

function deleteEntry(id) {
  if (!confirm('Удалить запись?')) return;
  state.entries = state.entries.filter(e => e.id !== id);
  save();
  renderAll();
}

function changeStatus(id, status) {
  const entry = state.entries.find(e => e.id === id);
  if (entry) {
    entry.status = status;
    save();
    renderAll();
  }
}

function saveNote(e) {
  e.preventDefault();
  const id = document.getElementById('noteId').value;
  
  const note = {
    id: id ? parseInt(id) : Date.now(),
    title: document.getElementById('noteTitle').value,
    text: document.getElementById('noteText').value,
    category: document.getElementById('noteCategory').value,
    date: document.getElementById('noteDate').value || null
  };
  
  if (id) {
    const idx = state.notes.findIndex(n => n.id === parseInt(id));
    state.notes[idx] = note;
  } else {
    state.notes.push(note);
  }
  
  save();
  closeModal('noteModal');
  renderNotes();
  alert('✅ Заметка сохранена!');
}

function editNote(id) {
  const note = state.notes.find(n => n.id === id);
  if (!note) return;
  
  openNoteModal();
  document.getElementById('noteModalTitle').textContent = '✏️ Редактировать заметку';
  document.getElementById('noteId').value = note.id;
  document.getElementById('noteTitle').value = note.title;
  document.getElementById('noteText').value = note.text || '';
  document.getElementById('noteCategory').value = note.category;
  document.getElementById('noteDate').value = note.date || '';
}

function deleteNote(id) {
  if (!confirm('Удалить заметку?')) return;
  state.notes = state.notes.filter(n => n.id !== id);
  save();
  renderNotes();
}

function showPriceList() {
  const modal = document.getElementById('priceModal');
  const container = document.getElementById('priceList');
  
  if (state.priceList.length === 0) {
    container.innerHTML = '<div class="empty-state">Прайс пуст</div>';
  } else {
    container.innerHTML = state.priceList.map(p => 
      '<div class="price-item">' +
        '<div class="price-item-info">' +
          '<div class="price-item-name">' + p.name + '</div>' +
          '<div class="price-item-details">' + p.service + ' · ' + p.duration + ' мин</div>' +
        '</div>' +
        '<div class="price-item-price">' + p.price + '₽</div>' +
        '<button class="btn-del" onclick="deletePriceItem(' + p.id + ')">️</button>' +
      '</div>'
    ).join('');
  }
  
  modal.classList.add('active');
}

function addPriceItem() {
  const name = prompt('Название услуги:');
  if (!name) return;
  const service = prompt('Тип (Шугаринг/LPG-массаж/Другое):', 'Шугаринг');
  const duration = parseInt(prompt('Длительность (мин):', '60')) || 60;
  const price = parseInt(prompt('Цена (₽):', '1000')) || 0;
  
  state.priceList.push({ id: Date.now(), name, service, duration, price });
  save();
  showPriceList();
}

function deletePriceItem(id) {
  if (!confirm('Удалить услугу из прайса?')) return;
  state.priceList = state.priceList.filter(p => p.id !== id);
  save();
  showPriceList();
}

function showFamilyMembers() {
  const modal = document.getElementById('familyModal');
  const container = document.getElementById('familyMembersList');
  
  const roleLabels = { child: '👶 Ребёнок', adult: '👤 Взрослый', dog: '🐕 Собака' };
  
  container.innerHTML = state.familyMembers.map(m => 
    '<div class="family-member">' +
      '<div class="family-member-name">' + m.name + ' <span style="font-size:12px;color:#666;">' + roleLabels[m.role] + '</span></div>' +
      '<div class="family-member-info">' +
        (m.age ? 'Возраст: ' + m.age + ' лет<br>' : '') +
        (m.school ? ' ' + m.school + '<br>' : '') +
        (m.breed ? '🐕 Порода: ' + m.breed + '<br>' : '') +
        (m.circles && m.circles.length > 0 ? '🎨 ' + m.circles.join(', ') : '') +
      '</div>' +
      '<button class="btn-del" onclick="deleteFamilyMember(' + m.id + ')" style="margin-top:8px;width:100%;">🗑️ Удалить</button>' +
    '</div>'
  ).join('');
  
  modal.classList.add('active');
}

function addFamilyMember() {
  const name = prompt('Имя:');
  if (!name) return;
  const role = prompt('Кто? (child/adult/dog):', 'child');
  const age = role === 'dog' ? null : parseInt(prompt('Возраст:', '10'));
  const school = prompt('Школа/Садик:', '');
  const breed = role === 'dog' ? prompt('Порода:', '') : null;
  const circlesStr = prompt('Кружки/Секции (через запятую):', '');
  const circles = circlesStr ? circlesStr.split(',').map(s => s.trim()) : [];
  
  state.familyMembers.push({ id: Date.now(), name, role, age, school, breed, circles });
  save();
  showFamilyMembers();
}

function deleteFamilyMember(id) {
  if (!confirm('Удалить члена семьи?')) return;
  state.familyMembers = state.familyMembers.filter(m => m.id !== id);
  save();
  showFamilyMembers();
}

function renderStats() {
  const container = document.getElementById('statsContent');
  const today = new Date().toISOString().split('T')[0];
  const activeEntries = state.entries.filter(e => e.status !== 'cancelled');
  const workEntries = activeEntries.filter(e => e.category === 'work');
  const familyEntries = activeEntries.filter(e => e.category === 'family');
  const dogEntries = activeEntries.filter(e => e.category === 'dog');
  
  const totalIncome = workEntries.reduce((s, e) => s + e.price, 0);
  const todayIncome = workEntries.filter(e => e.date === today).reduce((s, e) => s + e.price, 0);
  const weekLater = new Date();
  weekLater.setDate(weekLater.getDate() + 7);
  const weekIncome = workEntries.filter(e => e.date >= today && e.date <= weekLater.toISOString().split('T')[0]).reduce((s, e) => s + e.price, 0);
  
  container.innerHTML = 
    '<div class="stats-box">' +
      '<div class="stat-row"><span>📅 Всего записей</span><span><b>' + state.entries.length + '</b></span></div>' +
      '<div class="stat-row"><span> Работа</span><span><b>' + workEntries.length + '</b></span></div>' +
      '<div class="stat-row"><span>👨‍👩‍👧 Семья</span><span><b>' + familyEntries.length + '</b></span></div>' +
      '<div class="stat-row"><span>🐕 Собака</span><span><b>' + dogEntries.length + '</b></span></div>' +
      '<div class="stat-row"><span>📝 Заметок</span><span><b>' + state.notes.length + '</b></span></div>' +
    '</div>' +
    '<div class="stats-box">' +
      '<div class="stat-row"><span>💰 Общий доход</span><span><b>' + totalIncome + '₽</b></span></div>' +
      '<div class="stat-row"><span>📅 Сегодня</span><span><b style="color:#ff6b9d">' + todayIncome + '₽</b></span></div>' +
      '<div class="stat-row"><span>📆 На неделе</span><span><b>' + weekIncome + '₽</b></span></div>' +
    '</div>' +
    '<div class="stats-box">' +
      '<div class="stat-row"><span>✅ Выполнено</span><span><b style="color:#4caf50">' + state.entries.filter(e => e.status === 'done').length + '</b></span></div>' +
      '<div class="stat-row"><span>❌ Отменено</span><span><b style="color:#f44336">' + state.entries.filter(e => e.status === 'cancelled').length + '</b></span></div>' +
    '</div>';
}

document.addEventListener('DOMContentLoaded', () => {
  const exportBtn = document.getElementById('exportBtn');
  const importBtn = document.getElementById('importBtn');
  const importFile = document.getElementById('importFile');
  
  if (exportBtn) {
    exportBtn.addEventListener('click', () => {
      const data = JSON.stringify({
        entries: state.entries,
        notes: state.notes,
        priceList: state.priceList,
        familyMembers: state.familyMembers
      }, null, 2);
      const blob = new Blob([data], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'gdesveta_backup_' + new Date().toISOString().split('T')[0] + '.json';
      a.click();
      URL.revokeObjectURL(url);
    });
  }
  
  if (importBtn && importFile) {
    importBtn.addEventListener('click', () => importFile.click());
    importFile.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (ev) => {
        try {
          const data = JSON.parse(ev.target.result);
          if (confirm('Импортировать данные? Текущие будут заменены.')) {
            state.entries = data.entries || [];
            state.notes = data.notes || [];
            state.priceList = data.priceList || [];
            state.familyMembers = data.familyMembers || [];
            save();
            renderAll();
            alert('✅ Импорт выполнен');
          }
        } catch (err) {
          alert('❌ Ошибка: ' + err.message);
        }
      };
      reader.readAsText(file);
    });
  }
});

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

function renderAll() {
  renderCalendar();
  renderDayEntries();
  if (state.currentTab === 'work') renderWorkEntries();
  if (state.currentTab === 'family') renderFamilyEntries();
  if (state.currentTab === 'notes') renderNotes();
  if (state.currentTab === 'stats') renderStats();
}
JSEOF

echo "✅ app.js обновлён — добавлена логика выбора члена семьи"

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
echo "✅ ШАГ 1 ЗАВЕРШЁН!"
echo ""
echo "🧪 ТЕСТ:"
echo "1. Нажми '+ Добавить' → 'Семья'"
echo "2. Появится список членов семьи"
echo "3. Выбери 'Старший ребёнок'"
echo "4. Имя и школа подставятся автоматически"
echo "5. Если есть кружки — предложит выбрать"
echo ""
echo "Протестируй и скажи результат!"
