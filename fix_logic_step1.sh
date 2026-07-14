#!/bin/bash
echo "🔧 ШАГ 1: Убираю демо-данные и делаю контекстную кнопку"

# 1. УБИРАЕМ ДЕМО-ДАННЫЕ
echo "1. 🗑️ Убираю демо-данные..."

cat > app.js << 'APPJS'
/**
 * APP.JS v3.0 - БЕЗ ДЕМО-ДАННЫХ, КОНТЕКСТНАЯ КНОПКА
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log(' ГдеСвета v3.0 запускается...');
  
  Store.init();
  
  // НЕ создаём демо-данные! Пользователь начинает с чистого листа
  
  setupTabs();
  setupExportImport();
  
  CalendarView.init('calendarView');
  WorkView.init('workView');
  FamilyView.init('familyView');
  if (typeof TasksView !== 'undefined') TasksView.init('tasksView');
  NotesView.init('notesView');
  StatsView.init('statsView');
  
  if (typeof NotificationService !== 'undefined') {
    NotificationService.init();
  }
  
  initTheme();
  setupEventListeners();
  
  console.log('✅ Приложение готово! Чистый старт.');
});

function setupTabs() {
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      btn.classList.add('active');
      currentTab = btn.dataset.tab;
      document.getElementById('tab-' + currentTab).classList.add('active');
    });
  });
}

function setupExportImport() {
  const exportBtn = document.getElementById('exportBtn');
  const importBtn = document.getElementById('importBtn');
  const importFile = document.getElementById('importFile');
  
  if (exportBtn) {
    exportBtn.addEventListener('click', () => {
      const data = {
        entries: Store.getEntries(),
        notes: Store.getNotes(),
        priceList: Store.getPriceList(),
        familyMembers: Store.getFamilyMembers(),
        tasks: FamilyShare.getTasks()
      };
      const json = JSON.stringify(data, null, 2);
      const blob = new Blob([json], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'gdesveta_backup_' + Utils.getToday() + '.json';
      a.click();
      URL.revokeObjectURL(url);
      Modal.alert('✅ Данные экспортированы!');
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
          Modal.confirm('Импортировать данные?', () => {
            Store.importData(data);
            if (data.tasks) {
              Storage.set('gdesveta_family_tasks', data.tasks);
            }
            Modal.alert('✅ Импорт выполнен!');
            location.reload();
          });
        } catch (error) {
          Modal.alert('❌ Ошибка: ' + error.message);
        }
      };
      reader.readAsText(file);
    });
  }
}

function setupEventListeners() {
  Events.on('entry:edit', (id) => openEntryForm(id));
  Events.on('note:edit', (id) => openNoteForm(id));
}

// === ТЁМНАЯ ТЕМА ===
function initTheme() {
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) toggle.textContent = '☀️';
  }
  
  if (toggle) {
    toggle.addEventListener('click', () => {
      body.classList.add('theme-transition');
      body.classList.toggle('dark-theme');
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      toggle.textContent = isDark ? '☀️' : '🌙';
      setTimeout(() => body.classList.remove('theme-transition'), 300);
    });
  }
}

// === КОНТЕКСТНАЯ КНОПКА ДОБАВЛЕНИЯ ===
function openQuickAdd() {
  // Определяем текущую вкладку и открываем нужную форму
  if (currentTab === 'work') {
    openWorkForm();
  } else if (currentTab === 'family') {
    openFamilyForm();
  } else if (currentTab === 'tasks') {
    openTaskForm();
  } else if (currentTab === 'notes') {
    openNoteForm();
  } else {
    // На календаре или статистике - спрашиваем
    const content = `
      <div class="quick-add-grid">
        <button class="quick-add-btn work" onclick="openWorkForm()">
          <span class="quick-add-icon">💼</span><span>Работа</span>
        </button>
        <button class="quick-add-btn family" onclick="openFamilyForm()">
          <span class="quick-add-icon">👨‍‍👧</span><span>Семья</span>
        </button>
        <button class="quick-add-btn note" onclick="openNoteForm()">
          <span class="quick-add-icon">📝</span><span>Заметка</span>
        </button>
        <button class="quick-add-btn" style="border-color:#4a90e2;" onclick="openTaskForm()">
          <span class="quick-add-icon">✅</span><span>Задача</span>
        </button>
      </div>
    `;
    Modal.form({ title: 'Что добавляем?', content });
  }
}

// === ФОРМА РАБОЧЕЙ ЗАПИСИ ===
function openWorkForm(id = null) {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
  }
  
  const content = `
    <form id="workForm" onsubmit="return handleWorkSubmit(event)">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="work">
      
      <label>Имя клиента *</label>
      <input type="text" id="clientName" value="${entry ? entry.name : ''}" required placeholder="Напр. Мария">
      
      <label>Телефон</label>
      <input type="tel" id="clientPhone" value="${entry ? entry.phone : ''}" placeholder="+7 (999) 999-99-99">
      
      <label>Услуга *</label>
      <select id="serviceType" required>
        <option value="Шугаринг" ${entry && entry.service === 'Шугаринг' ? 'selected' : ''}>Шугаринг</option>
        <option value="LPG-массаж" ${entry && entry.service === 'LPG-массаж' ? 'selected' : ''}>LPG-массаж</option>
        <option value="Другое" ${entry && entry.service === 'Другое' ? 'selected' : ''}>Другое</option>
      </select>
      
      <label>Зона</label>
      <input type="text" id="serviceZone" value="${entry ? entry.zone : ''}" placeholder="Напр. Ноги полностью + Бикини">
      
      <label>Дата *</label>
      <input type="date" id="entryDate" value="${entry ? entry.date : Calendar.getSelectedDate()}" required>
      
      <label>Время *</label>
      <input type="time" id="entryTime" value="${entry ? entry.time : Utils.getNow()}" required>
      
      <label>Длительность (мин)</label>
      <div class="duration-row">
        <button type="button" class="duration-btn" data-min="30" onclick="setDuration(30)">30</button>
        <button type="button" class="duration-btn active" data-min="60" onclick="setDuration(60)">60</button>
        <button type="button" class="duration-btn" data-min="90" onclick="setDuration(90)">90</button>
        <button type="button" class="duration-btn" data-min="120" onclick="setDuration(120)">120</button>
      </div>
      <input type="hidden" id="entryDuration" value="${entry ? entry.duration : 60}">
      
      <label>Цена (₽)</label>
      <input type="number" id="entryPrice" value="${entry ? entry.price : 0}">
      
      <label>Заметки</label>
      <textarea id="entryNotes" rows="2">${entry ? entry.notes : ''}</textarea>
      
      ${id ? `
        <label>Статус</label>
        <select id="entryStatus">
          <option value="new" ${entry && entry.status === 'new' ? 'selected' : ''}>Новая</option>
          <option value="confirmed" ${entry && entry.status === 'confirmed' ? 'selected' : ''}>Подтверждена</option>
          <option value="done" ${entry && entry.status === 'done' ? 'selected' : ''}>Выполнена</option>
          <option value="cancelled" ${entry && entry.status === 'cancelled' ? 'selected' : ''}>Отменена</option>
        </select>
      ` : ''}
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({
    title: id ? '✏️ Редактировать запись' : '💼 Новая запись (работа)',
    content
  });
}

window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const id = document.getElementById('entryId').value;
  const data = {
    category: 'work',
    name: document.getElementById('clientName').value,
    phone: document.getElementById('clientPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('serviceType').value,
    zone: document.getElementById('serviceZone').value,
    notes: document.getElementById('entryNotes').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    status: document.getElementById('entryStatus')?.value || 'new'
  };
  
  try {
    if (id) {
      EntryService.update(parseInt(id), data);
    } else {
      EntryService.create(data);
    }
    
    Modal.close();
    setTimeout(() => {
      Modal.alert('✅ Запись сохранена!');
      WorkView.render();
      CalendarView.render();
    }, 100);
    
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  
  return false;
};

// === ФОРМА СЕМЕЙНОЙ ЗАПИСИ ===
function openFamilyForm(id = null) {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
  }
  
  const members = FamilyService.getAll().filter(m => m.role === 'child');
  let memberOptions = '<option value="">-- Выберите ребёнка --</option>';
  members.forEach(m => {
    const selected = entry && entry.familyMemberId === m.id ? 'selected' : '';
    memberOptions += `<option value="${m.id}" ${selected}>${m.name}</option>`;
  });
  
  const content = `
    <form id="familyForm" onsubmit="return handleFamilySubmit(event)">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="family">
      
      <label>Ребёнок *</label>
      <select id="familyMemberId" required>
        ${memberOptions}
      </select>
      
      <label>Тип события *</label>
      <select id="eventType" required>
        <option value="Школа" ${entry && entry.service === 'Школа' ? 'selected' : ''}> Школа</option>
        <option value="Садик" ${entry && entry.service === 'Садик' ? 'selected' : ''}> Садик</option>
        <option value="Кружок" ${entry && entry.service === 'Кружок' ? 'selected' : ''}>🎨 Кружок</option>
        <option value="Секция" ${entry && entry.service === 'Секция' ? 'selected' : ''}>⚽ Секция</option>
        <option value="Врач" ${entry && entry.service === 'Врач' ? 'selected' : ''}>🏥 Врач</option>
        <option value="Другое" ${entry && entry.service === 'Другое' ? 'selected' : ''}>📌 Другое</option>
      </select>
      
      <label>Дата *</label>
      <input type="date" id="entryDate" value="${entry ? entry.date : Calendar.getSelectedDate()}" required>
      
      <label>Время начала *</label>
      <input type="time" id="entryTime" value="${entry ? entry.time : '08:00'}" required>
      
      <label>Время окончания *</label>
      <input type="time" id="endTime" value="${entry ? Utils.calcEndTime(entry.time, entry.duration) : '13:00'}" required>
      
      <label>Место</label>
      <input type="text" id="eventLocation" value="${entry ? entry.zone : ''}" placeholder="Напр. Школа №5, каб. 12">
      
      <label>Заметки</label>
      <textarea id="entryNotes" rows="2">${entry ? entry.notes : ''}</textarea>
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({
    title: id ? '✏️ Редактировать событие' : '👨‍👩👧 Новое событие (семья)',
    content
  });
}

window.handleFamilySubmit = function(e) {
  e.preventDefault();
  
  const id = document.getElementById('entryId').value;
  const startTime = document.getElementById('entryTime').value;
  const endTime = document.getElementById('endTime').value;
  
  // Вычисляем длительность
  const startMins = Utils.timeToMinutes(startTime);
  const endMins = Utils.timeToMinutes(endTime);
  const duration = endMins - startMins;
  
  const data = {
    category: 'family',
    name: document.getElementById('eventType').value,
    date: document.getElementById('entryDate').value,
    time: startTime,
    duration: duration > 0 ? duration : 60,
    service: document.getElementById('eventType').value,
    zone: document.getElementById('eventLocation').value,
    notes: document.getElementById('entryNotes').value,
    familyMemberId: parseInt(document.getElementById('familyMemberId').value) || null,
    price: 0,
    status: 'new'
  };
  
  try {
    if (id) {
      EntryService.update(parseInt(id), data);
    } else {
      EntryService.create(data);
    }
    
    Modal.close();
    setTimeout(() => {
      Modal.alert('✅ Событие сохранено!');
      FamilyView.render();
      CalendarView.render();
    }, 100);
    
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  
  return false;
};

// === ФОРМА ЗАМЕТКИ ===
function openNoteForm(id = null) {
  let note = null;
  if (id) {
    note = Store.getNotes().find(n => n.id === id);
    if (!note) return;
  }
  
  const content = `
    <form id="noteForm" onsubmit="return handleNoteSubmit(event)">
      <input type="hidden" id="noteId" value="${id || ''}">
      <label>Заголовок *</label>
      <input type="text" id="noteTitle" value="${note ? note.title : ''}" required>
      <label>Текст</label>
      <textarea id="noteText" rows="5">${note ? note.text : ''}</textarea>
      <label>Категория</label>
      <select id="noteCategory">
        <option value="general" ${note && note.category === 'general' ? 'selected' : ''}>📋 Обычная</option>
        <option value="important" ${note && note.category === 'important' ? 'selected' : ''}>⭐ Важная</option>
        <option value="shopping" ${note && note.category === 'shopping' ? 'selected' : ''}>🛒 Покупки</option>
        <option value="ideas" ${note && note.category === 'ideas' ? 'selected' : ''}>💡 Идея</option>
        <option value="reminder" ${note && note.category === 'reminder' ? 'selected' : ''}> Напоминание</option>
      </select>
      <label>Дата</label>
      <input type="date" id="noteDate" value="${note ? note.date || '' : Calendar.getSelectedDate()}">
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({
    title: id ? '️ Редактировать заметку' : ' Новая заметка',
    content
  });
}

window.handleNoteSubmit = function(e) {
  e.preventDefault();
  const id = document.getElementById('noteId').value;
  const data = {
    title: document.getElementById('noteTitle').value,
    text: document.getElementById('noteText').value,
    category: document.getElementById('noteCategory').value,
    date: document.getElementById('noteDate').value || null
  };
  try {
    if (id) NoteService.update(parseInt(id), data);
    else NoteService.create(data);
    Modal.close();
    setTimeout(() => Modal.alert('✅ Заметка сохранена!'), 100);
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  return false;
};

// === ФОРМА ЗАДАЧИ ===
function openTaskForm() {
  const content = `
    <form id="taskForm" onsubmit="return handleTaskSubmit(event)">
      <label>Задача *</label>
      <input type="text" id="taskText" required placeholder="Что нужно сделать?">
      <label>Категория</label>
      <select id="taskCategory">
        <option value="general"> Обычная</option>
        <option value="shopping">🛒 Покупки</option>
        <option value="home">🏠 Дом</option>
        <option value="kids"> Дети</option>
        <option value="dog">🐕 Собака</option>
        <option value="important">⭐ Важная</option>
      </select>
      <label>Кому поручить (необязательно)</label>
      <input type="text" id="taskAssigned" placeholder="Напр. Муж, Старший">
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  Modal.form({ title: '✅ Новая задача', content });
}

window.handleTaskSubmit = function(e) {
  e.preventDefault();
  const data = {
    text: document.getElementById('taskText').value,
    category: document.getElementById('taskCategory').value,
    assignedTo: document.getElementById('taskAssigned').value || null
  };
  FamilyShare.addTask(data);
  Modal.close();
  setTimeout(() => Modal.alert('✅ Задача добавлена!'), 100);
  return false;
};

// === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
window.setDuration = function(mins) {
  document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`.duration-btn[data-min="${mins}"]`).classList.add('active');
  document.getElementById('entryDuration').value = mins;
};

window.deleteEntry = function(id) {
  Modal.confirm('Удалить эту запись?', () => {
    try {
      EntryService.delete(id);
      Modal.close();
      setTimeout(() => {
        Modal.alert('✅ Запись удалена!');
        if (currentTab === 'calendar') CalendarView.render();
        else if (currentTab === 'work') WorkView.render();
        else if (currentTab === 'family') FamilyView.render();
      }, 100);
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
};

window.clearAllData = function() {
  Modal.confirm(
    '⚠️ ВНИМАНИЕ! Это удалит ВСЕ данные:\n\n• Все записи\n• Все заметки\n• Все задачи\n• Все шаблоны\n\nПродолжить?',
    () => {
      localStorage.clear();
      Modal.close();
      setTimeout(() => {
        Modal.alert('✅ Все данные удалены. Страница перезагрузится...');
        setTimeout(() => {
          location.reload();
        }, 1500);
      }, 100);
    }
  );
};

function showPriceList() {
  const items = PriceService.getAll();
  let content = items.length === 0 ? '<div class="empty-state">Прайс пуст. Добавь первую услугу!</div>' :
    items.map(item => `
      <div class="price-item">
        <div class="price-item-info">
          <div class="price-item-name">${item.name}</div>
          <div class="price-item-details">${item.service} · ${PriceItem.getFormattedDuration(item.duration)}</div>
        </div>
        <div class="price-item-price">${PriceItem.getFormattedPrice(item.price)}</div>
        <button class="btn-del" onclick="deletePriceItem(${item.id})">🗑️</button>
      </div>
    `).join('');
  content += `<button class="action-btn" onclick="addPriceItem()" style="margin-top:15px;width:100%">+ Добавить услугу</button>`;
  Modal.form({ title: '💰 Прайс-лист', content });
}

window.addPriceItem = function() {
  Modal.close();
  setTimeout(() => {
    const name = prompt('Название услуги:'); if (!name) return;
    const service = prompt('Тип (Шугаринг/LPG-массаж):', 'Шугаринг');
    const duration = parseInt(prompt('Длительность (мин):', '60')) || 60;
    const price = parseInt(prompt('Цена (₽):', '1000')) || 0;
    try {
      PriceService.create({ name, service, duration, price });
      Modal.alert('✅ Услуга добавлена!');
      setTimeout(showPriceList, 200);
    } catch (error) { Modal.alert('❌ ' + error.message); }
  }, 100);
};

window.deletePriceItem = function(id) {
  Modal.confirm('Удалить услугу?', () => { 
    PriceService.delete(id); 
    Modal.close(); 
    setTimeout(showPriceList, 100);
  });
};

function showFamilyMembers() {
  const members = FamilyService.getAll();
  const roleLabels = { child: '👶 Ребёнок', adult: '👤 Взрослый', dog: '🐕 Собака' };
  let content = members.length === 0 ? '<div class="empty-state">Нет членов семьи. Добавь первого!</div>' :
    members.map(m => `
      <div class="family-member">
        <div class="family-member-name">${m.name} <span style="font-size:12px;color:#666;">${roleLabels[m.role]}</span></div>
        <div class="family-member-info">
          ${m.age ? 'Возраст: ' + m.age + ' лет<br>' : ''}
          ${m.school ? '🏫 ' + m.school + '<br>' : ''}
          ${m.breed ? '🐕 Порода: ' + m.breed + '<br>' : ''}
          ${m.circles && m.circles.length > 0 ? '🎨 ' + FamilyMember.getCirclesText(m.circles) : ''}
        </div>
        <button class="btn-del" onclick="deleteFamilyMember(${m.id})" style="margin-top:8px;width:100%;">🗑️ Удалить</button>
      </div>
    `).join('');
  content += `<button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить члена семьи</button>`;
  Modal.form({ title: '👥 Члены семьи', content });
}

window.addFamilyMember = function() {
  Modal.close();
  setTimeout(() => {
    const name = prompt('Имя:'); if (!name) return;
    const role = prompt('Кто? (child/adult/dog):', 'child');
    const age = role === 'dog' ? null : parseInt(prompt('Возраст:', '10'));
    const school = prompt('Школа/Садик:', '');
    const breed = role === 'dog' ? prompt('Порода:', '') : null;
    const circlesStr = prompt('Кружки (через запятую):', '');
    const circles = circlesStr ? circlesStr.split(',').map(s => s.trim()) : [];
    try {
      FamilyService.create({ name, role, age, school, breed, circles });
      Modal.alert('✅ Добавлено!');
      setTimeout(showFamilyMembers, 200);
    } catch (error) { Modal.alert('❌ ' + error.message); }
  }, 100);
};

window.deleteFamilyMember = function(id) {
  Modal.confirm('Удалить члена семьи?', () => { 
    FamilyService.delete(id); 
    Modal.close(); 
    setTimeout(showFamilyMembers, 100);
  });
};

console.log('✅ app.js v3.0 загружен');
APPJS

echo "✅ app.js v3.0 создан - без демо-данных, с контекстной кнопкой"

# 2. ОБНОВЛЯЕМ index.html
echo "2. 🔄 Обновляю index.html..."

cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="styles/main.css?v=3">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <button class="theme-toggle" id="themeToggle" title="Переключить тему">🌙</button>
      <nav>
        <button class="nav-btn active" data-tab="calendar">📅</button>
        <button class="nav-btn" data-tab="work">💼</button>
        <button class="nav-btn" data-tab="family">👨‍👩‍👧</button>
        <button class="nav-btn" data-tab="tasks">✅</button>
        <button class="nav-btn" data-tab="notes">📝</button>
        <button class="nav-btn" data-tab="stats">📊</button>
      </nav>
    </header>

    <main>
      <div id="tab-calendar" class="tab-content active">
        <div id="calendarView"></div>
      </div>

      <div id="tab-work" class="tab-content">
        <div class="tab-header">
          <h2>💼 Работа</h2>
          <button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>
        </div>
        <div id="workView"></div>
      </div>

      <div id="tab-family" class="tab-content">
        <div class="tab-header">
          <h2>‍👩‍👧 Семья</h2>
          <button class="tab-action-btn" onclick="showFamilyMembers()">👥 Семья</button>
        </div>
        <div id="familyView"></div>
      </div>

      <div id="tab-tasks" class="tab-content">
        <div class="tab-header">
          <h2>✅ Семейные задачи</h2>
          <button class="tab-action-btn" onclick="openTaskForm()">+ Задача</button>
        </div>
        <div id="tasksView"></div>
      </div>

      <div id="tab-notes" class="tab-content">
        <div class="tab-header">
          <h2>📝 Заметки</h2>
          <button class="tab-action-btn" onclick="openNoteForm()">+ Новая</button>
        </div>
        <div id="notesView"></div>
      </div>

      <div id="tab-stats" class="tab-content">
        <h2>📊 Статистика</h2>
        <div id="statsView"></div>
        <div class="stats-actions">
          <button onclick="clearAllData()" style="background:#ffebee;color:#d32f2f;margin-right:5px;">🗑️ Очистить</button>
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <button id="pinBtn" class="action-btn" onclick="openPinSettings()">🔐 PIN</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>

    <button class="add-btn-fixed" onclick="openQuickAdd()">+ Добавить</button>
  </div>

  <div id="notificationContainer"></div>
  <div id="modalContainer"></div>

  <script src="src/core/storage.js?v=3"></script>
  <script src="src/core/events.js?v=3"></script>
  <script src="src/core/utils.js?v=3"></script>
  <script src="src/core/store.js?v=3"></script>
  
  <script src="src/models/Entry.js?v=3"></script>
  <script src="src/models/Note.js?v=3"></script>
  <script src="src/models/PriceItem.js?v=3"></script>
  <script src="src/models/FamilyMember.js?v=3"></script>
  
  <script src="src/services/EntryService.js?v=3"></script>
  <script src="src/services/NoteService.js?v=3"></script>
  <script src="src/services/PriceService.js?v=3"></script>
  <script src="src/services/FamilyService.js?v=3"></script>
  <script src="src/services/ConflictChecker.js?v=3"></script>
  <script src="src/services/NotificationService.js?v=3"></script>
  <script src="src/services/FamilyShare.js?v=3"></script>
  <script src="src/services/TemplateService.js?v=3"></script>
  
  <script src="src/ui/components/Modal.js?v=3"></script>
  <script src="src/ui/components/Calendar.js?v=3"></script>
  <script src="src/ui/components/EntryCard.js?v=3"></script>
  <script src="src/ui/components/NoteCard.js?v=3"></script>
  <script src="src/ui/components/FamilySelect.js?v=3"></script>
  
  <script src="src/views/CalendarView.js?v=3"></script>
  <script src="src/views/WorkView.js?v=3"></script>
  <script src="src/views/FamilyView.js?v=3"></script>
  <script src="src/views/NotesView.js?v=3"></script>
  <script src="src/views/StatsView.js?v=3"></script>
  <script src="src/views/TasksView.js?v=3"></script>
  
  <script src="app.js?v=3"></script>
</body>
</html>
HTML

echo "✅ index.html обновлён"

# 3. ПЕРЕЗАПУСК
echo ""
echo "3. 🚀 Перезапуск..."

pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ ШАГ 1 ЗАВЕРШЁН!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО ИЗМЕНЕНО:"
echo "  1. ✅ НЕТ демо-данных - чистый старт"
echo "  2. ✅ Контекстная кнопка + Добавить"
echo "     • На вкладке Работа → форма работы"
echo "     • На вкладке Семья → форма семьи"
echo "     • На вкладке Заметки → форма заметки"
echo "     • На Календаре → спрашивает что добавить"
echo "  3. ✅ Разные формы:"
echo "     • Работа: клиент, телефон, услуга, зона, длительность, цена"
echo "     • Семья: ребёнок, тип события, время начала/конца, место"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Открой вкладку Работа → нажми + Добавить"
echo "   → Должна открыться форма РАБОТЫ"
echo ""
echo "2. Открой вкладку Семья → нажми + Добавить"
echo "   → Должна открыться форма СЕМЬИ"
echo ""
echo "3. Календарь пустой (нет демо-данных)"
echo ""
echo "Напиши 'работает' или опиши что не так!"
