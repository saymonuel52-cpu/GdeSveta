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
function renderMorningBriefing() {
  if (typeof Predictor === 'undefined') return;
  const briefing = Predictor.getMorningBriefing();
  const container = document.getElementById('calendarView');
  if (!container || document.getElementById('morningBriefing')) return;

  let reminderHtml = '';
  if (briefing.reminders.length > 0) {
    reminderHtml = `<div style="background:#fff3e0; border-left:4px solid #ff9800; padding:10px; margin-top:10px; border-radius:4px; color:#333;">
      <b>🔔 Пора напомнить о себе:</b>
      <ul style="margin:5px 0 0 20px; padding:0; font-size:13px;">
        ${briefing.reminders.slice(0, 3).map(r => `<li><b>${r.name}</b> (был ${r.daysAgo} дн. назад)</li>`).join('')}
      </ul>
    </div>`;
  }

  const html = `
    <div id="morningBriefing" style="background: linear-gradient(135deg, #ff6b9d, #ff8e53); color: white; padding: 15px; border-radius: 12px; margin-bottom: 15px; box-shadow: 0 4px 10px rgba(255,107,157,0.3);">
      <h3 style="margin:0 0 10px 0; font-size:18px;">☀️ Доброе утро, Света!</h3>
      <p style="margin:0 0 10px 0; opacity:0.9; font-size:14px; text-transform:capitalize;">${briefing.date}</p>
      <div style="display:flex; justify-content:space-between; text-align:center;">
        <div><div style="font-size:20px; font-weight:bold;">${briefing.workCount}</div><div style="font-size:12px; opacity:0.8;">Записей</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.income}₽</div><div style="font-size:12px; opacity:0.8;">Доход</div></div>
        <div><div style="font-size:20px; font-weight:bold;">${briefing.familyCount}</div><div style="font-size:12px; opacity:0.8;">Семья</div></div>
      </div>
      ${reminderHtml}
    </div>
  `;
  container.insertAdjacentHTML('afterbegin', html);
}
const _oldCalRender = CalendarView.render;
CalendarView.render = function() { _oldCalRender.apply(this, arguments); setTimeout(renderMorningBriefing, 200); };

// === ИНТЕГРАЦИЯ ПРОВЕРКИ РАБОЧЕГО ВРЕМЕНИ ===
const _originalHandleWorkSubmit = window.handleWorkSubmit;
window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const date = document.getElementById('entryDate').value;
  const time = document.getElementById('entryTime').value;
  const duration = parseInt(document.getElementById('entryDuration').value);
  
  // Проверяем правила расписания
  const validation = ScheduleRules.validateBooking(date, time, duration);
  
  if (!validation.valid) {
    Modal.alert(validation.errors.join('\n'));
    return false;
  }
  
  if (validation.warnings.length > 0) {
    Modal.confirm(validation.warnings.join('\n') + '\n\nПродолжить?', () => {
      _originalHandleWorkSubmit(e);
    });
    return false;
  }
  
  _originalHandleWorkSubmit(e);
  return false;
};

// === ПРОСТЫЕ НАСТРОЙКИ РАБОЧЕГО ВРЕМЕНИ (встроено) ===
window.openScheduleSettings = function() {
  console.log('🔧 openScheduleSettings вызван!');
  
  // Получаем текущие настройки или используем значения по умолчанию
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workDays":[1,2,3,4,5,6],"workStart":"09:00","workEnd":"20:00","lunchBreak":{"enabled":false,"start":"13:00","end":"14:00"},"bufferTime":10,"maxBookingsPerDay":8}'));
  
  const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
  
  const content = `
    <form id="scheduleForm" onsubmit="return window.saveScheduleSettings(event)">
      <label style="display:block;margin-bottom:10px;font-weight:600;">Рабочие дни (отметьте галочкой):</label>
      <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:20px;">
        ${[0,1,2,3,4,5,6].map(day => `
          <label style="display:flex;flex-direction:column;align-items:center;padding:12px;background:${settings.workDays.includes(day) ? '#ff6b9d' : '#f0f0f0'};border-radius:10px;cursor:pointer;transition:all 0.2s;">
            <input type="checkbox" name="workDays" value="${day}" 
              ${settings.workDays.includes(day) ? 'checked' : ''} 
              style="width:20px;height:20px;margin-bottom:8px;"
              onchange="this.parentElement.style.background=this.checked?'#ff6b9d':'#f0f0f0'">
            <span style="font-size:14px;font-weight:600;">${dayNames[day]}</span>
          </label>
        `).join('')}
      </div>
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">Начало рабочего дня:</label>
      <input type="time" id="workStart" value="${settings.workStart}" required 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">Конец рабочего дня:</label>
      <input type="time" id="workEnd" value="${settings.workEnd}" required 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label style="display:flex;align-items:center;gap:10px;margin:15px 0;padding:15px;background:#f8f8f8;border-radius:10px;cursor:pointer;">
        <input type="checkbox" id="lunchEnabled" 
          ${settings.lunchBreak.enabled ? 'checked' : ''}
          onchange="document.getElementById('lunchSettings').style.display = this.checked ? 'block' : 'none'"
          style="width:22px;height:22px;">
        <span style="font-weight:600;font-size:16px;">🍽️ Обеденный перерыв</span>
      </label>
      
      <div id="lunchSettings" style="display: ${settings.lunchBreak.enabled ? 'block' : 'none'};margin-bottom:15px;">
        <label style="display:block;margin-bottom:5px;">Начало обеда:</label>
        <input type="time" id="lunchStart" value="${settings.lunchBreak.start}" 
          style="width:100%;padding:12px;margin-bottom:10px;border:2px solid #e0e0e0;border-radius:10px;">
        
        <label style="display:block;margin-bottom:5px;">Конец обеда:</label>
        <input type="time" id="lunchEnd" value="${settings.lunchBreak.end}" 
          style="width:100%;padding:12px;margin-bottom:10px;border:2px solid #e0e0e0;border-radius:10px;">
      </div>
      
      <label style="display:block;margin-bottom:5px;font-weight:600;">⏱️ Буфер между записями (минут):</label>
      <input type="number" id="bufferTime" value="${settings.bufferTime}" min="0" max="60" 
        style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit" 
          style="flex:1;padding:15px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(255,107,157,0.4);">
          💾 Сохранить настройки
        </button>
        <button type="button" onclick="Modal.close()" 
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '⚙️ Настройки рабочего времени', content });
};

window.saveScheduleSettings = function(e) {
  e.preventDefault();
  console.log('💾 Сохранение настроек...');
  
  const workDays = Array.from(document.querySelectorAll('input[name="workDays"]:checked'))
    .map(cb => parseInt(cb.value));
  
  if (workDays.length === 0) {
    Modal.alert('❌ Выберите хотя бы один рабочий день!');
    return false;
  }
  
  const settings = {
    workDays,
    workStart: document.getElementById('workStart').value,
    workEnd: document.getElementById('workEnd').value,
    lunchBreak: {
      enabled: document.getElementById('lunchEnabled').checked,
      start: document.getElementById('lunchStart').value,
      end: document.getElementById('lunchEnd').value
    },
    bufferTime: parseInt(document.getElementById('bufferTime').value),
    maxBookingsPerDay: 8
  };
  
  Storage.set('scheduleRules', JSON.stringify(settings));
  Modal.close();
  
  setTimeout(() => {
    Modal.alert('✅ Настройки рабочего времени сохранены!\n\nТеперь при добавлении записей система будет проверять:\n• Рабочие дни\n• Рабочие часы\n• Обеденный перерыв\n• Буфер между записями');
  }, 100);
  
  return false;
};

console.log('✅ Функции настроек загружены');

// === СИСТЕМА БУФЕРНОГО ВРЕМЕНИ ===

// Получить буфер для конкретной услуги
window.getServiceBuffer = function(serviceName) {
  const buffers = {
    'Шугаринг': 15,
    'LPG-массаж': 10,
    'Другое': 10
  };
  return buffers[serviceName] || 10;
};

// Проверить конфликты с учётом буфера
window.checkTimeConflicts = function(date, time, duration, serviceName, excludeId = null) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
  const baseBuffer = settings.bufferTime || 10;
  const serviceBuffer = getServiceBuffer(serviceName);
  const totalBuffer = Math.max(baseBuffer, serviceBuffer);
  
  const entries = Store.getEntries()
    .filter(e => e.date === date && e.category === 'work' && e.id !== excludeId);
  
  const [newHours, newMinutes] = time.split(':').map(Number);
  const newStart = newHours * 60 + newMinutes;
  const newEnd = newStart + duration;
  
  const conflicts = [];
  
  for (const entry of entries) {
    const [eHours, eMinutes] = entry.time.split(':').map(Number);
    const eStart = eHours * 60 + eMinutes;
    const eEnd = eStart + entry.duration;
    
    // Проверяем пересечение с учётом буфера
    const bufferMinutes = totalBuffer;
    
    if (newStart < eEnd + bufferMinutes && newEnd + bufferMinutes > eStart) {
      const conflictType = (newStart >= eStart && newEnd <= eEnd) ? 'overlap' : 'too_close';
      conflicts.push({
        entry,
        type: conflictType,
        message: conflictType === 'overlap' 
          ? `⛔ Пересечение с "${entry.name}" (${entry.time}-${Entry.getEndTime(entry)})`
          : `⚠️ Слишком близко к "${entry.name}" (нужно ${bufferMinutes} мин перерыва)`
      });
    }
  }
  
  return conflicts;
};

// Найти ближайшее свободное время
window.findNextAvailableTime = function(date, desiredTime, duration, serviceName) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workStart":"09:00","workEnd":"20:00"}'));
  const [startH, startM] = settings.workStart.split(':').map(Number);
  const [endH, endM] = settings.workEnd.split(':').map(Number);
  const dayStart = startH * 60 + startM;
  const dayEnd = endH * 60 + endM;
  
  const [dHours, dMinutes] = desiredTime.split(':').map(Number);
  let currentTime = dHours * 60 + dMinutes;
  
  // Если время уже прошло — начинаем с текущего
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  if (date === todayStr) {
    const nowMinutes = now.getHours() * 60 + now.getMinutes();
    if (currentTime < nowMinutes) currentTime = nowMinutes;
  }
  
  // Пробуем найти свободное окно
  while (currentTime + duration <= dayEnd) {
    const timeStr = `${Math.floor(currentTime/60).toString().padStart(2,'0')}:${(currentTime%60).toString().padStart(2,'0')}`;
    const conflicts = checkTimeConflicts(date, timeStr, duration, serviceName);
    
    if (conflicts.length === 0) {
      return timeStr;
    }
    
    // Пропускаем конфликтующую запись + буфер
    const conflict = conflicts[0].entry;
    const [eH, eM] = conflict.time.split(':').map(Number);
    currentTime = eH * 60 + eM + conflict.duration + 15;
  }
  
  return null; // Нет свободного времени
};

// Интеграция проверки в форму работы
const _origHandleWorkSubmit = window.handleWorkSubmit;
window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const date = document.getElementById('entryDate').value;
  const time = document.getElementById('entryTime').value;
  const duration = parseInt(document.getElementById('entryDuration').value);
  const serviceType = document.getElementById('serviceType')?.value || 'Другое';
  const entryId = document.getElementById('entryId').value;
  
  // Проверяем конфликты
  const conflicts = checkTimeConflicts(date, time, duration, serviceType, entryId ? parseInt(entryId) : null);
  
  if (conflicts.length > 0) {
    const conflictMsg = conflicts.map(c => c.message).join('\n');
    const nextTime = findNextAvailableTime(date, time, duration, serviceType);
    
    let suggestMsg = '';
    if (nextTime) {
      suggestMsg = `\n\n💡 Ближайшее свободное время: ${nextTime}`;
    }
    
    Modal.confirm(
      `${conflictMsg}${suggestMsg}\n\nВсё равно сохранить?`,
      () => {
        // Пользователь согласен — сохраняем
        if (_origHandleWorkSubmit) _origHandleWorkSubmit(e);
        else {
          // Резервный вариант сохранения
          const data = {
            category: 'work',
            name: document.getElementById('clientName').value,
            phone: document.getElementById('clientPhone')?.value || '',
            date,
            time,
            duration,
            service: serviceType,
            zone: document.getElementById('serviceZone')?.value || '',
            notes: document.getElementById('entryNotes')?.value || '',
            price: parseInt(document.getElementById('entryPrice')?.value || 0),
            status: 'new'
          };
          EntryService.create(data);
          Modal.close();
          Modal.alert('✅ Запись сохранена!');
          setTimeout(() => {
            if (typeof WorkView !== 'undefined') WorkView.render();
            if (typeof CalendarView !== 'undefined') CalendarView.render();
          }, 200);
        }
      },
      () => {
        // Пользователь отменил — предлагаем свободное время
        if (nextTime) {
          document.getElementById('entryTime').value = nextTime;
          Modal.alert(`⏰ Время изменено на ${nextTime}`);
        }
      }
    );
    return false;
  }
  
  // Нет конфликтов — сохраняем
  if (_origHandleWorkSubmit) _origHandleWorkSubmit(e);
  return false;
};

// Добавляем подсказку в форму работы
const _origOpenWorkForm = window.openWorkForm;
window.openWorkForm = function(id = null) {
  if (_origOpenWorkForm) _origOpenWorkForm(id);
  
  // После открытия формы добавляем подсказку о буфере
  setTimeout(() => {
    const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
    const bufferHint = document.createElement('div');
    bufferHint.id = 'bufferHint';
    bufferHint.style.cssText = 'background:#fff3e0;border-left:4px solid #ff9800;padding:10px;margin:10px 0;border-radius:8px;font-size:13px;color:#333;';
    bufferHint.innerHTML = `⏱️ Буфер между записями: <b>${settings.bufferTime || 10} мин</b> (автоматически добавляется)`;
    
    const form = document.getElementById('workForm');
    if (form && !document.getElementById('bufferHint')) {
      form.insertBefore(bufferHint, form.firstChild);
    }
  }, 100);
};

console.log('✅ Система буферного времени загружена');

// === ИСПРАВЛЕННАЯ СИСТЕМА БУФЕРОВ ===

// Проверка конфликтов с учётом буфера
window.checkTimeConflicts = function(date, time, duration, serviceName, excludeId = null) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
  const baseBuffer = settings.bufferTime || 10;
  
  const entries = Store.getEntries()
    .filter(e => e.date === date && e.category === 'work' && e.id !== excludeId);
  
  const [newHours, newMinutes] = time.split(':').map(Number);
  const newStart = newHours * 60 + newMinutes;
  const newEnd = newStart + duration;
  
  const conflicts = [];
  
  for (const entry of entries) {
    const [eHours, eMinutes] = entry.time.split(':').map(Number);
    const eStart = eHours * 60 + eMinutes;
    const eEnd = eStart + entry.duration;
    
    // Проверяем пересечение с учётом буфера
    if (newStart < eEnd + baseBuffer && newEnd + baseBuffer > eStart) {
      const gap = Math.min(
        newStart - eEnd,  // перерыв после предыдущей
        eStart - newEnd   // перерыв до следующей
      );
      
      conflicts.push({
        entry,
        gap: gap,
        message: gap > 0 
          ? `⚠️ Перерыв ${gap} мин (рекомендуется ${baseBuffer} мин)`
          : `⛔ Пересечение с "${entry.name}" (${entry.time}-${Entry.getEndTime(entry)})`
      });
    }
  }
  
  return conflicts;
};

// Найти ближайшее свободное время
window.findNextAvailableTime = function(date, desiredTime, duration, serviceName) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workStart":"09:00","workEnd":"20:00","bufferTime":10}'));
  const buffer = settings.bufferTime || 10;
  const [startH, startM] = settings.workStart.split(':').map(Number);
  const [endH, endM] = settings.workEnd.split(':').map(Number);
  const dayStart = startH * 60 + startM;
  const dayEnd = endH * 60 + endM;
  
  const [dHours, dMinutes] = desiredTime.split(':').map(Number);
  let currentTime = Math.max(dHours * 60 + dMinutes, dayStart);
  
  // Пробуем найти свободное окно
  while (currentTime + duration <= dayEnd) {
    const timeStr = `${Math.floor(currentTime/60).toString().padStart(2,'0')}:${(currentTime%60).toString().padStart(2,'0')}`;
    const conflicts = checkTimeConflicts(date, timeStr, duration, serviceName);
    
    if (conflicts.length === 0) {
      return timeStr;
    }
    
    // Пропускаем конфликтующую запись + буфер
    const conflict = conflicts[0].entry;
    const [eH, eM] = conflict.time.split(':').map(Number);
    currentTime = eH * 60 + eM + conflict.duration + buffer;
  }
  
  return null;
};

// Сохранение записи с проверкой конфликтов
window.saveWorkEntryWithCheck = function(formData, entryId) {
  const conflicts = checkTimeConflicts(
    formData.date, 
    formData.time, 
    formData.duration, 
    formData.service, 
    entryId
  );
  
  if (conflicts.length > 0) {
    const conflictMsg = conflicts.map(c => c.message).join('\n');
    const nextTime = findNextAvailableTime(formData.date, formData.time, formData.duration, formData.service);
    
    let suggestMsg = nextTime ? `\n\n💡 Ближайшее свободное: ${nextTime}` : '';
    
    // Показываем предупреждение с ДВУМЯ кнопками
    Modal.confirm(
      `${conflictMsg}${suggestMsg}\n\nСохранить запись?`,
      // Кнопка "ДА" — сохраняем
      () => {
        // Добавляем пометку о маленьком перерыве
        const hasSmallGap = conflicts.some(c => c.gap > 0 && c.gap < 10);
        if (hasSmallGap) {
          formData.notes = (formData.notes || '') + ' ️ Малый перерыв';
        }
        
        // Сохраняем запись
        if (entryId) {
          EntryService.update(entryId, formData);
        } else {
          EntryService.create(formData);
        }
        
        Modal.close();
        Modal.alert('✅ Запись сохранена!');
        setTimeout(() => {
          if (typeof WorkView !== 'undefined') WorkView.render();
          if (typeof CalendarView !== 'undefined') CalendarView.render();
        }, 200);
      },
      // Кнопка "НЕТ" — предлагаем свободное время
      () => {
        if (nextTime) {
          // Обновляем время в форме
          const timeInput = document.getElementById('entryTime');
          if (timeInput) {
            timeInput.value = nextTime;
          }
          Modal.alert(`⏰ Время изменено на ${nextTime}`);
        } else {
          Modal.alert('❌ Нет свободного времени на этот день');
        }
      }
    );
    return false; // Не сохраняем сразу, ждём выбора пользователя
  }
  
  // Нет конфликтов — сохраняем сразу
  if (entryId) {
    EntryService.update(entryId, formData);
  } else {
    EntryService.create(formData);
  }
  return true;
};

// Перехватываем сохранение формы работы
window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const entryId = document.getElementById('entryId').value;
  const formData = {
    category: 'work',
    name: document.getElementById('clientName').value,
    phone: document.getElementById('clientPhone')?.value || '',
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('serviceType')?.value || 'Другое',
    zone: document.getElementById('serviceZone')?.value || '',
    notes: document.getElementById('entryNotes')?.value || '',
    price: parseInt(document.getElementById('entryPrice')?.value || 0),
    status: document.getElementById('entryStatus')?.value || 'new'
  };
  
  saveWorkEntryWithCheck(formData, entryId ? parseInt(entryId) : null);
  return false;
};

console.log('✅ Исправленная система буферов загружена');

// === СИСТЕМА ПРИОРИТЕТОВ ===

// Приоритеты событий
window.EVENT_PRIORITY = {
  CRITICAL: { level: 3, label: ' Критично', color: '#ef4444', items: ['Школа', 'Врач', 'Работа', 'Экзамен'] },
  IMPORTANT: { level: 2, label: '🟡 Важно', color: '#f59e0b', items: ['Кружок', 'Секция', 'Стоматолог'] },
  FLEXIBLE: { level: 1, label: ' Гибко', color: '#10b981', items: ['Прогулка', 'Заметка', 'Покупки', 'Встреча'] }
};

// Определить приоритет события
window.getEventPriority = function(entry) {
  const name = entry.name || '';
  const service = entry.service || '';
  const category = entry.category || '';
  
  // Проверяем по названию и услуге
  for (const [key, priority] of Object.entries(EVENT_PRIORITY)) {
    if (priority.items.some(item => name.includes(item) || service.includes(item))) {
      return { key, ...priority };
    }
  }
  
  // По категории
  if (category === 'work') return { key: 'CRITICAL', ...EVENT_PRIORITY.CRITICAL };
  if (category === 'family') {
    if (name.includes('Школа') || name.includes('Врач')) return { key: 'CRITICAL', ...EVENT_PRIORITY.CRITICAL };
    if (name.includes('Кружок') || name.includes('Секция')) return { key: 'IMPORTANT', ...EVENT_PRIORITY.IMPORTANT };
  }
  if (category === 'dog' || name.includes('Собака') || name.includes('Прогулка')) {
    return { key: 'FLEXIBLE', ...EVENT_PRIORITY.FLEXIBLE };
  }
  
  return { key: 'FLEXIBLE', ...EVENT_PRIORITY.FLEXIBLE };
};

// Умная проверка конфликтов с приоритетами
window.checkSmartConflicts = function(date, time, duration, newEntry, excludeId = null) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"bufferTime":10}'));
  const buffer = settings.bufferTime || 10;
  
  const entries = Store.getEntries()
    .filter(e => e.date === date && e.category !== 'note' && e.id !== excludeId);
  
  const [newHours, newMinutes] = time.split(':').map(Number);
  const newStart = newHours * 60 + newMinutes;
  const newEnd = newStart + duration;
  const newPriority = getEventPriority(newEntry);
  
  const conflicts = [];
  
  for (const entry of entries) {
    const [eHours, eMinutes] = entry.time.split(':').map(Number);
    const eStart = eHours * 60 + eMinutes;
    const eEnd = eStart + entry.duration;
    
    // Проверяем пересечение с буфером
    if (newStart < eEnd + buffer && newEnd + buffer > eStart) {
      const existingPriority = getEventPriority(entry);
      const gap = Math.min(newStart - eEnd, eStart - newEnd);
      
      conflicts.push({
        entry,
        existingPriority,
        newPriority,
        gap,
        message: gap > 0 
          ? `${existingPriority.label} "${entry.name}" (${entry.time}) — перерыв ${gap} мин`
          : `${existingPriority.label} "${entry.name}" (${entry.time}-${Entry.getEndTime(entry)}) — пересечение`
      });
    }
  }
  
  return conflicts;
};

// Умное предложение при конфликте
window.getSmartSuggestion = function(conflicts, date, time, duration) {
  if (conflicts.length === 0) return null;
  
  // Находим конфликт с наивысшим приоритетом
  const highestConflict = conflicts.reduce((max, c) => 
    c.existingPriority.level > max.existingPriority.level ? c : max
  );
  
  const newPriority = conflicts[0].newPriority;
  
  // Если новое событие важнее — предлагаем перенести старое
  if (newPriority.level > highestConflict.existingPriority.level) {
    return {
      action: 'move_existing',
      message: `💡 "${highestConflict.entry.name}" (${highestConflict.existingPriority.label}) можно перенести`,
      suggestion: `Перенести "${highestConflict.entry.name}" на другое время?`
    };
  }
  
  // Если старое событие важнее — предлагаем другое время для нового
  if (newPriority.level < highestConflict.existingPriority.level) {
    const nextTime = findNextAvailableTime(date, time, duration, newEntry.service);
    return {
      action: 'move_new',
      message: `⚠️ "${highestConflict.entry.name}" (${highestConflict.existingPriority.label}) нельзя переносить`,
      suggestion: nextTime ? `Перенести новую запись на ${nextTime}?` : 'Нет свободного времени'
    };
  }
  
  // Равные приоритеты — показываем оба варианта
  const nextTime = findNextAvailableTime(date, time, duration, newEntry.service);
  return {
    action: 'choose',
    message: `⚖️ Оба события имеют одинаковый приоритет`,
    suggestion: nextTime ? `Перенести новую запись на ${nextTime} или сохранить обе?` : 'Сохранить обе?'
  };
};

// Сохранение с умными конфликтами
window.saveWorkEntrySmart = function(formData, entryId) {
  const conflicts = checkSmartConflicts(formData.date, formData.time, formData.duration, formData, entryId);
  
  if (conflicts.length > 0) {
    const suggestion = getSmartSuggestion(conflicts, formData.date, formData.time, formData.duration);
    const conflictMsg = conflicts.map(c => c.message).join('\n');
    
    let buttons = [];
    
    if (suggestion.action === 'move_existing') {
      // Предложить перенести старое событие
      Modal.confirm(
        `${conflictMsg}\n\n${suggestion.suggestion}`,
        () => {
          // Сохраняем новую запись
          if (entryId) EntryService.update(entryId, formData);
          else EntryService.create(formData);
          Modal.close();
          Modal.alert('✅ Запись сохранена! Старое событие нужно перенести вручную.');
          setTimeout(() => {
            if (typeof WorkView !== 'undefined') WorkView.render();
            if (typeof CalendarView !== 'undefined') CalendarView.render();
          }, 200);
        },
        () => {
          Modal.alert('❌ Запись отменена');
        }
      );
    } else if (suggestion.action === 'move_new') {
      // Предложить перенести новую запись
      const nextTime = findNextAvailableTime(formData.date, formData.time, formData.duration, formData.service);
      Modal.confirm(
        `${conflictMsg}\n\n${suggestion.suggestion}`,
        () => {
          if (nextTime) {
            formData.time = nextTime;
            if (entryId) EntryService.update(entryId, formData);
            else EntryService.create(formData);
            Modal.close();
            Modal.alert(`✅ Запись сохранена на ${nextTime}`);
            setTimeout(() => {
              if (typeof WorkView !== 'undefined') WorkView.render();
              if (typeof CalendarView !== 'undefined') CalendarView.render();
            }, 200);
          }
        },
        () => {
          Modal.alert('❌ Запись отменена');
        }
      );
    } else {
      // Равные приоритеты — выбор пользователя
      Modal.confirm(
        `${conflictMsg}\n\n${suggestion.suggestion}`,
        () => {
          if (entryId) EntryService.update(entryId, formData);
          else EntryService.create(formData);
          Modal.close();
          Modal.alert('✅ Запись сохранена!');
          setTimeout(() => {
            if (typeof WorkView !== 'undefined') WorkView.render();
            if (typeof CalendarView !== 'undefined') CalendarView.render();
          }, 200);
        },
        () => {
          const nextTime = findNextAvailableTime(formData.date, formData.time, formData.duration, formData.service);
          if (nextTime) {
            formData.time = nextTime;
            if (entryId) EntryService.update(entryId, formData);
            else EntryService.create(formData);
            Modal.close();
            Modal.alert(`✅ Запись перенесена на ${nextTime}`);
            setTimeout(() => {
              if (typeof WorkView !== 'undefined') WorkView.render();
              if (typeof CalendarView !== 'undefined') CalendarView.render();
            }, 200);
          }
        }
      );
    }
    return false;
  }
  
  // Нет конфликтов
  if (entryId) EntryService.update(entryId, formData);
  else EntryService.create(formData);
  return true;
};

// Обновляем handleWorkSubmit для использования умной системы
const _origHandleWorkSubmit2 = window.handleWorkSubmit;
window.handleWorkSubmit = function(e) {
  e.preventDefault();
  
  const entryId = document.getElementById('entryId').value;
  const formData = {
    category: 'work',
    name: document.getElementById('clientName').value,
    phone: document.getElementById('clientPhone')?.value || '',
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('serviceType')?.value || 'Другое',
    zone: document.getElementById('serviceZone')?.value || '',
    notes: document.getElementById('entryNotes')?.value || '',
    price: parseInt(document.getElementById('entryPrice')?.value || 0),
    status: document.getElementById('entryStatus')?.value || 'new'
  };
  
  saveWorkEntrySmart(formData, entryId ? parseInt(entryId) : null);
  return false;
};

console.log('✅ Система приоритетов загружена');

// Патч для EntryCard — добавляем приоритеты
const _origRender = EntryCard.render;
EntryCard.render = function(entry, options) {
  const html = _origRender.call(this, entry, options);
  const priority = getEventPriority(entry);
  
  // Добавляем класс приоритета
  return html.replace('class="entry-card', `class="entry-card priority-${priority.key.toLowerCase()}"`);
};

// === ВИЗУАЛЬНЫЙ ПОИСК СВОБОДНЫХ ОКОН ===

// Получить визуальное расписание дня
window.getDayTimeline = function(date) {
  const settings = JSON.parse(Storage.get('scheduleRules', '{"workStart":"09:00","workEnd":"20:00","bufferTime":10}'));
  const buffer = settings.bufferTime || 10;
  const [startH, startM] = settings.workStart.split(':').map(Number);
  const [endH, endM] = settings.workEnd.split(':').map(Number);
  const dayStart = startH * 60 + startM;
  const dayEnd = endH * 60 + endM;
  
  const entries = Store.getEntries()
    .filter(e => e.date === date)
    .sort((a, b) => a.time.localeCompare(b.time));
  
  const slots = [];
  let currentTime = dayStart;
  
  for (const entry of entries) {
    const [eH, eM] = entry.time.split(':').map(Number);
    const eStart = eH * 60 + eM;
    const eEnd = eStart + entry.duration;
    
    // Свободное окно перед записью
    if (eStart > currentTime) {
      slots.push({
        type: 'free',
        start: currentTime,
        end: eStart,
        duration: eStart - currentTime
      });
    }
    
    // Запись
    slots.push({
      type: 'busy',
      entry,
      start: eStart,
      end: eEnd,
      duration: entry.duration
    });
    
    // Буфер после записи
    currentTime = eEnd + buffer;
  }
  
  // Последнее свободное окно
  if (currentTime < dayEnd) {
    slots.push({
      type: 'free',
      start: currentTime,
      end: dayEnd,
      duration: dayEnd - currentTime
    });
  }
  
  return slots;
};

// Открыть визуальное расписание
window.openDayTimeline = function(date = null) {
  if (!date) {
    date = new Date().toISOString().split('T')[0];
  }
  
  const slots = getDayTimeline(date);
  const dateFormatted = new Date(date).toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' });
  
  let html = `
    <div style="padding:10px;">
      <h3 style="margin:0 0 15px 0;text-align:center;text-transform:capitalize;">${dateFormatted}</h3>
      <div style="position:relative;">
  `;
  
  slots.forEach((slot, index) => {
    const startStr = `${Math.floor(slot.start/60).toString().padStart(2,'0')}:${(slot.start%60).toString().padStart(2,'0')}`;
    const endStr = `${Math.floor(slot.end/60).toString().padStart(2,'0')}:${(slot.end%60).toString().padStart(2,'0')}`;
    const duration = slot.duration;
    
    if (slot.type === 'free') {
      html += `
        <div onclick="bookFreeSlot('${date}', '${startStr}', ${duration})" 
             style="background:linear-gradient(135deg,#059669,#10b981);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(5,150,105,0.4);border:2px solid #047857;color:white;padding:15px;margin:8px 0;border-radius:12px;cursor:pointer;transition:all 0.2s;box-shadow:0 2px 8px rgba(16,185,129,0.3);"
             onmouseover="this.style.transform='scale(1.02)'"
             onmouseout="this.style.transform='scale(1)'">
          <div style="font-size:18px;font-weight:700;margin-bottom:5px;">✅ Свободно: ${startStr} - ${endStr}</div>
          <div style="font-size:14px;opacity:0.9;">⏱️ ${duration} минут • Нажми, чтобы записать</div>
        </div>
      `;
    } else {
      const entry = slot.entry;
      const priority = getEventPriority(entry);
      const categoryColors = {
        work: 'linear-gradient(135deg,#ff6b9d,#ff8e53)',
        family: 'linear-gradient(135deg,#3b82f6,#60a5fa)',
        dog: 'linear-gradient(135deg,#f59e0b,#fbbf24)',
        note: 'linear-gradient(135deg,#8b5cf6,#a78bfa)'
      };
      const color = categoryColors[entry.category] || categoryColors.work;
      
      html += `
        <div style="background:${color};color:white;padding:15px;margin:8px 0;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.2);">
          <div style="font-size:18px;font-weight:700;margin-bottom:5px;">${entry.name}</div>
          <div style="font-size:14px;opacity:0.9;"> ${startStr} - ${endStr} • ⏱️ ${duration} мин</div>
          ${entry.price ? `<div style="font-size:14px;opacity:0.9;margin-top:5px;">💰 ${entry.price}₽</div>` : ''}
          <div style="font-size:11px;opacity:0.8;margin-top:5px;">${priority.label}</div>
        </div>
      `;
    }
  });
  
  if (slots.length === 0) {
    html += `<div style="text-align:center;padding:40px;color:#999;">Нет записей на этот день</div>`;
  }
  
  html += `
      </div>
      <div style="margin-top:20px;text-align:center;">
        <button onclick="Modal.close()" style="padding:12px 30px;background:#e0e0e0;color:#333;border:none;border-radius:10px;font-weight:600;cursor:pointer;">Закрыть</button>
      </div>
    </div>
  `;
  
  Modal.form({ title: ' Расписание дня', content: html });
};

// Забронировать свободное окно
window.bookFreeSlot = function(date, startTime, duration) {
  Modal.close();
  setTimeout(() => {
    openWorkForm(null);
    setTimeout(() => {
      document.getElementById('entryDate').value = date;
      document.getElementById('entryTime').value = startTime;
      document.getElementById('entryDuration').value = Math.min(duration, 60);
    }, 100);
  }, 200);
};

// Добавить кнопку в интерфейс
const _origWorkViewRender = WorkView.render;
WorkView.render = function() {
  _origWorkViewRender.apply(this, arguments);
  
  // Добавляем кнопку "Свободные окна"
  setTimeout(() => {
    const workView = document.getElementById('workView');
    if (workView && !document.getElementById('freeSlotsBtn')) {
      const btn = document.createElement('button');
      btn.id = 'freeSlotsBtn';
      btn.textContent = '🔍 Свободные окна';
      btn.style.cssText = 'width:100%;padding:15px;margin:15px 0;background:linear-gradient(135deg,#059669,#10b981);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(5,150,105,0.4);border:2px solid #047857;color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;box-shadow:0 4px 12px rgba(16,185,129,0.4);';
      btn.onclick = () => openDayTimeline();
      workView.insertBefore(btn, workView.firstChild);
    }
  }, 100);
};

console.log('✅ Визуальный поиск свободных окон загружен');

// === ФУНКЦИИ ДЛЯ ВКЛАДКИ СОБАКА ===

// Открыть форму собаки
window.openDogForm = function(id = null) {
  const eventTypes = Object.entries(DogService.eventTypes).map(([key, val]) => 
    `<option value="${val.label}">${val.label}</option>`
  ).join('');
  
  const content = `
    <form id="dogForm" onsubmit="return saveDogEvent(event, ${id})">
      <label>Название события</label>
      <input type="text" id="dogName" placeholder="Напр. Стрижка" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Тип события</label>
      <select id="dogType" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
        ${eventTypes}
      </select>
      
      <label>Дата</label>
      <input type="date" id="dogDate" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Время</label>
      <input type="time" id="dogTime" required 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>Длительность (минут)</label>
      <input type="number" id="dogDuration" value="60" min="10" max="300" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>📍 Адрес / Место</label>
      <input type="text" id="dogAddress" placeholder="Напр. Грумерская 'Лапки', ул. Пушкина 10" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <label>💬 Примечания</label>
      <textarea id="dogNotes" placeholder="Напр. Боится уколов, взять любимый мячик" rows="3" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;"></textarea>
      
      <label> Стоимость (₽)</label>
      <input type="number" id="dogPrice" placeholder="Напр. 2000" min="0" 
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;">
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit" 
          style="flex:1;padding:15px;background:linear-gradient(135deg,#f59e0b,#fbbf24);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          💾 Сохранить
        </button>
        <button type="button" onclick="Modal.close()" 
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: id ? '✏️ Редактировать событие' : '🐕 Добавить событие', content });
  
  // Установить сегодняшнюю дату по умолчанию
  setTimeout(() => {
    document.getElementById('dogDate').value = new Date().toISOString().split('T')[0];
    document.getElementById('dogTime').value = '10:00';
  }, 100);
};

// Сохранить событие собаки
window.saveDogEvent = function(e, id) {
  e.preventDefault();
  
  const data = {
    name: document.getElementById('dogName').value,
    service: document.getElementById('dogType').value,
    date: document.getElementById('dogDate').value,
    time: document.getElementById('dogTime').value,
    duration: parseInt(document.getElementById('dogDuration').value),
    zone: document.getElementById('dogAddress').value,
    notes: document.getElementById('dogNotes').value,
    price: parseInt(document.getElementById('dogPrice').value || 0),
    status: 'new'
  };
  
  if (id) {
    DogService.update(id, data);
  } else {
    DogService.create(data);
  }
  
  Modal.close();
  Modal.alert(id ? '✅ Событие обновлено!' : '✅ Событие создано!');
  setTimeout(() => {
    if (typeof DogView !== 'undefined') DogView.render();
    if (typeof CalendarView !== 'undefined') CalendarView.render();
  }, 200);
  
  return false;
};

// Редактировать событие собаки
window.editDogEvent = function(id) {
  const event = Store.getEntries().find(e => e.id === id);
  if (!event) return;
  
  openDogForm(id);
  
  setTimeout(() => {
    document.getElementById('dogName').value = event.name || '';
    document.getElementById('dogType').value = event.service || '';
    document.getElementById('dogDate').value = event.date;
    document.getElementById('dogTime').value = event.time;
    document.getElementById('dogDuration').value = event.duration;
    document.getElementById('dogAddress').value = event.zone || '';
    document.getElementById('dogNotes').value = event.notes || '';
    document.getElementById('dogPrice').value = event.price || 0;
  }, 100);
};

// Удалить событие собаки
window.deleteDogEvent = function(id) {
  Modal.confirm('Удалить это событие?', () => {
    DogService.delete(id);
    Modal.close();
    Modal.alert('✅ Событие удалено!');
    setTimeout(() => {
      if (typeof DogView !== 'undefined') DogView.render();
      if (typeof CalendarView !== 'undefined') CalendarView.render();
    }, 200);
  });
};

// Переключение карточки собаки
window.toggleDogCard = function(id) {
  const details = document.getElementById(`dog-details-${id}`);
  const actions = document.getElementById(`dog-actions-${id}`);
  
  if (details && actions) {
    const isHidden = details.style.display === 'none';
    details.style.display = isHidden ? 'block' : 'none';
    actions.style.display = isHidden ? 'block' : 'none';
  }
};

// Инициализация вкладки собаки при переключении
const _origSwitchTab = window.switchTab;
window.switchTab = function(tabName) {
  if (_origSwitchTab) _origSwitchTab(tabName);
  
  if (tabName === 'dog') {
    setTimeout(() => {
      if (typeof DogView !== 'undefined') {
        DogView.init('dogView');
      }
    }, 100);
  }
};

console.log('✅ Функции вкладки "Собака" загружены');

// === РЕДАКТИРОВАНИЕ ЧЛЕНОВ СЕМЬИ ===

// Открыть форму редактирования члена семьи
window.editFamilyMember = function(id) {
  console.log('️ editFamilyMember:', id);
  const member = Store.getFamilyMembers().find(m => m.id === id);
  if (!member) {
    Modal.alert('❌ Член семьи не найден!');
    return;
  }
  
  const roles = [
    { value: 'Сын', label: ' Сын' },
    { value: 'Дочь', label: '👧 Дочь' },
    { value: 'Муж', label: '👨 Муж' },
    { value: 'Жена', label: '👩 Жена' },
    { value: 'Другое', label: '👤 Другое' }
  ];
  
  const roleOptions = roles.map(r => 
    `<option value="${r.value}" ${member.role === r.value ? 'selected' : ''}>${r.label}</option>`
  ).join('');
  
  const content = `
    <form id="familyEditForm" onsubmit="return saveFamilyMemberEdit(event, ${id})">
      <label>👤 Имя</label>
      <input type="text" id="editMemberName" value="${member.name || ''}" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎭 Роль в семье</label>
      <select id="editMemberRole" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        ${roleOptions}
      </select>
      
      <label>🏫 Школа / Садик / Работа</label>
      <input type="text" id="editMemberSchool" value="${member.school || member.place || ''}"
        placeholder="Напр. Школа №5, 3 класс"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎂 Возраст</label>
      <input type="number" id="editMemberAge" value="${member.age || ''}" min="0" max="100"
        placeholder="Напр. 8"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
      
      <label>🎨 Кружки / Секции</label>
      <textarea id="editMemberCircles" rows="2"
        placeholder="Напр. Танцы (вт, чт), Плавание (сб)"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${member.circles || ''}</textarea>
      
      <label>💬 Примечания</label>
      <textarea id="editMemberNotes" rows="2"
        placeholder="Напр. Аллергия на орехи, любит рисовать"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${member.notes || ''}</textarea>
      
      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit"
          style="flex:1;padding:15px;background:linear-gradient(135deg,#3b82f6,#60a5fa);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(59,130,246,0.4);">
          💾 Сохранить изменения
        </button>
        <button type="button" onclick="Modal.close()"
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;
  
  Modal.form({ title: '✏️ Редактировать члена семьи', content });
};

// Сохранить изменения члена семьи
window.saveFamilyMemberEdit = function(e, id) {
  e.preventDefault();
  console.log('💾 saveFamilyMemberEdit:', id);
  
  const members = Store.getFamilyMembers();
  const index = members.findIndex(m => m.id === id);
  
  if (index === -1) {
    Modal.alert('❌ Член семьи не найден!');
    return false;
  }
  
  members[index] = {
    ...members[index],
    name: document.getElementById('editMemberName').value,
    role: document.getElementById('editMemberRole').value,
    school: document.getElementById('editMemberSchool').value,
    place: document.getElementById('editMemberSchool').value,
    age: parseInt(document.getElementById('editMemberAge').value) || null,
    circles: document.getElementById('editMemberCircles').value,
    notes: document.getElementById('editMemberNotes').value,
    updatedAt: new Date().toISOString()
  };
  
  Storage.set('familyMembers', JSON.stringify(members));
  Modal.close();
  Modal.alert('✅ Изменения сохранены!');
  
  setTimeout(() => {
    if (typeof FamilyView !== 'undefined') FamilyView.render();
    if (typeof showFamilyMembers === 'function') showFamilyMembers();
  }, 200);
  
  return false;
};

// Улучшенный рендеринг карточки члена семьи с кнопкой редактирования
window.renderFamilyMemberCard = function(member) {
  const roleEmojis = {
    'Сын': '👦',
    'Дочь': '👧',
    'Муж': '👨',
    'Жена': '👩',
    'Другое': '👤'
  };
  const emoji = roleEmojis[member.role] || '👤';
  
  return `
    <div class="family-member-card" style="background:white;border-radius:16px;padding:15px;margin:10px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1);border-left:4px solid #3b82f6;">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;">
        <div style="display:flex;align-items:center;gap:10px;">
          <span style="font-size:32px;">${emoji}</span>
          <div>
            <div style="font-weight:700;font-size:18px;color:#1e293b;">${member.name || 'Без имени'}</div>
            <div style="font-size:13px;color:#64748b;">${member.role || 'Член семьи'}${member.age ? ' · ' + member.age + ' лет' : ''}</div>
          </div>
        </div>
        <div style="display:flex;gap:5px;">
          <button onclick="editFamilyMember(${member.id})" 
            style="background:#3b82f6;color:white;border:none;border-radius:8px;padding:8px 12px;font-size:13px;cursor:pointer;font-weight:600;">
            ✏️
          </button>
          <button onclick="deleteFamilyMember(${member.id})" 
            style="background:#ef4444;color:white;border:none;border-radius:8px;padding:8px 12px;font-size:13px;cursor:pointer;font-weight:600;">
            🗑️
          </button>
        </div>
      </div>
      ${member.school ? `<div style="font-size:14px;color:#334155;margin:5px 0;">🏫 ${member.school}</div>` : ''}
      ${member.circles ? `<div style="font-size:14px;color:#334155;margin:5px 0;"> ${member.circles}</div>` : ''}
      ${member.notes ? `<div style="font-size:13px;color:#64748b;margin-top:8px;font-style:italic;">💬 ${member.notes}</div>` : ''}
    </div>
  `;
};

console.log('✅ Функции редактирования семьи загружены');

// Удаление члена семьи
window.deleteFamilyMember = function(id) {
  Modal.confirm('Удалить этого члена семьи?', () => {
    const members = Store.getFamilyMembers();
    const filtered = members.filter(m => m.id !== id);
    Storage.set('familyMembers', JSON.stringify(filtered));
    Modal.close();
    Modal.alert('✅ Член семьи удалён!');
    setTimeout(() => {
      if (typeof FamilyView !== 'undefined') FamilyView.render();
      if (typeof showFamilyMembers === 'function') showFamilyMembers();
    }, 200);
  });
};

// === ФОРМА ПОВТОРЯЮЩЕГОСЯ СОБЫТИЯ ===

window.openRecurringForm = function() {
  const repeatOptions = Object.entries(RecurringService.repeatTypes).map(([key, val]) => 
    `<option value="${val.value}">${val.label}</option>`
  ).join('');

  const content = `
    <form id="recurringForm" onsubmit="return saveRecurringEvent(event)">
      <label>Название события *</label>
      <input type="text" id="recurringName" placeholder="Напр. Школа, Кружок Танцы" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Категория</label>
      <select id="recurringCategory"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        <option value="family">👨‍👩‍👧 Семья</option>
        <option value="work">💼 Работа</option>
        <option value="dog">🐕 Собака</option>
      </select>

      <label>Тип услуги / события</label>
      <input type="text" id="recurringService" placeholder="Напр. Школа №5, Танцы"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Время *</label>
      <input type="time" id="recurringTime" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Длительность (минут) *</label>
      <input type="number" id="recurringDuration" value="60" min="10" max="480" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Тип повторения *</label>
      <select id="recurringType" required onchange="toggleDaysOfWeek()"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        ${repeatOptions}
      </select>

      <div id="daysOfWeekSelector" style="display:none;margin-bottom:15px;">
        <label>Дни недели:</label>
        <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-top:5px;">
          ${['Вс','Пн','Вт','Ср','Чт','Пт','Сб'].map((day, idx) => `
            <label style="display:flex;flex-direction:column;align-items:center;padding:8px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
              <input type="checkbox" class="day-checkbox" value="${idx}" style="margin-bottom:5px;">
              <span style="font-size:12px;">${day}</span>
            </label>
          `).join('')}
        </div>
      </div>

      <label>Дата начала *</label>
      <input type="date" id="recurringStartDate" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Дата окончания *</label>
      <input type="date" id="recurringEndDate" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>💰 Стоимость (за одно событие)</label>
      <input type="number" id="recurringPrice" placeholder="Напр. 1500" min="0"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>💬 Примечания</label>
      <textarea id="recurringNotes" placeholder="Напр. С собой форма, пропуск" rows="2"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;"></textarea>

      <div style="background:#e0f2fe;padding:12px;border-radius:10px;margin:15px 0;font-size:14px;">
        💡 <b>Совет:</b> Система автоматически создаст события до указанной даты.
        Можно исключить праздники и каникулы вручную.
      </div>

      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit"
          style="flex:1;padding:15px;background:linear-gradient(135deg,#8b5cf6,#a78bfa);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(139,92,246,0.4);">
          📅 Создать повторяющееся событие
        </button>
        <button type="button" onclick="Modal.close()"
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;

  Modal.form({ title: '📅 Повторяющееся событие', content });

  // Установить сегодняшнюю дату
  setTimeout(() => {
    document.getElementById('recurringStartDate').value = new Date().toISOString().split('T')[0];
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);
    document.getElementById('recurringEndDate').value = nextMonth.toISOString().split('T')[0];
  }, 100);
};

// Переключение селектора дней недели
window.toggleDaysOfWeek = function() {
  const type = document.getElementById('recurringType').value;
  const selector = document.getElementById('daysOfWeekSelector');
  if (selector) {
    selector.style.display = type === 'weekly' ? 'block' : 'none';
  }
};

// Сохранение повторяющегося события
window.saveRecurringEvent = function(e) {
  e.preventDefault();

  const daysOfWeek = Array.from(document.querySelectorAll('.day-checkbox:checked')).map(cb => parseInt(cb.value));

  const data = {
    name: document.getElementById('recurringName').value,
    category: document.getElementById('recurringCategory').value,
    service: document.getElementById('recurringService').value,
    time: document.getElementById('recurringTime').value,
    duration: parseInt(document.getElementById('recurringDuration').value),
    repeatType: document.getElementById('recurringType').value,
    daysOfWeek: daysOfWeek,
    startDate: document.getElementById('recurringStartDate').value,
    endDate: document.getElementById('recurringEndDate').value,
    price: parseInt(document.getElementById('recurringPrice').value || 0),
    notes: document.getElementById('recurringNotes').value
  };

  RecurringService.create(data);
  Modal.close();
  Modal.alert('✅ Повторяющееся событие создано!\n\nСобытия автоматически добавлены в календарь.');
  setTimeout(() => {
    if (typeof CalendarView !== 'undefined') CalendarView.render();
    if (typeof WorkView !== 'undefined') WorkView.render();
    if (typeof FamilyView !== 'undefined') FamilyView.render();
  }, 200);

  return false;
};

console.log('✅ Функции повторяющихся событий загружены');

// === ВЕЧЕРНИЙ ОТЧЁТ И ПЛАН НА ЗАВТРА ===

// Получить статистику дня
window.getDailyStats = function(date = null) {
  if (!date) {
    date = new Date().toISOString().split('T')[0];
  }
  
  const entries = Store.getEntries().filter(e => e.date === date);
  const workEntries = entries.filter(e => e.category === 'work');
  const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
  
  const completed = workEntries.filter(e => e.status === 'done');
  const cancelled = workEntries.filter(e => e.status === 'cancelled');
  const pending = workEntries.filter(e => e.status === 'new' || e.status === 'confirmed');
  
  const totalIncome = completed.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  const plannedIncome = workEntries.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  
  return {
    date,
    total: entries.length,
    work: workEntries.length,
    family: familyEntries.length,
    completed: completed.length,
    cancelled: cancelled.length,
    pending: pending.length,
    totalIncome,
    plannedIncome,
    entries: workEntries.sort((a, b) => a.time.localeCompare(b.time))
  };
};

// Получить план на завтра
window.getTomorrowPlan = function() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];
  
  const entries = Store.getEntries()
    .filter(e => e.date === tomorrowStr)
    .sort((a, b) => a.time.localeCompare(b.time));
  
  const workEntries = entries.filter(e => e.category === 'work');
  const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
  
  const totalWorkTime = workEntries.reduce((sum, e) => sum + e.duration, 0);
  const totalIncome = workEntries.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
  
  // Проверяем, не перегружен ли день
  const isOverloaded = workEntries.length > 6 || totalWorkTime > 480;
  
  return {
    date: tomorrowStr,
    entries,
    workCount: workEntries.length,
    familyCount: familyEntries.length,
    totalWorkTime,
    totalIncome,
    isOverloaded,
    entries
  };
};

// Показать вечерний отчёт
window.showEveningReport = function() {
  const today = getDailyStats();
  const tomorrow = getTomorrowPlan();
  
  const tomorrowDate = new Date(tomorrow.date).toLocaleDateString('ru-RU', { 
    weekday: 'long', 
    day: 'numeric', 
    month: 'long' 
  });
  
  let html = `
    <div style="padding:10px;">
      <h2 style="text-align:center;margin-bottom:20px;color:#1e293b;"> Итоги дня</h2>
      
      <!-- СЕГОДНЯ -->
      <div style="background:linear-gradient(135deg,#10b981,#34d399);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(16,185,129,0.3);">
        <h3 style="margin:0 0 15px 0;font-size:20px;">✨ Сегодня</h3>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:15px;">
          <div style="background:rgba(255,255,255,0.2);padding:10px;border-radius:10px;text-align:center;">
            <div style="font-size:28px;font-weight:700;">${today.completed}</div>
            <div style="font-size:13px;opacity:0.9;">Выполнено</div>
          </div>
          <div style="background:rgba(255,255,255,0.2);padding:10px;border-radius:10px;text-align:center;">
            <div style="font-size:28px;font-weight:700;">${today.pending}</div>
            <div style="font-size:13px;opacity:0.9;">Запланировано</div>
          </div>
        </div>
        <div style="background:rgba(255,255,255,0.2);padding:15px;border-radius:10px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>💰 Заработано:</span>
            <b>${today.totalIncome}₽</b>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span> Всего записей:</span>
            <b>${today.work}</b>
          </div>
          ${today.cancelled > 0 ? `
          <div style="display:flex;justify-content:space-between;">
            <span>❌ Отменено:</span>
            <b>${today.cancelled}</b>
          </div>
          ` : ''}
        </div>
      </div>
      
      <!-- ЗАВТРА -->
      <div style="background:linear-gradient(135deg,#3b82f6,#60a5fa);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(59,130,246,0.3);">
        <h3 style="margin:0 0 15px 0;font-size:20px;"> Завтра (${tomorrowDate})</h3>
        ${tomorrow.isOverloaded ? `
        <div style="background:rgba(239,68,68,0.9);padding:10px;border-radius:10px;margin-bottom:10px;text-align:center;">
          ⚠️ <b>Плотный день!</b> ${tomorrow.workCount} записей
        </div>
        ` : ''}
        <div style="background:rgba(255,255,255,0.2);padding:15px;border-radius:10px;margin-bottom:10px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>💼 Записей:</span>
            <b>${tomorrow.workCount}</b>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span>👨‍👩👧 Семейных дел:</span>
            <b>${tomorrow.familyCount}</b>
          </div>
          <div style="display:flex;justify-content:space-between;">
            <span>💰 Планируется:</span>
            <b>${tomorrow.totalIncome}₽</b>
          </div>
        </div>
        ${tomorrow.entries.length > 0 ? `
        <div style="font-size:14px;">
          <b>Расписание:</b>
          <div style="margin-top:8px;max-height:150px;overflow-y:auto;">
            ${tomorrow.entries.map(e => `
              <div style="background:rgba(255,255,255,0.1);padding:8px;margin:5px 0;border-radius:6px;">
                ${e.time} - ${e.name} (${e.duration} мин)
              </div>
            `).join('')}
          </div>
        </div>
        ` : '<div style="text-align:center;padding:10px;opacity:0.9;">🎉 Завтра выходной!</div>'}
      </div>
      
      <button onclick="Modal.close()" 
        style="width:100%;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
        Закрыть
      </button>
    </div>
  `;
  
  Modal.form({ title: '📊 Вечерний отчёт', content: html });
};

// Автоматическая проверка времени (вызывать периодически)
window.checkEveningTime = function() {
  const now = new Date();
  const hours = now.getHours();
  const minutes = now.getMinutes();
  
  // Показываем отчёт в 20:00-22:00 если ещё не показали сегодня
  if (hours >= 20 && hours < 22) {
    const lastShown = Storage.get('eveningReportShown', '');
    const today = new Date().toISOString().split('T')[0];
    
    if (lastShown !== today) {
      // Проверяем, были ли сегодня записи
      const stats = getDailyStats();
      if (stats.work > 0) {
        setTimeout(() => {
          showEveningReport();
          Storage.set('eveningReportShown', today);
        }, 1000);
      }
    }
  }
};

// Запускаем проверку каждую минуту
setInterval(checkEveningTime, 60000);

// Проверяем сразу при загрузке
setTimeout(checkEveningTime, 2000);

console.log('✅ Вечерний отчёт загружен');

// === СТАТИСТИКА ЗАГРУЗКИ НЕДЕЛИ ===

// Получить статистику загрузки недели
window.getWeeklyLoadStats = function() {
  const today = new Date();
  const currentDay = today.getDay();
  
  // Начало недели (понедельник)
  const monday = new Date(today);
  monday.setDate(today.getDate() - (currentDay === 0 ? 6 : currentDay - 1));
  monday.setHours(0, 0, 0, 0);
  
  // Конец недели (воскресенье)
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  sunday.setHours(23, 59, 59, 999);
  
  const days = [];
  const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday);
    date.setDate(monday.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];
    
    const entries = Store.getEntries()
      .filter(e => e.date === dateStr && e.category === 'work');
    
    const completed = entries.filter(e => e.status === 'done');
    const totalDuration = entries.reduce((sum, e) => sum + e.duration, 0);
    const income = completed.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);
    
    // Считаем слоты (предполагаем 8-часовой рабочий день = 8 слотов по 1 часу)
    const maxSlots = 8;
    const usedSlots = Math.ceil(totalDuration / 60);
    const loadPercent = Math.min(Math.round((usedSlots / maxSlots) * 100), 100);
    
    days.push({
      date: dateStr,
      dayName: dayNames[i],
      dayNumber: date.getDate(),
      entries: entries.length,
      completed: completed.length,
      totalDuration,
      income,
      usedSlots,
      maxSlots,
      loadPercent,
      isToday: dateStr === today.toISOString().split('T')[0]
    });
  }
  
  // Общая статистика
  const totalIncome = days.reduce((sum, d) => sum + d.income, 0);
  const totalEntries = days.reduce((sum, d) => sum + d.entries, 0);
  const totalCompleted = days.reduce((sum, d) => sum + d.completed, 0);
  const avgLoad = Math.round(days.reduce((sum, d) => sum + d.loadPercent, 0) / 7);
  
  // Найти самый загруженный и свободный день
  const busiestDay = days.reduce((max, d) => d.loadPercent > max.loadPercent ? d : max, days[0]);
  const freestDay = days.reduce((min, d) => d.loadPercent < min.loadPercent ? d : min, days[0]);
  
  return {
    days,
    totalIncome,
    totalEntries,
    totalCompleted,
    avgLoad,
    busiestDay,
    freestDay
  };
};

// Показать статистику недели
window.showWeeklyStats = function() {
  const stats = getWeeklyLoadStats();
  
  // Определяем цвета для нагрузки
  const getLoadColor = (percent) => {
    if (percent >= 80) return '#ef4444'; // красный
    if (percent >= 60) return '#f59e0b'; // оранжевый
    if (percent >= 40) return '#10b981'; // зелёный
    return '#3b82f6'; // синий
  };
  
  const getLoadBars = (percent) => {
    const filled = Math.ceil(percent / 10);
    const empty = 10 - filled;
    return '█'.repeat(filled) + '░'.repeat(empty);
  };
  
  let html = `
    <div style="padding:10px;">
      <h2 style="text-align:center;margin-bottom:20px;color:#1e293b;">📊 Загрузка недели</h2>
      
      <!-- Общая статистика -->
      <div style="background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:20px;border-radius:16px;margin-bottom:20px;box-shadow:0 4px 12px rgba(102,126,234,0.3);">
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;text-align:center;">
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalEntries}</div>
            <div style="font-size:13px;opacity:0.9;">Записей</div>
          </div>
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalCompleted}</div>
            <div style="font-size:13px;opacity:0.9;">Выполнено</div>
          </div>
          <div>
            <div style="font-size:28px;font-weight:700;">${stats.totalIncome}₽</div>
            <div style="font-size:13px;opacity:0.9;">Доход</div>
          </div>
        </div>
      </div>
      
      <!-- Дни недели -->
      <div style="margin-bottom:20px;">
        ${stats.days.map(day => `
          <div style="background:white;border-radius:12px;padding:12px;margin:8px 0;box-shadow:0 2px 8px rgba(0,0,0,0.1);${day.isToday ? 'border:2px solid #667eea;' : ''}">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
              <div style="display:flex;align-items:center;gap:10px;">
                <b style="font-size:16px;color:#1e293b;">${day.dayName}, ${day.dayNumber}</b>
                ${day.isToday ? '<span style="background:#667eea;color:white;padding:2px 8px;border-radius:6px;font-size:12px;">Сегодня</span>' : ''}
              </div>
              <div style="color:#64748b;font-size:14px;">${day.entries} записей</div>
            </div>
            <div style="font-family:monospace;font-size:14px;margin:5px 0;color:${getLoadColor(day.loadPercent)};">
              ${getLoadBars(day.loadPercent)} ${day.loadPercent}%
            </div>
            <div style="display:flex;justify-content:space-between;font-size:13px;color:#64748b;margin-top:5px;">
              <span>⏱️ ${Math.round(day.totalDuration / 60)}ч ${day.totalDuration % 60}мин</span>
              <span>💰 ${day.income}₽</span>
            </div>
          </div>
        `).join('')}
      </div>
      
      <!-- Рекомендации -->
      <div style="background:#fef3c7;border-left:4px solid #f59e0b;padding:15px;border-radius:10px;margin-bottom:20px;">
        <b style="color:#92400e;">💡 Рекомендации:</b>
        <ul style="margin:8px 0 0 20px;color:#92400e;font-size:14px;">
          ${stats.busiestDay.loadPercent > 80 ? `<li>️ ${stats.busiestDay.dayName} перегружен (${stats.busiestDay.loadPercent}%) — попробуй перенести часть записей</li>` : ''}
          ${stats.freestDay.loadPercent < 30 && stats.freestDay.dayName !== 'Вс' ? `<li>✅ ${stats.freestDay.dayName} свободен (${stats.freestDay.loadPercent}%) — можно добавить записи</li>` : ''}
          ${stats.avgLoad > 70 ? `<li>🔥 Высокая средняя загрузка (${stats.avgLoad}%) — следи за выгоранием!</li>` : ''}
          ${stats.avgLoad < 40 ? `<li>📈 Низкая загрузка (${stats.avgLoad}%) — время для рекламы!</li>` : ''}
        </ul>
      </div>
      
      <button onclick="Modal.close()" 
        style="width:100%;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
        Закрыть
      </button>
    </div>
  `;
  
  Modal.form({ title: '📈 Статистика недели', content: html });
};

console.log('✅ Статистика недели загружена');
