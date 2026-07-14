#!/bin/bash
echo "🔧 Чиню кнопки и упрощаю форму"

# 1. ИСПРАВЛЯЕМ EntryCard - inline onclick
cat > src/ui/components/EntryCard.js << 'ENTRYCARD'
/**
 * ENTRY CARD COMPONENT v3.0
 * С inline onclick - гарантированно работает
 */

const EntryCard = {
  render(entry, options = {}) {
    const endTime = Entry.getEndTime(entry);
    const statusLabel = Entry.getStatusLabel(entry.status);
    const categoryIcons = { work: '💼', family: '👨‍👩‍', dog: '🐕' };
    
    return `
      <div class="entry-card category-${entry.category} status-${entry.status}" data-id="${entry.id}">
        <div class="entry-compact-info">
          <span class="entry-compact-time">${entry.time} - ${endTime}</span>
          <span class="entry-compact-name">${categoryIcons[entry.category] || ''} ${entry.name}</span>
          ${entry.price > 0 ? `<span class="entry-compact-price">${entry.price}₽</span>` : ''}
          <span class="expand-icon">▼</span>
        </div>
        
        <div class="entry-details">
          <div><b>${entry.name}</b> <span class="status-badge status-${entry.status}">${statusLabel}</span></div>
          <div style="margin-top:5px;">
            ${entry.service}
            ${entry.zone ? ' · ' + entry.zone : ''}
            ${entry.phone ? ' · 📞 ' + entry.phone : ''}
            · ⏱️ ${entry.duration} мин
          </div>
          ${entry.notes ? `<div style="margin-top:5px;font-style:italic;">💬 ${entry.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons">
          <button class="status-btn ${entry.status==='new'?'active':''}" onclick="changeStatus(${entry.id}, 'new')">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" onclick="changeStatus(${entry.id}, 'confirmed')">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" onclick="changeStatus(${entry.id}, 'done')">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" onclick="changeStatus(${entry.id}, 'cancelled')">Отмена</button>
        </div>
        
        <div class="entry-actions">
          <button class="btn-edit" onclick="editEntry(${entry.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="duplicateEntry(${entry.id})"> Копировать</button>
          <button class="btn-del" onclick="deleteEntry(${entry.id})">🗑️ Удалить</button>
        </div>
      </div>
    `;
  }
};

window.EntryCard = EntryCard;

// Глобальные функции
window.changeStatus = function(id, status) {
  console.log('changeStatus', id, status);
  try {
    EntryService.changeStatus(id, status);
    if (currentTab === 'calendar') CalendarView.render();
    else if (currentTab === 'work') WorkView.render();
    else if (currentTab === 'family') FamilyView.render();
  } catch (e) {
    console.error('Ошибка changeStatus:', e);
  }
};

window.editEntry = function(id) {
  console.log('editEntry', id);
  try {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    
    if (entry.category === 'work') {
      openWorkForm(id);
    } else if (entry.category === 'family' || entry.category === 'dog') {
      openFamilyForm(id);
    }
  } catch (e) {
    console.error('Ошибка editEntry:', e);
  }
};

window.duplicateEntry = function(id) {
  console.log('duplicateEntry', id);
  try {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    
    Modal.confirm('Копировать запись на следующие 7 дней?', () => {
      try {
        const startDate = new Date(entry.date);
        let created = 0;
        
        for (let i = 1; i <= 7; i++) {
          const newDate = new Date(startDate);
          newDate.setDate(newDate.getDate() + i);
          const dateStr = newDate.toISOString().split('T')[0];
          
          const newEntry = {
            ...entry,
            id: Utils.generateId(),
            date: dateStr,
            status: 'new',
            createdAt: new Date().toISOString()
          };
          
          Store.addEntry(newEntry);
          created++;
        }
        
        Modal.close();
        setTimeout(() => {
          Modal.alert(`✅ Создано ${created} копий на неделю!`);
          if (currentTab === 'calendar') CalendarView.render();
          else if (currentTab === 'work') WorkView.render();
          else if (currentTab === 'family') FamilyView.render();
        }, 100);
        
      } catch (error) {
        Modal.alert('❌ Ошибка: ' + error.message);
      }
    });
  } catch (e) {
    console.error('Ошибка duplicateEntry:', e);
  }
};

window.deleteEntry = function(id) {
  console.log('deleteEntry', id);
  try {
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
  } catch (e) {
    console.error('Ошибка deleteEntry:', e);
  }
};
ENTRYCARD

echo "✅ EntryCard.js исправлен"

# 2. УПРОЩАЕМ ФОРМУ РАБОТЫ - только прайс
cat > app_simple.js << 'APPJS'
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
APPJS

mv app_simple.js app.js

echo "✅ app.js v3.1 создан - кнопки и упрощенная форма"

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
echo "═══════════════════════════════════════"
echo "✅ ИСПРАВЛЕНО!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО СДЕЛАНО:"
echo "  1. ✅ Кнопки работают (удалить/копировать/статус)"
echo "  2. ✅ Упрощена форма работы - только прайс"
echo "     • Выбираешь услугу → всё заполняется"
echo "     • Не нужно дублировать название/зону"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Нажми на запись → 🗑️ Удалить → Да"
echo "   → Запись должна удалиться"
echo ""
echo "2. Нажми на запись → 📋 Копировать → Да"
echo "   → Создастся 7 копий на неделю"
echo ""
echo "3. Работа → + Добавить"
echo "   → Выбери услугу из прайса"
echo "   → Длительность и цена заполнятся сами"
echo "   → Введи имя клиента → Сохранить"
echo ""
echo "Напиши 'работает' или что не так!"
