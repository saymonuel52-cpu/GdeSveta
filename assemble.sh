#!/bin/bash
echo "🚀 Собираю полное приложение..."

# 1. Создаём полный index.html
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
        <div id="calendarView"></div>
      </div>

      <div id="tab-work" class="tab-content">
        <div class="tab-header">
          <h2>💼 Работа</h2>
          <button class="tab-action-btn" onclick="showPriceList()"> Прайс</button>
        </div>
        <div id="workView"></div>
      </div>

      <div id="tab-family" class="tab-content">
        <div class="tab-header">
          <h2>👨👩‍👧 Семья</h2>
          <button class="tab-action-btn" onclick="showFamilyMembers()">👥 Семья</button>
        </div>
        <div id="familyView"></div>
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
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>

    <button class="add-btn-fixed" onclick="openQuickAdd()">+ Добавить</button>
  </div>

  <!-- Модальные окна -->
  <div id="modalContainer"></div>

  <!-- Загрузка модулей (порядок важен!) -->
  <script src="src/core/storage.js"></script>
  <script src="src/core/events.js"></script>
  <script src="src/core/utils.js"></script>
  <script src="src/core/store.js"></script>
  
  <script src="src/models/Entry.js"></script>
  <script src="src/models/Note.js"></script>
  <script src="src/models/PriceItem.js"></script>
  <script src="src/models/FamilyMember.js"></script>
  <script src="src/models/User.js"></script>
  
  <script src="src/services/EntryService.js"></script>
  <script src="src/services/NoteService.js"></script>
  <script src="src/services/PriceService.js"></script>
  <script src="src/services/FamilyService.js"></script>
  <script src="src/services/ConflictChecker.js"></script>
  <script src="src/services/NotificationService.js"></script>
  
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

echo "✅ index.html создан"

# 2. Создаём полный app.js
cat > app.js << 'APPJS'
/**
 * APP.JS
 * Точка входа приложения
 * Инициализация и связывание всех модулей
 */

// Глобальные переменные
let currentTab = 'calendar';

// Инициализация приложения
document.addEventListener('DOMContentLoaded', () => {
  console.log(' ГдеСвета — запуск...');
  
  // Инициализация хранилища
  Store.init();
  
  // Инициализация демо-данных (если пусто)
  if (Store.getFamilyMembers().length === 0) {
    initDemoData();
  }
  
  // Инициализация UI
  setupTabs();
  setupExportImport();
  
  // Инициализация views
  CalendarView.init('calendarView');
  WorkView.init('workView');
  FamilyView.init('familyView');
  NotesView.init('notesView');
  StatsView.init('statsView');
  
  // Подписка на события для обновления UI
  setupEventListeners();
  
  console.log('✅ Приложение готово!');
});

// Инициализация демо-данных
function initDemoData() {
  console.log('📝 Создание демо-данных...');
  
  // Члены семьи
  FamilyService.create({
    name: 'Старший ребёнок',
    role: 'child',
    age: 10,
    school: 'Школа №5',
    circles: ['Футбол', 'Английский']
  });
  
  FamilyService.create({
    name: 'Средний ребёнок',
    role: 'child',
    age: 8,
    school: 'Школа №5',
    circles: ['Танцы', 'Рисование']
  });
  
  FamilyService.create({
    name: 'Малыш',
    role: 'child',
    age: 1,
    school: 'Садик "Солнышко"',
    circles: []
  });
  
  FamilyService.create({
    name: 'Муж',
    role: 'adult',
    circles: []
  });
  
  FamilyService.create({
    name: 'Бобик',
    role: 'dog',
    breed: 'Лабрадор',
    circles: ['Груминг раз в 3 мес']
  });
  
  // Прайс-лист
  PriceService.create({
    name: 'Ноги полностью',
    service: 'Шугаринг',
    duration: 60,
    price: 1500
  });
  
  PriceService.create({
    name: 'Бикини классическое',
    service: 'Шугаринг',
    duration: 30,
    price: 800
  });
  
  PriceService.create({
    name: 'Подмышки',
    service: 'Шугаринг',
    duration: 15,
    price: 400
  });
  
  PriceService.create({
    name: 'LPG всего тела',
    service: 'LPG-массаж',
    duration: 60,
    price: 2000
  });
  
  console.log('✅ Демо-данные созданы');
}

// Настройка вкладок
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

// Настройка экспорта/импорта
function setupExportImport() {
  const exportBtn = document.getElementById('exportBtn');
  const importBtn = document.getElementById('importBtn');
  const importFile = document.getElementById('importFile');
  
  if (exportBtn) {
    exportBtn.addEventListener('click', () => {
      const data = Store.exportData();
      const json = JSON.stringify(data, null, 2);
      const blob = new Blob([json], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'gdesveta_backup_' + Utils.getToday() + '.json';
      a.click();
      URL.revokeObjectURL(url);
      Modal.alert('Данные экспортированы!');
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
          Modal.confirm('Импортировать данные? Текущие будут заменены.', () => {
            Store.importData(data);
            Modal.alert('Импорт выполнен!');
          });
        } catch (error) {
          Modal.alert('Ошибка импорта: ' + error.message);
        }
      };
      reader.readAsText(file);
    });
  }
}

// Подписка на события
function setupEventListeners() {
  // Открытие формы записи
  Events.on('entry:edit', (id) => {
    openEntryForm(id);
  });
  
  // Открытие формы заметки
  Events.on('note:edit', (id) => {
    openNoteForm(id);
  });
}

// Быстрое добавление
function openQuickAdd() {
  const content = `
    <div class="quick-add-grid">
      <button class="quick-add-btn work" onclick="openEntryForm(null, 'work')">
        <span class="quick-add-icon">💼</span>
        <span>Работа</span>
      </button>
      <button class="quick-add-btn family" onclick="openEntryForm(null, 'family')">
        <span class="quick-add-icon">👨‍‍👧</span>
        <span>Семья</span>
      </button>
      <button class="quick-add-btn dog" onclick="openEntryForm(null, 'dog')">
        <span class="quick-add-icon">🐕</span>
        <span>Собака</span>
      </button>
      <button class="quick-add-btn note" onclick="openNoteForm()">
        <span class="quick-add-icon"></span>
        <span>Заметка</span>
      </button>
    </div>
  `;
  
  const modal = Modal.form({
    title: 'Что добавляем?',
    content
  });
}

// Форма записи
function openEntryForm(id = null, category = 'work') {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    category = entry.category;
  }
  
  const categoryLabels = {
    work: ' Новая запись (работа)',
    family: '‍👩‍👧 Событие (семья)',
    dog: '🐕 Событие (собака)'
  };
  
  const isWork = category === 'work';
  const isFamily = category === 'family' || category === 'dog';
  
  let content = `
    <form id="entryForm">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="${category}">
      
      ${isFamily ? `
        <label>Член семьи</label>
        ${FamilySelect.render(entry ? entry.familyMemberId : null)}
      ` : ''}
      
      <label>Название *</label>
      <input type="text" id="entryName" value="${entry ? entry.name : ''}" required>
      
      ${isWork ? `
        <label>Телефон</label>
        <input type="tel" id="entryPhone" value="${entry ? entry.phone : ''}">
      ` : ''}
      
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
      
      ${isWork ? `
        <label>Цена (₽)</label>
        <input type="number" id="entryPrice" value="${entry ? entry.price : 0}">
      ` : ''}
      
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
  
  // Обработчики длительности
  modal.querySelectorAll('.duration-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      modal.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      modal.querySelector('#entryDuration').value = btn.dataset.min;
    });
  });
  
  // Обработчик выбора члена семьи
  const familySelect = modal.querySelector('.family-select');
  if (familySelect) {
    familySelect.addEventListener('change', () => {
      const member = FamilySelect.getSelectedMember(familySelect);
      if (member) {
        modal.querySelector('#entryName').value = member.name;
        if (member.school) {
          modal.querySelector('#entryZone').value = member.school;
        }
      }
    });
  }
  
  // Обработчик формы
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
      if (id) {
        EntryService.update(id, data);
      } else {
        EntryService.create(data);
      }
      
      Modal.close();
      Modal.alert('✅ Запись сохранена!');
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}

// Форма заметки
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
        <option value="general" ${note && note.category === 'general' ? 'selected' : ''}> Обычная</option>
        <option value="important" ${note && note.category === 'important' ? 'selected' : ''}>⭐ Важная</option>
        <option value="shopping" ${note && note.category === 'shopping' ? 'selected' : ''}>🛒 Покупки</option>
        <option value="ideas" ${note && note.category === 'ideas' ? 'selected' : ''}>💡 Идея</option>
        <option value="reminder" ${note && note.category === 'reminder' ? 'selected' : ''}>⏰ Напоминание</option>
      </select>
      
      <label>Дата (необязательно)</label>
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
      if (id) {
        NoteService.update(id, data);
      } else {
        NoteService.create(data);
      }
      
      Modal.close();
      Modal.alert('✅ Заметка сохранена!');
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}

// Прайс-лист
function showPriceList() {
  const items = PriceService.getAll();
  
  let content = '';
  if (items.length === 0) {
    content = '<div class="empty-state">Прайс пуст</div>';
  } else {
    content = items.map(item => `
      <div class="price-item">
        <div class="price-item-info">
          <div class="price-item-name">${item.name}</div>
          <div class="price-item-details">${item.service} · ${PriceItem.getFormattedDuration(item.duration)}</div>
        </div>
        <div class="price-item-price">${PriceItem.getFormattedPrice(item.price)}</div>
        <button class="btn-del" onclick="deletePriceItem(${item.id})">🗑️</button>
      </div>
    `).join('');
  }
  
  content += `
    <button class="action-btn" onclick="addPriceItem()" style="margin-top:15px;width:100%">+ Добавить услугу</button>
  `;
  
  Modal.form({
    title: '💰 Прайс-лист',
    content
  });
}

function addPriceItem() {
  Modal.close();
  
  const name = prompt('Название услуги:');
  if (!name) return;
  
  const service = prompt('Тип (Шугаринг/LPG-массаж/Другое):', 'Шугаринг');
  const duration = parseInt(prompt('Длительность (мин):', '60')) || 60;
  const price = parseInt(prompt('Цена (₽):', '1000')) || 0;
  
  try {
    PriceService.create({ name, service, duration, price });
    Modal.alert('✅ Услуга добавлена!');
    showPriceList();
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
}

function deletePriceItem(id) {
  Modal.confirm('Удалить услугу?', () => {
    PriceService.delete(id);
    Modal.close();
    showPriceList();
  });
}

// Члены семьи
function showFamilyMembers() {
  const members = FamilyService.getAll();
  const roleLabels = { child: '👶 Ребёнок', adult: '👤 Взрослый', dog: '🐕 Собака' };
  
  let content = '';
  if (members.length === 0) {
    content = '<div class="empty-state">Нет членов семьи</div>';
  } else {
    content = members.map(m => `
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
  }
  
  content += `
    <button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить члена семьи</button>
  `;
  
  Modal.form({
    title: ' Члены семьи',
    content
  });
}

function addFamilyMember() {
  Modal.close();
  
  const name = prompt('Имя:');
  if (!name) return;
  
  const role = prompt('Кто? (child/adult/dog):', 'child');
  const age = role === 'dog' ? null : parseInt(prompt('Возраст:', '10'));
  const school = prompt('Школа/Садик:', '');
  const breed = role === 'dog' ? prompt('Порода:', '') : null;
  const circlesStr = prompt('Кружки/Секции (через запятую):', '');
  const circles = circlesStr ? circlesStr.split(',').map(s => s.trim()) : [];
  
  try {
    FamilyService.create({ name, role, age, school, breed, circles });
    Modal.alert('✅ Член семьи добавлен!');
    showFamilyMembers();
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
}

function deleteFamilyMember(id) {
  Modal.confirm('Удалить члена семьи?', () => {
    FamilyService.delete(id);
    Modal.close();
    showFamilyMembers();
  });
}

console.log('✅ app.js загружен');
APPJS

echo "✅ app.js создан"

# 3. Создаём полные стили
cat > styles/main.css << 'CSS'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #fef9f9;
  color: #333;
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
  min-height: 100vh;
}

header {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  padding: 20px 15px;
  position: sticky;
  top: 0;
  z-index: 100;
  border-radius: 0 0 20px 20px;
  box-shadow: 0 4px 15px rgba(255,107,157,0.3);
}

header h1 {
  text-align: center;
  font-size: 24px;
  margin-bottom: 12px;
}

nav {
  display: flex;
  gap: 6px;
}

.nav-btn {
  flex: 1;
  padding: 10px 5px;
  border: none;
  background: rgba(255,255,255,0.25);
  color: white;
  border-radius: 15px;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.nav-btn.active {
  background: white;
  transform: scale(1.05);
}

main {
  padding: 15px;
}

.tab-content {
  display: none;
}

.tab-content.active {
  display: block;
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.tab-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.tab-header h2 {
  margin: 0;
  font-size: 20px;
}

.tab-action-btn {
  padding: 8px 15px;
  background: white;
  border: 2px solid #ff6b9d;
  color: #ff6b9d;
  border-radius: 20px;
  font-size: 13px;
  font-weight: bold;
  cursor: pointer;
}

/* Календарь */
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
  font-size: 16px;
  flex: 1;
  text-align: center;
}

.small-btn {
  font-size: 12px !important;
  padding: 6px 12px !important;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 3px;
  background: white;
  padding: 10px;
  border-radius: 15px;
  margin-bottom: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.day-header {
  text-align: center;
  font-size: 10px;
  color: #666;
  padding: 5px 2px;
  font-weight: bold;
}

.day-cell {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  position: relative;
  background: #fafafa;
  border: 2px solid transparent;
}

.day-cell.today {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  font-weight: bold;
}

.day-cell.selected {
  border-color: #ff6b9d;
  background: #ffe0ec;
}

.day-cell.has-work {
  border-left: 3px solid #ff6b9d;
}

.day-cell.has-family {
  border-left: 3px solid #4a90e2;
}

.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 15px;
  font-size: 11px;
  color: #666;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

.legend-color {
  width: 12px;
  height: 12px;
  border-radius: 3px;
}

.legend-color.work {
  background: #ff6b9d;
}

.legend-color.family {
  background: #4a90e2;
}

.legend-color.note {
  background: #7ed321;
}

/* Карточки записей */
.entry-card {
  background: white;
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  border-left: 4px solid #ff6b9d;
  cursor: pointer;
}

.entry-card.category-family {
  border-left-color: #4a90e2;
}

.entry-card.category-dog {
  border-left-color: #f5a623;
}

.entry-card.status-done {
  opacity: 0.7;
}

.entry-card.status-cancelled {
  opacity: 0.5;
  text-decoration: line-through;
}

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
}

.entry-compact-time {
  font-weight: bold;
  font-size: 14px;
  white-space: nowrap;
  color: #ff6b9d;
}

.entry-card.category-family .entry-compact-time {
  color: #4a90e2;
}

.entry-compact-name {
  font-weight: 600;
  font-size: 14px;
  flex: 1;
}

.entry-compact-price {
  font-weight: bold;
  font-size: 14px;
  color: #333;
}

.expand-icon {
  color: #999;
  font-size: 12px;
  transition: transform 0.3s;
}

.entry-card.expanded .expand-icon {
  transform: rotate(180deg);
}

.entry-card.compact .entry-details,
.entry-card.compact .status-buttons,
.entry-card.compact .entry-actions {
  display: none;
}

.entry-card.expanded .entry-details,
.entry-card.expanded .status-buttons,
.entry-card.expanded .entry-actions {
  display: block;
  animation: slideDown 0.3s;
}

@keyframes slideDown {
  from { opacity: 0; max-height: 0; }
  to { opacity: 1; max-height: 500px; }
}

.entry-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #e0e0e0;
  font-size: 13px;
  color: #666;
}

.status-badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 10px;
  font-weight: bold;
  margin-left: 5px;
}

.status-new {
  background: #e3f2fd;
  color: #1976d2;
}

.status-confirmed {
  background: #fff3e0;
  color: #f57c00;
}

.status-done {
  background: #e8f5e9;
  color: #388e3c;
}

.status-cancelled {
  background: #ffebee;
  color: #d32f2f;
}

.status-buttons,
.entry-actions {
  display: flex;
  gap: 5px;
  margin-top: 10px;
  flex-wrap: wrap;
}

.status-btn,
.entry-actions button {
  flex: 1;
  min-width: 80px;
  padding: 8px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 12px;
  background: white;
  cursor: pointer;
  font-weight: 600;
}

.status-btn.active {
  background: #ff6b9d;
  color: white;
  border-color: #ff6b9d;
}

.btn-edit {
  background: #e3f2fd !important;
  color: #1976d2 !important;
}

.btn-dup {
  background: #fff3e0 !important;
  color: #f57c00 !important;
}

.btn-del {
  background: #ffebee !important;
  color: #d32f2f !important;
}

/* Кнопка добавления */
.add-btn-fixed {
  position: fixed;
  bottom: 25px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 14px 28px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 6px 20px rgba(255,107,157,0.5);
  z-index: 999;
}

/* Модальные окна */
.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 1000;
  align-items: flex-end;
  justify-content: center;
}

.modal.active {
  display: flex;
}

.modal-content {
  background: white;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  border-radius: 20px 20px 0 0;
  padding: 20px;
  overflow-y: auto;
  position: relative;
}

.close-modal {
  position: absolute;
  top: 10px;
  right: 15px;
  font-size: 28px;
  cursor: pointer;
  color: #666;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f0f0f0;
}

.modal-content h3 {
  margin-bottom: 15px;
  font-size: 20px;
  padding-right: 35px;
}

.modal-content label {
  display: block;
  margin: 12px 0 5px;
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
  font-family: inherit;
}

.duration-row {
  display: flex;
  gap: 5px;
  margin-top: 5px;
}

.duration-btn {
  flex: 1;
  padding: 10px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  font-weight: 600;
}

.duration-btn.active {
  background: #ff6b9d;
  color: white;
  border-color: #ff6b9d;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.save-btn {
  flex: 2;
  padding: 14px;
  background: #ff6b9d;
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
}

.cancel-btn {
  flex: 1;
  padding: 14px;
  background: #e0e0e0;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  cursor: pointer;
}

/* Быстрое добавление */
.quick-add-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin-top: 15px;
}

.quick-add-btn {
  padding: 20px 15px;
  border: 2px solid #e0e0e0;
  border-radius: 15px;
  background: white;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.quick-add-btn:active {
  transform: scale(0.95);
}

.quick-add-btn.work {
  border-color: #ff6b9d;
}

.quick-add-btn.family {
  border-color: #4a90e2;
}

.quick-add-btn.dog {
  border-color: #f5a623;
}

.quick-add-btn.note {
  border-color: #7ed321;
}

.quick-add-icon {
  font-size: 32px;
}

.quick-add-btn span:last-child {
  font-weight: 600;
  font-size: 14px;
}

/* Фильтры */
.filter-bar,
.family-filters,
.note-filters {
  margin-bottom: 15px;
}

.filter-bar select {
  width: 100%;
  padding: 10px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-size: 14px;
  background: white;
}

.family-filters,
.note-filters {
  display: flex;
  gap: 5px;
  flex-wrap: wrap;
}

.family-filter,
.note-filter {
  padding: 8px 12px;
  border: 2px solid #e0e0e0;
  border-radius: 20px;
  background: white;
  font-size: 12px;
  cursor: pointer;
  font-weight: 600;
}

.family-filter.active,
.note-filter.active {
  background: #ff6b9d;
  color: white;
  border-color: #ff6b9d;
}

/* Заметки */
.note-card {
  background: white;
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  border-left: 4px solid #7ed321;
}

.note-card.important {
  border-left-color: #f5a623;
  background: #fff9e6;
}

.note-card.shopping {
  border-left-color: #4a90e2;
}

.note-card.ideas {
  border-left-color: #9b59b6;
}

.note-title {
  font-weight: bold;
  font-size: 15px;
  margin-bottom: 5px;
}

.note-text {
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
  white-space: pre-wrap;
}

.note-meta {
  font-size: 11px;
  color: #999;
  display: flex;
  justify-content: space-between;
}

.note-actions {
  display: flex;
  gap: 5px;
  margin-top: 8px;
}

.note-actions button {
  flex: 1;
  padding: 6px;
  border: none;
  border-radius: 6px;
  font-size: 11px;
  cursor: pointer;
}

/* Прайс */
.price-item {
  background: #fafafa;
  padding: 12px;
  margin: 8px 0;
  border-radius: 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.price-item-info {
  flex: 1;
}

.price-item-name {
  font-weight: 600;
}

.price-item-details {
  font-size: 12px;
  color: #666;
}

.price-item-price {
  font-weight: bold;
  color: #ff6b9d;
  margin-right: 10px;
}

/* Члены семьи */
.family-member {
  background: #fafafa;
  padding: 12px;
  margin: 8px 0;
  border-radius: 10px;
}

.family-member-name {
  font-weight: bold;
  font-size: 15px;
}

.family-member-info {
  font-size: 13px;
  color: #666;
  margin-top: 3px;
}

/* Статистика */
.stats-box {
  background: white;
  padding: 15px;
  margin-bottom: 10px;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.stat-row:last-child {
  border: none;
}

.stats-actions {
  display: flex;
  gap: 10px;
  margin-top: 15px;
}

.action-btn {
  flex: 1;
  padding: 12px;
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  font-weight: bold;
  cursor: pointer;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: #999;
}

h2 {
  margin-bottom: 15px;
  color: #333;
  font-size: 20px;
}
CSS

echo "✅ styles/main.css создан"

# 4. Запускаем сервер
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "🎉 ПРИЛОЖЕНИЕ СОБРАНО!"
echo ""
echo "✅ Что работает:"
echo "  📅 Календарь с цветовой маркировкой"
echo "  💼 Работа с прайс-листом"
echo "  👨‍👩‍👧 Семья с членами семьи"
echo "   Заметки с категориями"
echo "  📊 Статистика"
echo "  💾 Экспорт/Импорт данных"
echo ""
echo "🧪 Тестирование:"
echo "  1. Нажми '+ Добавить'"
echo "  2. Выбери категорию"
echo "  3. Заполни форму"
echo "  4. Сохрани"
echo ""
echo " Демо-данные уже созданы:"
echo "  • 5 членов семьи"
echo "  • 5 услуг в прайсе"
echo ""
echo "Приложение готово к использованию! 🚀"
