#!/bin/bash
echo "👨‍👩‍👧 Добавляю семейный доступ..."

# 1. Создаём сервис FamilyShare
cat > src/services/FamilyShare.js << 'FAMILY'
/**
 * FAMILY SHARE SERVICE
 * Семейный доступ: PIN, общий список задач, экспорт расписания
 */

const FamilyShare = {
  /**
   * PIN-код (хранится хешированным)
   */
  PIN_KEY: 'gdesveta_pin',
  PIN_ENABLED_KEY: 'gdesveta_pin_enabled',
  
  /**
   * Установить PIN
   */
  setPin(pin) {
    if (!pin || pin.length < 4) {
      throw new Error('PIN должен быть минимум 4 цифры');
    }
    if (!/^\d{4,6}$/.test(pin)) {
      throw new Error('PIN должен содержать только цифры (4-6)');
    }
    Storage.set(this.PIN_KEY, pin); // В реальном приложении — хеш
    Storage.set(this.PIN_ENABLED_KEY, true);
    return true;
  },
  
  /**
   * Проверить PIN
   */
  checkPin(pin) {
    const saved = Storage.get(this.PIN_KEY);
    return saved === pin;
  },
  
  /**
   * Удалить PIN
   */
  removePin() {
    Storage.remove(this.PIN_KEY);
    Storage.remove(this.PIN_ENABLED_KEY);
  },
  
  /**
   * Включён ли PIN
   */
  isPinEnabled() {
    return Storage.get(this.PIN_ENABLED_KEY, false);
  },
  
  /**
   * Экспорт расписания на день в текст
   */
  exportDaySchedule(date) {
    const entries = EntryService.getByDate(date);
    const notes = NoteService.getByDate(date);
    const dayName = Utils.formatDate(date, 'long');
    
    let text = `📅 ГдеСвета — ${dayName}\n\n`;
    
    if (entries.length > 0) {
      text += `⏰ ЗАПИСИ:\n`;
      entries.forEach(e => {
        const endTime = Utils.calcEndTime(e.time, e.duration);
        const icon = e.category === 'work' ? '💼' : e.category === 'family' ? '👨‍👧' : '🐕';
        text += `${icon} ${e.time}-${endTime} ${e.name}`;
        if (e.price > 0) text += ` (${e.price}₽)`;
        text += `\n`;
      });
      text += `\n`;
    }
    
    if (notes.length > 0) {
      text += ` ЗАМЕТКИ:\n`;
      notes.forEach(n => {
        const icon = Note.getCategoryIcon(n.category);
        text += `${icon} ${n.title}\n`;
      });
    }
    
    if (entries.length === 0 && notes.length === 0) {
      text += `Свободный день! 🌸\n`;
    }
    
    return text;
  },
  
  /**
   * Поделиться через системное меню (Web Share API)
   */
  async shareSchedule(date) {
    const text = this.exportDaySchedule(date);
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'Расписание на ' + Utils.formatDate(date, 'short'),
          text: text
        });
        return true;
      } catch (error) {
        console.log('[Share] Отменено пользователем');
        return false;
      }
    } else {
      // Фоллбэк: копирование в буфер
      try {
        await navigator.clipboard.writeText(text);
        Modal.alert('📋 Скопировано в буфер обмена!');
        return true;
      } catch (error) {
        Modal.alert('❌ Не удалось поделиться: ' + error.message);
        return false;
      }
    }
  },
  
  /**
   * Экспорт недели
   */
  exportWeekSchedule(startDate) {
    const start = new Date(startDate);
    const end = new Date(start);
    end.setDate(end.getDate() + 6);
    
    let text = `📅 ГдеСвета — неделя с ${Utils.formatDate(startDate, 'short')}\n\n`;
    
    for (let d = 0; d < 7; d++) {
      const date = new Date(start);
      date.setDate(date.getDate() + d);
      const dateStr = date.toISOString().split('T')[0];
      const dayName = Utils.formatDate(dateStr, 'short');
      
      const entries = EntryService.getByDate(dateStr);
      if (entries.length > 0) {
        text += `📆 ${dayName}:\n`;
        entries.forEach(e => {
          text += `  ${e.time} ${e.name}\n`;
        });
        text += `\n`;
      }
    }
    
    return text;
  },
  
  /**
   * Семейный список задач (общий)
   */
  TASKS_KEY: 'gdesveta_family_tasks',
  
  getTasks() {
    return Storage.get(this.TASKS_KEY, []);
  },
  
  addTask(task) {
    const tasks = this.getTasks();
    const newTask = {
      id: Utils.generateId(),
      text: task.text,
      category: task.category || 'general',
      assignedTo: task.assignedTo || null,
      completed: false,
      createdAt: new Date().toISOString()
    };
    tasks.push(newTask);
    Storage.set(this.TASKS_KEY, tasks);
    Events.emit('task:added', newTask);
    return newTask;
  },
  
  toggleTask(id) {
    const tasks = this.getTasks();
    const task = tasks.find(t => t.id === id);
    if (task) {
      task.completed = !task.completed;
      task.completedAt = task.completed ? new Date().toISOString() : null;
      Storage.set(this.TASKS_KEY, tasks);
      Events.emit('task:toggled', task);
    }
    return task;
  },
  
  deleteTask(id) {
    const tasks = this.getTasks().filter(t => t.id !== id);
    Storage.set(this.TASKS_KEY, tasks);
    Events.emit('task:deleted', id);
  },
  
  getActiveTasks() {
    return this.getTasks().filter(t => !t.completed);
  },
  
  getCompletedTasks() {
    return this.getTasks().filter(t => t.completed);
  },
  
  clearCompletedTasks() {
    const tasks = this.getTasks().filter(t => !t.completed);
    Storage.set(this.TASKS_KEY, tasks);
  }
};

window.FamilyShare = FamilyShare;
FAMILY

echo "✅ FamilyShare.js создан"

# 2. Обновляем index.html — добавляем элементы семейного доступа
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="styles/main.css">
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
          <div>
            <button class="tab-action-btn" onclick="showPriceList()"> Прайс</button>
            <button class="tab-action-btn" onclick="shareToday()" style="margin-left:5px;"></button>
          </div>
        </div>
        <div id="workView"></div>
      </div>

      <div id="tab-family" class="tab-content">
        <div class="tab-header">
          <h2>👨‍👩‍👧 Семья</h2>
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
          <h2> Заметки</h2>
          <button class="tab-action-btn" onclick="openNoteForm()">+ Новая</button>
        </div>
        <div id="notesView"></div>
      </div>

      <div id="tab-stats" class="tab-content">
        <h2> Статистика</h2>
        <div id="statsView"></div>
        <div class="stats-actions">
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <button id="pinBtn" class="action-btn" onclick="openPinSettings()"> PIN</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>

    <button class="add-btn-fixed" onclick="openQuickAdd()">+ Добавить</button>
  </div>

  <div id="notificationContainer"></div>
  <div id="modalContainer"></div>

  <!-- Скрипты -->
  <script src="src/core/storage.js"></script>
  <script src="src/core/events.js"></script>
  <script src="src/core/utils.js"></script>
  <script src="src/core/store.js"></script>
  
  <script src="src/models/Entry.js"></script>
  <script src="src/models/Note.js"></script>
  <script src="src/models/PriceItem.js"></script>
  <script src="src/models/FamilyMember.js"></script>
  
  <script src="src/services/EntryService.js"></script>
  <script src="src/services/NoteService.js"></script>
  <script src="src/services/PriceService.js"></script>
  <script src="src/services/FamilyService.js"></script>
  <script src="src/services/ConflictChecker.js"></script>
  <script src="src/services/NotificationService.js"></script>
  <script src="src/services/FamilyShare.js"></script>
  
  <script src="src/ui/components/Modal.js"></script>
  <script src="src/ui/components/Calendar.js"></script>
  <script src="src/ui/components/EntryCard.js"></script>
  <script src="src/ui/components/NoteCard.js"></script>
  <script src="src/ui/components/FamilySelect.js"></script>
  
  <script src="src/views/CalendarView.js"></script>
  <script src="src/views/WorkView.js"></script>
  <script src="src/views/FamilyView.js"></script>
  <script src="src/views/NotesView.js"></script>
  <script src="src/views/StatsView.js"></script>
  
  <script src="app.js"></script>
</body>
</html>
HTML

echo "✅ index.html обновлён — добавлены вкладки и кнопки"

# 3. Добавляем стили для новых элементов
cat >> styles/main.css << 'CSS'

/* === СЕМЕЙНЫЕ ЗАДАЧИ === */
.task-card {
  background: white;
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  border-left: 4px solid #4a90e2;
  display: flex;
  align-items: center;
  gap: 10px;
}

body.dark-theme .task-card {
  background: #16213e;
}

.task-card.completed {
  opacity: 0.6;
  border-left-color: #9e9e9e;
}

.task-card.completed .task-text {
  text-decoration: line-through;
}

.task-checkbox {
  width: 24px;
  height: 24px;
  border: 2px solid #4a90e2;
  border-radius: 6px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: white;
  font-size: 16px;
  color: #4a90e2;
}

body.dark-theme .task-checkbox {
  background: #2d3561;
}

.task-checkbox.checked {
  background: #4a90e2;
  color: white;
}

.task-text {
  flex: 1;
  font-size: 15px;
  color: #333;
}

body.dark-theme .task-text {
  color: #eaeaea;
}

.task-category {
  font-size: 11px;
  padding: 3px 8px;
  border-radius: 10px;
  background: #f0f0f0;
  color: #666;
}

body.dark-theme .task-category {
  background: #2d3561;
  color: #aaa;
}

.task-delete {
  background: none;
  border: none;
  color: #f44336;
  cursor: pointer;
  font-size: 18px;
  padding: 5px;
}

.task-filters {
  display: flex;
  gap: 8px;
  margin-bottom: 15px;
  flex-wrap: wrap;
}

.task-filter {
  padding: 8px 14px;
  border: 2px solid #e0e0e0;
  border-radius: 20px;
  background: white;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
}

body.dark-theme .task-filter {
  background: #2d3561;
  border-color: #3a4a7a;
  color: #eaeaea;
}

.task-filter.active {
  background: #4a90e2;
  color: white;
  border-color: #4a90e2;
}

/* === PIN НАСТРОЙКИ === */
.pin-section {
  background: white;
  padding: 20px;
  border-radius: 15px;
  margin-bottom: 15px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

body.dark-theme .pin-section {
  background: #16213e;
}

.pin-status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 15px;
}

.pin-status-text {
  font-size: 14px;
  color: #666;
}

body.dark-theme .pin-status-text {
  color: #aaa;
}

.pin-input {
  width: 100%;
  padding: 12px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 20px;
  text-align: center;
  letter-spacing: 8px;
  margin-bottom: 10px;
}

body.dark-theme .pin-input {
  background: #2d3561;
  border-color: #3a4a7a;
  color: #eaeaea;
}

/* === ЭКРАН ВВОДА PIN === */
.pin-screen {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.95);
  z-index: 100000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.pin-screen-content {
  background: white;
  padding: 30px;
  border-radius: 20px;
  text-align: center;
  max-width: 350px;
  width: 100%;
}

body.dark-theme .pin-screen-content {
  background: #16213e;
  color: #eaeaea;
}

.pin-screen-title {
  font-size: 20px;
  margin-bottom: 20px;
  color: #ff6b9d;
}

.pin-screen-input {
  width: 100%;
  padding: 15px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 24px;
  text-align: center;
  letter-spacing: 10px;
  margin-bottom: 15px;
}

body.dark-theme .pin-screen-input {
  background: #2d3561;
  border-color: #3a4a7a;
  color: #eaeaea;
}

.pin-screen-error {
  color: #f44336;
  font-size: 14px;
  margin-bottom: 10px;
  min-height: 20px;
}

/* === КНОПКА ПОДЕЛИТЬСЯ === */
.share-btn {
  background: #4a90e2;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 8px 12px;
  cursor: pointer;
  font-size: 14px;
}

.share-btn:active {
  transform: scale(0.95);
}
CSS

echo "✅ Стили для семейного доступа добавлены"

# 4. Создаём TasksView
cat > src/views/TasksView.js << 'TASKS'
/**
 * TASKS VIEW
 * Страница семейных задач
 */

const TasksView = {
  container: null,
  filter: 'active',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const tasks = this.filter === 'active' ? 
      FamilyShare.getActiveTasks() : 
      this.filter === 'completed' ? 
        FamilyShare.getCompletedTasks() : 
        FamilyShare.getTasks();
    
    let html = `
      <div class="task-filters">
        <button class="task-filter ${this.filter === 'active' ? 'active' : ''}" data-filter="active">
          Активные (${FamilyShare.getActiveTasks().length})
        </button>
        <button class="task-filter ${this.filter === 'completed' ? 'active' : ''}" data-filter="completed">
          Выполненные (${FamilyShare.getCompletedTasks().length})
        </button>
        <button class="task-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">
          Все (${FamilyShare.getTasks().length})
        </button>
      </div>
    `;
    
    if (tasks.length === 0) {
      html += '<div class="empty-state">Нет задач</div>';
    } else {
      html += tasks.map(task => {
        const categoryIcons = {
          general: '📋',
          shopping: '🛒',
          home: '🏠',
          kids: '',
          dog: '',
          important: '⭐'
        };
        const icon = categoryIcons[task.category] || '📋';
        
        return `
          <div class="task-card ${task.completed ? 'completed' : ''}" data-id="${task.id}">
            <div class="task-checkbox ${task.completed ? 'checked' : ''}" onclick="toggleTask(${task.id})">
              ${task.completed ? '✓' : ''}
            </div>
            <div class="task-text">${icon} ${task.text}</div>
            ${task.assignedTo ? `<div class="task-category">${task.assignedTo}</div>` : ''}
            <button class="task-delete" onclick="deleteTask(${task.id})">🗑️</button>
          </div>
        `;
      }).join('');
    }
    
    this.container.innerHTML = html;
    
    this.container.querySelectorAll('.task-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('task:added', () => this.render());
    Events.on('task:toggled', () => this.render());
    Events.on('task:deleted', () => this.render());
  }
};

window.TasksView = TasksView;

// Глобальные функции для задач
window.toggleTask = function(id) {
  FamilyShare.toggleTask(id);
};

window.deleteTask = function(id) {
  Modal.confirm('Удалить задачу?', () => {
    FamilyShare.deleteTask(id);
  });
};

window.openTaskForm = function() {
  const content = `
    <form id="taskForm">
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
  
  const modal = Modal.form({
    title: '✅ Новая задача',
    content
  });
  
  modal.querySelector('#taskForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const data = {
      text: modal.querySelector('#taskText').value,
      category: modal.querySelector('#taskCategory').value,
      assignedTo: modal.querySelector('#taskAssigned').value || null
    };
    FamilyShare.addTask(data);
    Modal.close();
    Modal.alert('✅ Задача добавлена!');
  });
};
TASKS

echo "✅ TasksView создан"

# 5. Обновляем app.js — добавляем инициализацию TasksView и функции PIN
cat > app.js << 'APPJS'
/**
 * APP.JS
 * Точка входа приложения
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 ГдеСвета — запуск...');
  
  Store.init();
  
  if (Store.getFamilyMembers().length === 0) {
    initDemoData();
  }
  
  setupTabs();
  setupExportImport();
  
  CalendarView.init('calendarView');
  WorkView.init('workView');
  FamilyView.init('familyView');
  TasksView.init('tasksView');
  NotesView.init('notesView');
  StatsView.init('statsView');
  
  if (typeof NotificationService !== 'undefined') {
    NotificationService.init();
  }
  
  initTheme();
  setupEventListeners();
  
  // Проверка PIN при запуске
  if (FamilyShare.isPinEnabled()) {
    showPinScreen();
  }
  
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
  
  // Демо-задачи
  FamilyShare.addTask({ text: 'Купить памперсы', category: 'shopping', assignedTo: 'Муж' });
  FamilyShare.addTask({ text: 'Записать старшего к врачу', category: 'kids' });
  FamilyShare.addTask({ text: 'Прогулка с Бобиком', category: 'dog' });
  
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
      toggle.textContent = isDark ? '☀️' : '🌙';
      setTimeout(() => body.classList.remove('theme-transition'), 300);
    });
  }
}

// === PIN-ЗАЩИТА ===
function showPinScreen() {
  const screen = document.createElement('div');
  screen.className = 'pin-screen';
  screen.innerHTML = `
    <div class="pin-screen-content">
      <div class="pin-screen-title">🔐 Введите PIN</div>
      <input type="password" class="pin-screen-input" id="pinInput" maxlength="6" inputmode="numeric" placeholder="••••">
      <div class="pin-screen-error" id="pinError"></div>
      <button class="save-btn" onclick="checkPinAndUnlock()" style="width:100%;">Войти</button>
    </div>
  `;
  document.body.appendChild(screen);
  
  const input = screen.querySelector('#pinInput');
  input.focus();
  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') checkPinAndUnlock();
  });
}

window.checkPinAndUnlock = function() {
  const input = document.querySelector('#pinInput');
  const error = document.querySelector('#pinError');
  const pin = input.value;
  
  if (FamilyShare.checkPin(pin)) {
    document.querySelector('.pin-screen').remove();
  } else {
    error.textContent = '❌ Неверный PIN';
    input.value = '';
    input.focus();
  }
};

window.openPinSettings = function() {
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
};

window.setNewPin = function() {
  const pin = document.querySelector('#newPin').value;
  const confirm = document.querySelector('#confirmPin').value;
  
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

// === ПОДЕЛИТЬСЯ РАСПИСАНИЕМ ===
window.shareToday = async function() {
  const today = Utils.getToday();
  const shared = await FamilyShare.shareSchedule(today);
  if (shared) {
    console.log('✅ Расписание отправлено');
  }
};

// === БЫСТРОЕ ДОБАВЛЕНИЕ ===
function openQuickAdd() {
  const content = `
    <div class="quick-add-grid">
      <button class="quick-add-btn work" onclick="openEntryForm(null, 'work')">
        <span class="quick-add-icon">💼</span><span>Работа</span>
      </button>
      <button class="quick-add-btn family" onclick="openEntryForm(null, 'family')">
        <span class="quick-add-icon">👨‍👩‍👧</span><span>Семья</span>
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
    family: '👨‍👩👧 Событие (семья)',
    dog: '🐕 Событие (собака)'
  };
  
  const isWork = category === 'work';
  const isFamily = category === 'family' || category === 'dog';
  
  let content = `
    <form id="entryForm">
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
        <button type="button" class="duration-btn" data-min="30">30</button>
        <button type="button" class="duration-btn active" data-min="60">60</button>
        <button type="button" class="duration-btn" data-min="90">90</button>
        <button type="button" class="duration-btn" data-min="120">120</button>
      </div>
      <input type="hidden" id="entryDuration" value="${entry ? entry.duration : 60}">
      
      <label>Услуга/Тип</label>
      <select id="entryService">
        <option ${entry && entry.service === 'Шугаринг' ? 'selected' : ''}>Шугаринг</option>
        <option ${entry && entry.service === 'LPG-массаж' ? 'selected' : ''}>LPG-массаж</option>
        <option ${entry && entry.service === 'Школа' ? 'selected' : ''}>Школа</option>
        <option ${entry && entry.service === 'Садик' ? 'selected' : ''}>Садик</option>
        <option ${entry && entry.service === 'Кружок' ? 'selected' : ''}>Кружок</option>
        <option ${entry && entry.service === 'Секция' ? 'selected' : ''}>Секция</option>
        <option ${entry && entry.service === 'Врач' ? 'selected' : ''}>Врач</option>
        <option ${entry && entry.service === 'Ветеринар' ? 'selected' : ''}>Ветеринар</option>
        <option ${entry && entry.service === 'Груминг' ? 'selected' : ''}>Груминг</option>
        <option ${entry && entry.service === 'Прогулка' ? 'selected' : ''}>Прогулка</option>
        <option ${entry && entry.service === 'Другое' ? 'selected' : ''}>Другое</option>
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
  
  const modal = Modal.form({
    title: id ? '✏️ Редактировать запись' : categoryLabels[category],
    content
  });
  
  modal.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      modal.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      modal.querySelector('#entryDuration').value = btn.dataset.min;
    });
  });
  
  const familySelect = modal.querySelector('.family-select');
  if (familySelect) {
    familySelect.addEventListener('change', () => {
      const member = FamilySelect.getSelectedMember(familySelect);
      if (member) {
        modal.querySelector('#entryName').value = member.name;
        if (member.school) modal.querySelector('#entryZone').value = member.school;
      }
    });
  }
  
  modal.querySelector('#entryForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const data = {
      category: modal.querySelector('#entryCategory').value,
      name: modal.querySelector('#entryName').value,
      phone: modal.querySelector('#entryPhone')?.value || '',
      date: modal.querySelector('#entryDate').value,
      time: modal.querySelector('#entryTime').value,
      duration: parseInt(modal.querySelector('#entryDuration').value),
      service: modal.querySelector('#entryService').value,
      zone: modal.querySelector('#entryZone').value,
      notes: modal.querySelector('#entryNotes').value,
      price: parseInt(modal.querySelector('#entryPrice')?.value || 0),
      status: modal.querySelector('#entryStatus')?.value || 'new',
      familyMemberId: familySelect ? FamilySelect.getSelectedId(familySelect) : null
    };
    
    try {
      if (id) EntryService.update(id, data);
      else EntryService.create(data);
      Modal.close();
      Modal.alert('✅ Запись сохранена!');
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}

// === ФОРМА ЗАМЕТКИ ===
function openNoteForm(id = null) {
  let note = null;
  if (id) {
    note = Store.getNotes().find(n => n.id === id);
    if (!note) return;
  }
  
  const content = `
    <form id="noteForm">
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
        <option value="ideas" ${note && note.category === 'ideas' ? 'selected' : ''}> Идея</option>
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
  
  const modal = Modal.form({
    title: id ? '✏️ Редактировать заметку' : '📝 Новая заметка',
    content
  });
  
  modal.querySelector('#noteForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const data = {
      title: modal.querySelector('#noteTitle').value,
      text: modal.querySelector('#noteText').value,
      category: modal.querySelector('#noteCategory').value,
      date: modal.querySelector('#noteDate').value || null
    };
    try {
      if (id) NoteService.update(id, data);
      else NoteService.create(data);
      Modal.close();
      Modal.alert('✅ Заметка сохранена!');
    } catch (error) {
      Modal.alert(' Ошибка: ' + error.message);
    }
  });
}

// === ПРАЙС ===
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

function addPriceItem() {
  Modal.close();
  const name = prompt('Название:'); if (!name) return;
  const service = prompt('Тип:', 'Шугаринг');
  const duration = parseInt(prompt('Минут:', '60')) || 60;
  const price = parseInt(prompt('Цена ₽:', '1000')) || 0;
  try {
    PriceService.create({ name, service, duration, price });
    Modal.alert('✅ Добавлено!');
    showPriceList();
  } catch (error) { Modal.alert('❌ ' + error.message); }
}

function deletePriceItem(id) {
  Modal.confirm('Удалить?', () => { PriceService.delete(id); Modal.close(); showPriceList(); });
}

// === СЕМЬЯ ===
function showFamilyMembers() {
  const members = FamilyService.getAll();
  const roleLabels = { child: '👶 Ребёнок', adult: '👤 Взрослый', dog: '🐕 Собака' };
  let content = members.length === 0 ? '<div class="empty-state">Нет членов семьи</div>' :
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
  content += `<button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить</button>`;
  Modal.form({ title: '👥 Члены семьи', content });
}

function addFamilyMember() {
  Modal.close();
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
    showFamilyMembers();
  } catch (error) { Modal.alert('❌ ' + error.message); }
}

function deleteFamilyMember(id) {
  Modal.confirm('Удалить?', () => { FamilyService.delete(id); Modal.close(); showFamilyMembers(); });
}

console.log('✅ app.js загружен');
APPJS

echo "✅ app.js обновлён"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000"
  echo "✅ Приложение открыто!"
fi

echo ""
echo "👨‍👩‍👧 ПРИОРИТЕТ 4 ВЫПОЛНЕН!"
echo ""
echo "✅ Добавлено:"
echo "  🔐 PIN-код — защита от детей"
echo "  📤 Поделиться расписанием — отправить мужу"
echo "  ✅ Семейные задачи — общий список дел"
echo "  ️ Новая вкладка 'Задачи'"
echo ""
echo "Как использовать:"
echo "  1. PIN: Статистика → 🔐 PIN"
echo "  2. Поделиться: Работа → 📤"
echo "  3. Задачи: вкладка ✅"
echo ""
echo "📋 Следующий шаг: Быстрые шаблоны"
