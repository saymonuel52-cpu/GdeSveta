/**
 * APP.JS v3.1 - УПРОЩЕННАЯ ФОРМА РАБОТЫ
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log(' ГдеСвета v3.1 запускается...');
  Store.init();
  setupTabs();
  setupExportImport();
  CalendarView.init('calendarView');
  WorkView.init('workView');
  FamilyView.init('familyView');
  if (typeof TasksView !== 'undefined') TasksView.init('tasksView');
  NotesView.init('notesView');
  StatsView.init('statsView');
  if (typeof NotificationService !== 'undefined') NotificationService.init();
  initTheme();
  setupEventListeners();
  console.log('✅ Приложение готово!');
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
            if (data.tasks) Storage.set('gdesveta_family_tasks', data.tasks);
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


function openQuickAdd() {
  if (currentTab === 'work') openWorkForm();
  else if (currentTab === 'family') openFamilyForm();
  else if (currentTab === 'tasks') openTaskForm();
  else if (currentTab === 'notes') openNoteForm();
  else {
    const content = `
      <div class="quick-add-grid">
        <button class="quick-add-btn work" onclick="openWorkForm()">
          <span class="quick-add-icon">💼</span><span>Работа</span>
        </button>
        <button class="quick-add-btn family" onclick="openFamilyForm()">
          <span class="quick-add-icon">👨‍👩‍</span><span>Семья</span>
        </button>
        <button class="quick-add-btn note" onclick="openNoteForm()">
          <span class="quick-add-icon">📝</span><span>Заметка</span>
        </button>
      </div>
    `;
    Modal.form({ title: 'Что добавляем?', content });
  }
}

// === УПРОЩЕННАЯ ФОРМА РАБОТЫ - ТОЛЬКО ПРАЙС ===
function openWorkForm(id = null) {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
  }
  
  const priceItems = PriceService.getAll().filter(p => p.active !== false);
  let priceOptions = '<option value="">-- Выберите услугу из прайса --</option>';
  priceItems.forEach(p => {
    const selected = entry && entry.name === p.name ? 'selected' : '';
    priceOptions += `<option value="${p.id}" data-duration="${p.duration}" data-price="${p.price}" data-service="${p.service}" ${selected}>${p.name} (${p.duration} мин, ${p.price}₽)</option>`;
  });
  
  const content = `
    <form id="workForm" onsubmit="return handleWorkSubmit(event)">
      <input type="hidden" id="entryId" value="${id || ''}">
      <input type="hidden" id="entryCategory" value="work">
      
      <label>Услуга из прайса *</label>
      <select id="priceSelector" onchange="applyPrice()" required>
        ${priceOptions}
      </select>
      
      <label>Имя клиента *</label>
      <input type="text" id="clientName" value="${entry ? entry.name : ''}" required placeholder="Напр. Мария">
      
      <label>Телефон</label>
      <input type="tel" id="clientPhone" value="${entry ? entry.phone : ''}" placeholder="+7 (999) 999-99-99">
      
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

window.applyPrice = function() {
  const selector = document.getElementById('priceSelector');
  const selectedOption = selector.options[selector.selectedIndex];
  
  if (selectedOption && selectedOption.value) {
    const duration = selectedOption.dataset.duration;
    const price = selectedOption.dataset.price;
    
    document.getElementById('entryDuration').value = duration;
    document.getElementById('entryPrice').value = price;
    
    document.querySelectorAll('.duration-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.min === duration);
    });
  }
};

window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const id = document.getElementById('entryId').value;
  const priceSelector = document.getElementById('priceSelector');
  const selectedOption = priceSelector.options[priceSelector.selectedIndex];
  const serviceName = selectedOption ? selectedOption.dataset.service : '';
  
  const data = {
    category: 'work',
    name: serviceName || document.getElementById('clientName').value,
    phone: document.getElementById('clientPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: serviceName,
    zone: '',
    notes: document.getElementById('entryNotes').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    status: document.getElementById('entryStatus')?.value || 'new'
  };
  
  try {
    if (id) EntryService.update(parseInt(id), data);
    else EntryService.create(data);
    
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

window.setDuration = function(mins) {
  document.querySelectorAll('.duration-btn').forEach(b => b.classList.remove('active'));
  document.querySelector(`.duration-btn[data-min="${mins}"]`).classList.add('active');
  document.getElementById('entryDuration').value = mins;
};

// === СЕМЕЙНАЯ ФОРМА ===
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
        <option value="Школа" ${entry && entry.service === 'Школа' ? 'selected' : ''}>🏫 Школа</option>
        <option value="Садик" ${entry && entry.service === 'Садик' ? 'selected' : ''}>🏫 Садик</option>
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
      <input type="text" id="eventLocation" value="${entry ? entry.zone : ''}" placeholder="Напр. Школа №5">
      
      <div class="form-actions">
        <button type="submit" class="save-btn">Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({
    title: id ? '✏️ Редактировать событие' : '👨‍👧 Новое событие (семья)',
    content
  });
}

window.handleFamilySubmit = function(e) {
  e.preventDefault();
  const id = document.getElementById('entryId').value;
  const startTime = document.getElementById('entryTime').value;
  const endTime = document.getElementById('endTime').value;
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
    notes: '',
    familyMemberId: parseInt(document.getElementById('familyMemberId').value) || null,
    price: 0,
    status: 'new'
  };
  
  try {
    if (id) EntryService.update(parseInt(id), data);
    else EntryService.create(data);
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
  
  Modal.form({ title: id ? '✏️ Редактировать заметку' : '📝 Новая заметка', content });
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

function openTaskForm() {
  const content = `
    <form id="taskForm" onsubmit="return handleTaskSubmit(event)">
      <label>Задача *</label>
      <input type="text" id="taskText" required placeholder="Что нужно сделать?">
      <label>Категория</label>
      <select id="taskCategory">
        <option value="general">📋 Обычная</option>
        <option value="shopping">🛒 Покупки</option>
        <option value="home"> Дом</option>
        <option value="kids">👶 Дети</option>
        <option value="dog">🐕 Собака</option>
        <option value="important">⭐ Важная</option>
      </select>
      <label>Кому поручить</label>
      <input type="text" id="taskAssigned" placeholder="Напр. Муж">
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

window.deleteEntry = function(id) {
  console.log('deleteEntry', id);
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
  Modal.confirm('⚠️ Удалить ВСЕ данные?', () => {
    localStorage.clear();
    Modal.close();
    setTimeout(() => {
      Modal.alert('✅ Все данные удалены.');
      setTimeout(() => location.reload(), 1500);
    }, 100);
  });
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
          ${m.school ? '🏫 ' + m.school + '<br>' : ''}
          ${m.breed ? '🐕 Порода: ' + m.breed + '<br>' : ''}
          ${m.circles && m.circles.length > 0 ? '🎨 ' + FamilyMember.getCirclesText(m.circles) : ''}
        </div>
        <button class="btn-del" onclick="deleteFamilyMember(${m.id})" style="margin-top:8px;width:100%;">🗑️ Удалить</button>
      </div>
    `).join('');
  content += `<button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить</button>`;
  Modal.form({ title: ' Члены семьи', content });
}

window.addFamilyMember = function() {
  Modal.close();
  setTimeout(() => {
    const name = prompt('Имя:'); if (!name) return;
    const role = prompt('Кто? (child/adult/dog):', 'child');
    const age = role === 'dog' ? null : parseInt(prompt('Возраст:', '10'));
    const school = prompt('Школа/Садик:', '');
    const breed = role === 'dog' ? prompt('Порода:', '') : null;
    const circlesStr = prompt('Кружки:', '');
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

console.log('✅ app.js v3.1 загружен');

// Глобальная функция для обновления всех views
window.refreshAllViews = function() {
  if (typeof CalendarView !== 'undefined') CalendarView.render();
  if (typeof WorkView !== 'undefined') WorkView.render();
  if (typeof FamilyView !== 'undefined') FamilyView.render();
  if (typeof NotesView !== 'undefined') NotesView.render();
  if (typeof TasksView !== 'undefined') TasksView.render();
};

// === ТЁМНАЯ ТЕМА ===
function initTheme() {
  console.log(' initTheme вызван');
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  console.log('   savedTheme:', savedTheme);
  console.log('   toggle:', toggle);
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) {
      toggle.textContent = '️';
      console.log('   Применена тёмная тема');
    }
  }
  
  if (toggle) {
    toggle.onclick = function() {
      console.log('🔴 Кнопка темы нажата!');
      body.classList.toggle('dark-theme');
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      this.textContent = isDark ? '☀️' : '🌙';
      console.log('   Тема переключена:', isDark ? 'тёмная' : 'светлая');
    };
    console.log('   Обработчик клика добавлен');
  } else {
    console.error(' Кнопка #themeToggle не найдена!');
  }
}

// Вызываем ПРИ ЗАГРУЗКЕ
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initTheme);
} else {
  initTheme();
}

// === ИСПРАВЛЕННАЯ ТЁМНАЯ ТЕМА ===
function initTheme() {
  console.log('🌙 initTheme вызван');
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  console.log('  savedTheme:', savedTheme);
  console.log('  toggle:', toggle);
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) {
      toggle.textContent = '☀️';
      console.log('  Применена тёмная тема');
    }
  }
  
  if (toggle) {
    toggle.onclick = function() {
      console.log('🔴 Кнопка темы нажата!');
      body.classList.toggle('dark-theme');
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      this.textContent = isDark ? '🌙' : '☀️';
      console.log('  Тема переключена:', isDark ? 'тёмная' : 'светлая');
    };
    console.log('  Обработчик клика добавлен');
  } else {
    console.error('❌ Кнопка #themeToggle не найдена!');
  }
}

// Вызываем ПРИ ЗАГРУЗКЕ
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initTheme);
} else {
  setTimeout(initTheme, 100);
}

// === УЛУЧШЕННАЯ ФОРМА ДОБАВЛЕНИЯ УСЛУГИ ===
window.addPriceItem = function() {
  const content = `
    <form id="priceForm" onsubmit="return savePriceItem(event)">
      <label>Название услуги *</label>
      <input type="text" id="priceName" required placeholder="Напр. Ноги до колен" 
             style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
      
      <label>Тип услуги</label>
      <select id="priceType" style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
        <option value="Шугаринг">💅 Шугаринг</option>
        <option value="LPG-массаж">💆 LPG-массаж</option>
        <option value="Другое">📌 Другое</option>
      </select>
      
      <label>Длительность (минуты)</label>
      <select id="priceDuration" required style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
        <option value="10">⏱️ 10 минут</option>
        <option value="15">⏱️ 15 минут</option>
        <option value="20">⏱️ 20 минут</option>
        <option value="30" selected>⏱️ 30 минут (полчаса)</option>
        <option value="45">⏱️ 45 минут</option>
        <option value="60">⏱️ 1 час</option>
        <option value="90">️ 1.5 часа</option>
        <option value="120">⏱️ 2 часа</option>
      </select>
      
      <label>Цена (₽) *</label>
      <input type="number" id="priceValue" required placeholder="Напр. 1500" min="0"
             style="width:100%;padding:10px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:8px;">
      
      <div style="background:#fff3e0;padding:12px;border-radius:8px;margin-bottom:15px;font-size:13px;">
        💡 <b>Совет:</b> Укажи реальную цену и время для точного планирования
      </div>
      
      <div class="form-actions">
        <button type="submit" class="save-btn" style="flex:1;">💾 Сохранить</button>
        <button type="button" class="cancel-btn" onclick="Modal.close()" style="flex:1;">Отмена</button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '💰 Добавить услугу в прайс', content });
};

// Функция сохранения
window.savePriceItem = function(e) {
  e.preventDefault();
  
  const name = document.getElementById('priceName').value;
  const type = document.getElementById('priceType').value;
  const duration = parseInt(document.getElementById('priceDuration').value);
  const price = parseInt(document.getElementById('priceValue').value);
  
  try {
    PriceService.create({ name, service: type, duration, price });
    Modal.close();
    Modal.alert(`✅ Услуга "${name}" добавлена в прайс!\n\n⏱️ ${duration} мин\n💰 ${price}₽`);
    setTimeout(() => {
      if (typeof showPriceList === 'function') showPriceList();
    }, 500);
  } catch (error) {
    Modal.alert('❌ Ошибка: ' + error.message);
  }
  
  return false;
};

// === ФУНКЦИЯ ОТРИСОВКИ УТРЕННЕГО БРИФИНГА ===
function renderMorningBriefing() {
  const briefing = Predictor.getMorningBriefing();
  const calendarView = document.getElementById('calendarView');
  if (!calendarView) return;

  let reminderHtml = '';
  if (briefing.reminders.length > 0) {
    reminderHtml = `<div style="background:#fff3e0; border-left:4px solid #ff9800; padding:10px; margin-top:10px; border-radius:4px;">
      <b>🔔 Пора напомнить о себе (${briefing.reminders.length}):</b>
      <ul style="margin:5px 0 0 20px; padding:0; font-size:13px;">
        ${briefing.reminders.slice(0, 3).map(r => `<li><b>${r.name}</b> (был ${r.daysAgo} дн. назад, средн. интервал: ${r.avgInterval} дн.)</li>`).join('')}
      </ul>
    </div>`;
  }

  const briefingHtml = `
    <div style="background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; padding: 15px; border-radius: 12px; margin-bottom: 15px; box-shadow: 0 4px 10px rgba(255,107,157,0.3);">
      <h3 style="margin:0 0 10px 0; font-size:18px;">☀️ Доброе утро, Света!</h3>
      <p style="margin:0 0 10px 0; opacity:0.9; font-size:14px; text-transform:capitalize;">${briefing.date}</p>
      <div style="display:flex; justify-content:space-between; text-align:center;">
        <div><div style="font-size:20px; font-weight:bold;">${briefing.workCount}</div><div style="font-size:12px; opacity:0.8;">Записей</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.income}₽</div><div style="font-size:12px; opacity:0.8;">Доход сегодня</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.familyCount}</div><div style="font-size:12px; opacity:0.8;">Семейных дел</div></div>
      </div>
      ${reminderHtml}
    </div>
  `;

  // Вставляем брифинг ПЕРЕД календарем
  const container = document.getElementById('calendarContainer') || calendarView;
  if (container.firstChild && container.firstChild.id !== 'morningBriefing') {
    const div = document.createElement('div');
    div.id = 'morningBriefing';
    div.innerHTML = briefingHtml;
    container.insertBefore(div, container.firstChild);
  }
}

// Вызываем при инициализации и при смене вкладки
const originalCalendarRender = CalendarView.render;
CalendarView.render = function() {
  originalCalendarRender.apply(this, arguments);
  setTimeout(renderMorningBriefing, 100); // Небольшая задержка, чтобы DOM успел отрисоваться
};
