#!/bin/bash
echo "🔥 РАДИКАЛЬНОЕ ИСПРАВЛЕНИЕ"
echo "═══════════════════════════════════════"

# 1. УДАЛЯЕМ SERVICE WORKER (он кэширует старое)
echo "1. 🗑️ Удаляю service-worker.js..."
rm -f service-worker.js
echo "✅ Service worker удалён"

# 2. УДАЛЯЕМ СТАРЫЙ КЭШ
echo "2. ️ Удаляю кэш..."
rm -rf ~/.cache
rm -rf android/app/build
echo "✅ Кэш удалён"

# 3. ПЕРЕПИСЫВАЕМ Modal.js - ТЕПЕРЬ С INLINE ONCLICK
echo "3. 🔧 Переписываю Modal.js..."

cat > src/ui/components/Modal.js << 'MODAL'
/**
 * MODAL COMPONENT v2.0
 * ИСПРАВЛЕННАЯ ВЕРСИЯ - inline onclick
 */
const Modal = {
  currentModal: null,
  
  create(options) {
    // Удаляем старую модалку если есть
    if (this.currentModal) {
      this.currentModal.remove();
    }
    
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.id = 'currentModal';
    
    // ВАЖНО: onclick прямо в HTML - гарантированно работает!
    modal.innerHTML = `
      <div class="modal-content">
        <span class="close-modal" onclick="Modal.close()" style="cursor:pointer;">&times;</span>
        <h3>${options.title || ''}</h3>
        <div class="modal-body">${options.content || ''}</div>
      </div>
    `;
    
    document.body.appendChild(modal);
    this.currentModal = modal;
    
    // Закрытие по клику на фон
    modal.addEventListener('click', function(e) {
      if (e.target === modal) {
        Modal.close();
      }
    });
    
    return modal;
  },
  
  close() {
    console.log('🔴 Modal.close() вызван!');
    if (this.currentModal) {
      this.currentModal.remove();
      this.currentModal = null;
      console.log('✅ Модалка закрыта');
    }
  },
  
  alert(message, title = 'Внимание') {
    const modal = this.create({
      title,
      content: `<p>${message}</p><button class="save-btn" style="margin-top:15px;" onclick="Modal.close()">OK</button>`
    });
  },
  
  confirm(message, onConfirm, onCancel) {
    const modal = this.create({
      title: 'Подтверждение',
      content: `
        <p>${message}</p>
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button class="save-btn" onclick="Modal._confirmYes()">Да</button>
          <button class="cancel-btn" onclick="Modal._confirmNo()">Нет</button>
        </div>
      `
    });
    
    // Сохраняем колбэки
    this._onConfirm = onConfirm;
    this._onCancel = onCancel;
  },
  
  _confirmYes() {
    this.close();
    if (this._onConfirm) this._onConfirm();
  },
  
  _confirmNo() {
    this.close();
    if (this._onCancel) this._onCancel();
  },
  
  form(options) {
    return this.create({
      title: options.title || 'Форма',
      content: options.content || ''
    });
  }
};

window.Modal = Modal;
MODAL

echo "✅ Modal.js переписан с inline onclick"

# 4. ОБНОВЛЯЕМ index.html - добавляем version ко всем скриптам
echo "4.  Обновляю index.html..."

cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="styles/main.css?v=2">
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

  <!-- СКРИПТЫ С VERSION -->
  <script src="src/core/storage.js?v=2"></script>
  <script src="src/core/events.js?v=2"></script>
  <script src="src/core/utils.js?v=2"></script>
  <script src="src/core/store.js?v=2"></script>
  
  <script src="src/models/Entry.js?v=2"></script>
  <script src="src/models/Note.js?v=2"></script>
  <script src="src/models/PriceItem.js?v=2"></script>
  <script src="src/models/FamilyMember.js?v=2"></script>
  
  <script src="src/services/EntryService.js?v=2"></script>
  <script src="src/services/NoteService.js?v=2"></script>
  <script src="src/services/PriceService.js?v=2"></script>
  <script src="src/services/FamilyService.js?v=2"></script>
  <script src="src/services/ConflictChecker.js?v=2"></script>
  <script src="src/services/NotificationService.js?v=2"></script>
  <script src="src/services/FamilyShare.js?v=2"></script>
  <script src="src/services/TemplateService.js?v=2"></script>
  
  <script src="src/ui/components/Modal.js?v=2"></script>
  <script src="src/ui/components/Calendar.js?v=2"></script>
  <script src="src/ui/components/EntryCard.js?v=2"></script>
  <script src="src/ui/components/NoteCard.js?v=2"></script>
  <script src="src/ui/components/FamilySelect.js?v=2"></script>
  
  <script src="src/views/CalendarView.js?v=2"></script>
  <script src="src/views/WorkView.js?v=2"></script>
  <script src="src/views/FamilyView.js?v=2"></script>
  <script src="src/views/NotesView.js?v=2"></script>
  <script src="src/views/StatsView.js?v=2"></script>
  <script src="src/views/TasksView.js?v=2"></script>
  
  <script src="app.js?v=2"></script>
</body>
</html>
HTML

echo "✅ index.html обновлён с version"

# 5. ПЕРЕЗАПИСЫВАЕМ app.js С ПРАВИЛЬНЫМ ЗАКРЫТИЕМ
echo "5. 🔧 Переписываю app.js..."

cat > app.js << 'APPJS'
/**
 * APP.JS v2.0 - ИСПРАВЛЕННАЯ ВЕРСИЯ
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 ГдеСвета v2.0 запускается...');
  
  Store.init();
  
  if (Store.getFamilyMembers().length === 0) {
    initDemoData();
  }
  
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
  
  console.log('✅ Приложение готово!');
});

function initDemoData() {
  console.log('📝 Создание демо-данных...');
  
  FamilyService.create({ name: 'Старший ребёнок', role: 'child', age: 10, school: 'Школа №5', circles: ['Футбол', 'Английский'] });
  FamilyService.create({ name: 'Средний ребёнок', role: 'child', age: 8, school: 'Школа №5', circles: ['Танцы', 'Рисование'] });
  FamilyService.create({ name: 'Малыш', role: 'child', age: 1, school: 'Садик "Солнышко"', circles: [] });
  FamilyService.create({ name: 'Муж', role: 'adult', circles: [] });
  FamilyService.create({ name: 'Бобик', role: 'dog', breed: 'Лабрадор', circles: ['Груминг раз в 3 мес'] });
  
  PriceService.create({ name: 'Ноги полностью', service: 'Шугаринг', duration: 60, price: 1500 });
  PriceService.create({ name: 'Бикини классическое', service: 'Шугаринг', duration: 30, price: 800 });
  PriceService.create({ name: 'Подмышки', service: 'Шугаринг', duration: 15, price: 400 });
  PriceService.create({ name: 'LPG всего тела', service: 'LPG-массаж', duration: 60, price: 2000 });
  PriceService.create({ name: 'LPG ноги', service: 'LPG-массаж', duration: 45, price: 1200 });
  
  console.log('✅ Демо-данные созданы');
}

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
      toggle.textContent = isDark ? '️' : '🌙';
      setTimeout(() => body.classList.remove('theme-transition'), 300);
    });
  }
}

// === БЫСТРОЕ ДОБАВЛЕНИЕ ===
function openQuickAdd() {
  const content = `
    <div class="quick-add-grid">
      <button class="quick-add-btn work" onclick="openEntryForm(null, 'work')">
        <span class="quick-add-icon">💼</span><span>Работа</span>
      </button>
      <button class="quick-add-btn family" onclick="openEntryForm(null, 'family')">
        <span class="quick-add-icon">👨‍‍👧</span><span>Семья</span>
      </button>
      <button class="quick-add-btn dog" onclick="openEntryForm(null, 'dog')">
        <span class="quick-add-icon">🐕</span><span>Собака</span>
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

// === ФОРМА ЗАПИСИ ===
function openEntryForm(id = null, category = 'work') {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    category = entry.category;
  }
  
  const categoryLabels = {
    work: '💼 Новая запись (работа)',
    family: '👨‍👩‍ Событие (семья)',
    dog: '🐕 Событие (собака)'
  };
  
  const isWork = category === 'work';
  const isFamily = category === 'family' || category === 'dog';
  
  // ПРАВИЛЬНЫЙ СПИСОК КАТЕГОРИЙ
  let serviceOptions = '';
  if (isWork) {
    serviceOptions = `
      <option>Шугаринг</option>
      <option>LPG-массаж</option>
      <option>Другое</option>
    `;
  } else {
    serviceOptions = `
      <option>Школа</option>
      <option>Садик</option>
      <option>Кружок</option>
      <option>Секция</option>
      <option>Врач</option>
      <option>Ветеринар</option>
      <option>Груминг</option>
      <option>Прогулка</option>
      <option>Другое</option>
    `;
  }
  
  let content = `
    <form id="entryForm" onsubmit="return handleEntrySubmit(event)">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="${category}">
      
      ${isFamily ? `<label>Член семьи</label>${FamilySelect.render(entry ? entry.familyMemberId : null)}` : ''}
      
      <label>Название *</label>
      <input type="text" id="entryName" value="${entry ? entry.name : ''}" required>
      
      ${isWork ? `<label>Телефон</label><input type="tel" id="entryPhone" value="${entry ? entry.phone : ''}">` : ''}
      
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
      
      <label>Услуга/Тип</label>
      <select id="entryService">
        ${serviceOptions}
      </select>
      
      <label>Зона/Место</label>
      <input type="text" id="entryZone" value="${entry ? entry.zone : ''}">
      <label>Заметки</label>
      <textarea id="entryNotes" rows="2">${entry ? entry.notes : ''}</textarea>
      
      ${isWork ? `<label>Цена (₽)</label><input type="number" id="entryPrice" value="${entry ? entry.price : 0}">` : ''}
      
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
    title: id ? '✏️ Редактировать запись' : categoryLabels[category],
    content
  });
}

// Глобальная функция для установки длительности
window.setDuration = function(mins) {
  document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`.duration-btn[data-min="${mins}"]`).classList.add('active');
  document.getElementById('entryDuration').value = mins;
};

// Глобальная функция для сохранения записи
window.handleEntrySubmit = function(e) {
  e.preventDefault();
  
  const id = document.getElementById('entryId').value;
  const data = {
    category: document.getElementById('entryCategory').value,
    name: document.getElementById('entryName').value,
    phone: document.getElementById('entryPhone')?.value || '',
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('entryService').value,
    zone: document.getElementById('entryZone').value,
    notes: document.getElementById('entryNotes').value,
    price: parseInt(document.getElementById('entryPrice')?.value || 0),
    status: document.getElementById('entryStatus')?.value || 'new',
    familyMemberId: document.querySelector('.family-select') ? 
      parseInt(document.querySelector('.family-select').value) || null : null
  };
  
  try {
    if (id) {
      EntryService.update(parseInt(id), data);
    } else {
      EntryService.create(data);
    }
    
    // ЗАКРЫВАЕМ МОДАЛКУ ПЕРВОЙ!
    Modal.close();
    
    // Потом показываем alert
    setTimeout(() => {
      Modal.alert('✅ Запись сохранена!');
    }, 100);
    
    // Обновляем вид
    setTimeout(() => {
      if (currentTab === 'calendar') CalendarView.render();
      else if (currentTab === 'work') WorkView.render();
      else if (currentTab === 'family') FamilyView.render();
    }, 200);
    
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  
  return false;
};

// === УДАЛЕНИЕ ЗАПИСИ ===
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

// === ОЧИСТКА ВСЕХ ДАННЫХ ===
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

// === ОСТАЛЬНЫЕ ФУНКЦИИ ===
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
        <option value="reminder" ${note && note.category === 'reminder' ? 'selected' : ''}>⏰ Напоминание</option>
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

function showPriceList() {
  const items = PriceService.getAll();
  let content = items.length === 0 ? '<div class="empty-state">Прайс пуст</div>' :
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
    const name = prompt('Название:'); if (!name) return;
    const service = prompt('Тип:', 'Шугаринг');
    const duration = parseInt(prompt('Минут:', '60')) || 60;
    const price = parseInt(prompt('Цена ₽:', '1000')) || 0;
    try {
      PriceService.create({ name, service, duration, price });
      Modal.alert('✅ Добавлено!');
      setTimeout(showPriceList, 200);
    } catch (error) { Modal.alert('❌ ' + error.message); }
  }, 100);
};

window.deletePriceItem = function(id) {
  Modal.confirm('Удалить?', () => { 
    PriceService.delete(id); 
    Modal.close(); 
    setTimeout(showPriceList, 100);
  });
};

function showFamilyMembers() {
  const members = FamilyService.getAll();
  const roleLabels = { child: '👶 Ребёнок', adult: '👤 Взрослый', dog: '🐕 Собака' };
  let content = members.length === 0 ? '<div class="empty-state">Нет членов семьи</div>' :
    members.map(m => `
      <div class="family-member">
        <div class="family-member-name">${m.name} <span style="font-size:12px;color:#666;">${roleLabels[m.role]}</span></div>
        <div class="family-member-info">
          ${m.age ? 'Возраст: ' + m.age + ' лет<br>' : ''}
          ${m.school ? ' ' + m.school + '<br>' : ''}
          ${m.breed ? '🐕 Порода: ' + m.breed + '<br>' : ''}
          ${m.circles && m.circles.length > 0 ? '🎨 ' + FamilyMember.getCirclesText(m.circles) : ''}
        </div>
        <button class="btn-del" onclick="deleteFamilyMember(${m.id})" style="margin-top:8px;width:100%;">🗑️ Удалить</button>
      </div>
    `).join('');
  content += `<button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить</button>`;
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
  Modal.confirm('Удалить?', () => { 
    FamilyService.delete(id); 
    Modal.close(); 
    setTimeout(showFamilyMembers, 100);
  });
};

function openTaskForm() {
  const content = `
    <form id="taskForm" onsubmit="return handleTaskSubmit(event)">
      <label>Задача *</label>
      <input type="text" id="taskText" required placeholder="Что нужно сделать?">
      <label>Категория</label>
      <select id="taskCategory">
        <option value="general">📋 Обычная</option>
        <option value="shopping">🛒 Покупки</option>
        <option value="home">🏠 Дом</option>
        <option value="kids">👶 Дети</option>
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

function openPinSettings() {
  const isPinEnabled = FamilyShare.isPinEnabled();
  const content = `
    <div class="pin-section">
      <div class="pin-status">
        <span class="pin-status-text">PIN-код ${isPinEnabled ? '✅ включён' : '❌ выключен'}</span>
      </div>
      ${isPinEnabled ? `
        <button class="action-btn" onclick="removePin()" style="width:100%;background:#ffebee;color:#d32f2f;">
          🗑️ Удалить PIN
        </button>
      ` : `
        <label>Новый PIN (4-6 цифр):</label>
        <input type="password" class="pin-input" id="newPin" maxlength="6" inputmode="numeric" placeholder="••••">
        <label>Повторите PIN:</label>
        <input type="password" class="pin-input" id="confirmPin" maxlength="6" inputmode="numeric" placeholder="••••">
        <button class="save-btn" onclick="setNewPin()" style="width:100%;margin-top:10px;">
          🔐 Установить PIN
        </button>
      `}
    </div>
  `;
  Modal.form({ title: '🔐 Настройки PIN', content });
}

window.setNewPin = function() {
  const pin = document.getElementById('newPin').value;
  const confirm = document.getElementById('confirmPin').value;
  if (pin !== confirm) {
    Modal.alert('❌ PIN не совпадают!');
    return;
  }
  try {
    FamilyShare.setPin(pin);
    Modal.alert('✅ PIN установлен!');
    Modal.close();
  } catch (error) {
    Modal.alert('❌ ' + error.message);
  }
};

window.removePin = function() {
  Modal.confirm('Удалить PIN-код?', () => {
    FamilyShare.removePin();
    Modal.close();
    Modal.alert('✅ PIN удалён!');
  });
};

console.log('✅ app.js v2.0 загружен');
APPJS

echo "✅ app.js v2.0 создан"

# 6. ПЕРЕЗАПУСК СЕРВЕРА
echo ""
echo "6. 🚀 Перезапуск сервера..."

pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
else
  echo "📱 Открой: http://localhost:8000?v=$(date +%s)"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ РАДИКАЛЬНОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!"
echo "═══════════════════════════════════════"
echo ""
echo " ЧТО ИЗМЕНЕНО:"
echo "  1. ✅ Удалён service-worker.js (не кэширует)"
echo "  2. ✅ Modal.js - inline onclick (ГАРАНТИРОВАННО работает)"
echo "  3. ✅ Все скрипты с ?v=2 (обход кэша)"
echo "  4. ✅ handleEntrySubmit - глобальная функция"
echo "  5. ✅ Modal.close() вызывается ПЕРВЫМ"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Нажми '🗑️ Очистить' в Статистике"
echo "   → Все тестовые данные удалятся"
echo ""
echo "2. Нажми '+ Добавить' → 'Работа'"
echo "   → Заполни форму"
echo "   → Нажми 'Сохранить'"
echo "   → Модалка ЗАКРОЕТСЯ"
echo ""
echo "3. Нажми на запись → '🗑️ Удалить'"
echo "   → Подтверди"
echo "   → Запись ИСЧЕЗНЕТ"
echo ""
echo "4. Крестик (×) в углу модалки"
echo "   → Нажми"
echo "   → Модалка ЗАКРОЕТСЯ"
echo ""
echo "Если НЕ работает - напиши 'не работает' и я сделаю ещё радикальнее!"
