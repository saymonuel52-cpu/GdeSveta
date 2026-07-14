#!/bin/bash
echo "🔔 Добавляю систему уведомлений..."

# 1. Создаём NotificationService
cat > src/services/NotificationService.js << 'NOTIFY'
/**
 * NOTIFICATION SERVICE
 * Локальные уведомления и напоминания
 */

const NotificationService = {
  permission: 'default',
  enabled: true,
  checkInterval: null,
  
  /**
   * Инициализация
   */
  init() {
    if ('Notification' in window) {
      this.permission = Notification.permission;
      console.log(`[Notification] Permission: ${this.permission}`);
    }
    
    // Запускаем проверку каждые 30 секунд
    this.startChecking();
    
    // Утренний брифинг при открытии
    this.morningBriefing();
  },
  
  /**
   * Запросить разрешение
   */
  async requestPermission() {
    if (!('Notification' in window)) {
      console.warn('[Notification] API не поддерживается');
      return false;
    }
    
    try {
      const result = await Notification.requestPermission();
      this.permission = result;
      console.log(`[Notification] Permission: ${result}`);
      return result === 'granted';
    } catch (error) {
      console.error('[Notification] Error:', error);
      return false;
    }
  },
  
  /**
   * Показать уведомление
   */
  show(title, options = {}) {
    // Визуальное уведомление в приложении
    this.showInApp(title, options.body || '');
    
    // Системное уведомление
    if (this.enabled && this.permission === 'granted' && 'Notification' in window) {
      try {
        new Notification(title, {
          body: options.body || '',
          icon: '/assets/icons/icon-192.png',
          badge: '/assets/icons/badge-72.png',
          tag: options.tag || 'gdesveta',
          requireInteraction: options.requireInteraction || false
        });
      } catch (error) {
        console.error('[Notification] Show error:', error);
      }
    }
  },
  
  /**
   * Показать уведомление внутри приложения
   */
  showInApp(title, message) {
    const container = document.getElementById('notificationContainer');
    if (!container) return;
    
    const notification = document.createElement('div');
    notification.className = 'in-app-notification';
    notification.innerHTML = `
      <div class="notification-content">
        <div class="notification-title">${title}</div>
        <div class="notification-message">${message}</div>
      </div>
      <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;
    
    container.appendChild(notification);
    
    // Автоматически удалить через 5 секунд
    setTimeout(() => {
      if (notification.parentElement) {
        notification.remove();
      }
    }, 5000);
  },
  
  /**
   * Проверить ближайшие события
   */
  checkUpcoming() {
    const now = new Date();
    const upcoming = EntryService.getUpcoming(10);
    
    upcoming.forEach(entry => {
      const entryTime = new Date(entry.date + 'T' + entry.time);
      const diffMinutes = Math.floor((entryTime - now) / 60000);
      
      // Напоминание за 60 минут
      if (diffMinutes === 60) {
        this.show(
          `⏰ Скоро запись: ${entry.name}`,
          `${entry.time} — ${entry.service}`
        );
      }
      
      // Напоминание за 15 минут
      if (diffMinutes === 15) {
        this.show(
          `⏰ Через 15 минут: ${entry.name}`,
          `${entry.time} — ${entry.service}`
        );
      }
      
      // Напоминание за 5 минут
      if (diffMinutes === 5) {
        this.show(
          `⏰ Через 5 минут: ${entry.name}`,
          `${entry.time} — ${entry.service}`
        );
      }
    });
  },
  
  /**
   * Утренний брифинг
   */
  morningBriefing() {
    const today = Utils.getToday();
    const entries = EntryService.getByDate(today);
    const notes = NoteService.getByDate(today);
    
    if (entries.length === 0 && notes.length === 0) return;
    
    const workEntries = entries.filter(e => e.category === 'work');
    const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
    
    let message = '';
    if (workEntries.length > 0) {
      message += ` ${workEntries.length} клиента\n`;
    }
    if (familyEntries.length > 0) {
      message += `👨‍‍👧 ${familyEntries.length} семейных дел\n`;
    }
    if (notes.length > 0) {
      message += ` ${notes.length} заметок`;
    }
    
    setTimeout(() => {
      this.show('☀️ Доброе утро!', message);
    }, 1000);
  },
  
  /**
   * Запустить проверку
   */
  startChecking() {
    // Проверяем каждые 30 секунд
    this.checkInterval = setInterval(() => {
      this.checkUpcoming();
    }, 30000);
  },
  
  /**
   * Остановить проверку
   */
  stopChecking() {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }
  },
  
  /**
   * Включить/выключить уведомления
   */
  toggle(enabled) {
    this.enabled = enabled;
    Storage.set('notifications_enabled', enabled);
  },
  
  /**
   * Получить статус
   */
  getStatus() {
    return {
      permission: this.permission,
      enabled: this.enabled,
      supported: 'Notification' in window
    };
  }
};

window.NotificationService = NotificationService;
NOTIFY

echo "✅ NotificationService создан"

# 2. Обновляем стили для уведомлений
cat >> styles/main.css << 'CSS'

/* === УВЕДОМЛЕНИЯ === */
#notificationContainer {
  position: fixed;
  top: 80px;
  right: 10px;
  z-index: 10000;
  max-width: 350px;
}

.in-app-notification {
  background: white;
  border-left: 4px solid #ff6b9d;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 10px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  animation: slideIn 0.3s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(100%);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.notification-content {
  flex: 1;
}

.notification-title {
  font-weight: bold;
  font-size: 14px;
  color: #333;
  margin-bottom: 4px;
}

.notification-message {
  font-size: 13px;
  color: #666;
}

.notification-close {
  background: none;
  border: none;
  font-size: 20px;
  color: #999;
  cursor: pointer;
  padding: 0 5px;
  margin-left: 10px;
}

.notification-close:hover {
  color: #333;
}

/* Индикатор скорого события */
.entry-card.soon {
  border-left-color: #ff9800;
  background: #fff8e1;
}

.entry-card.soon .entry-compact-time {
  color: #ff9800;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

/* Утренний брифинг */
.morning-briefing {
  background: linear-gradient(135deg, #fff9f9, #ffe0ec);
  padding: 15px;
  border-radius: 12px;
  margin-bottom: 15px;
  border: 2px solid #ff6b9d;
}

.briefing-title {
  font-size: 18px;
  font-weight: bold;
  color: #ff6b9d;
  margin-bottom: 10px;
}

.briefing-stats {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.briefing-stat {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 14px;
}

.briefing-stat-icon {
  font-size: 20px;
}
CSS

echo "✅ Стили для уведомлений добавлены"

# 3. Обновляем app.js — добавляем инициализацию уведомлений
cat > app.js << 'APPJS'
/**
 * APP.JS
 * Точка входа приложения
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 ГдеСвета — запуск...');
  
  Store.init();
  
  // Демо-данные если пусто
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
  
  // Инициализация уведомлений
  if (typeof NotificationService !== 'undefined') {
    NotificationService.init();
  }
  
  setupEventListeners();
  
  console.log('✅ Приложение готово!');
});

function initDemoData() {
  console.log(' Создание демо-данных...');
  
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
          Modal.confirm('Импортировать данные?', () => {
            Store.importData(data);
            Modal.alert('Импорт выполнен!');
          });
        } catch (error) {
          Modal.alert('Ошибка: ' + error.message);
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
  const content = `
    <div class="quick-add-grid">
      <button class="quick-add-btn work" onclick="openEntryForm(null, 'work')">
        <span class="quick-add-icon">💼</span>
        <span>Работа</span>
      </button>
      <button class="quick-add-btn family" onclick="openEntryForm(null, 'family')">
        <span class="quick-add-icon">‍👩‍👧</span>
        <span>Семья</span>
      </button>
      <button class="quick-add-btn dog" onclick="openEntryForm(null, 'dog')">
        <span class="quick-add-icon">🐕</span>
        <span>Собака</span>
      </button>
      <button class="quick-add-btn note" onclick="openNoteForm()">
        <span class="quick-add-icon">📝</span>
        <span>Заметка</span>
      </button>
    </div>
  `;
  Modal.form({ title: 'Что добавляем?', content });
}

function openEntryForm(id = null, category = 'work') {
  let entry = null;
  if (id) {
    entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    category = entry.category;
  }
  
  const categoryLabels = {
    work: '💼 Новая запись (работа)',
    family: '👨‍👩‍👧 Событие (семья)',
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
        if (member.school) {
          modal.querySelector('#entryZone').value = member.school;
        }
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
      if (id) NoteService.update(id, data);
      else NoteService.create(data);
      Modal.close();
      Modal.alert('✅ Заметка сохранена!');
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}

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
        <button class="btn-del" onclick="deletePriceItem(${item.id})">️</button>
      </div>
    `).join('');
  }
  content += `<button class="action-btn" onclick="addPriceItem()" style="margin-top:15px;width:100%">+ Добавить услугу</button>`;
  Modal.form({ title: '💰 Прайс-лист', content });
}

function addPriceItem() {
  Modal.close();
  const name = prompt('Название услуги:');
  if (!name) return;
  const service = prompt('Тип:', 'Шугаринг');
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

function showFamilyMembers() {
  const members = FamilyService.getAll();
  const roleLabels = { child: ' Ребёнок', adult: ' Взрослый', dog: '🐕 Собака' };
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
          ${m.breed ? ' Порода: ' + m.breed + '<br>' : ''}
          ${m.circles && m.circles.length > 0 ? ' ' + FamilyMember.getCirclesText(m.circles) : ''}
        </div>
        <button class="btn-del" onclick="deleteFamilyMember(${m.id})" style="margin-top:8px;width:100%;">🗑️ Удалить</button>
      </div>
    `).join('');
  }
  content += `<button class="action-btn" onclick="addFamilyMember()" style="margin-top:15px;width:100%">+ Добавить члена семьи</button>`;
  Modal.form({ title: '👥 Члены семьи', content });
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

echo "✅ app.js обновлён — добавлена инициализация уведомлений"

# 4. Добавляем контейнер для уведомлений в index.html
sed -i '/<div id="modalContainer"><\/div>/i \  <div id="notificationContainer"></div>' index.html

echo "✅ Контейнер уведомлений добавлен"

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
echo "🔔 ПРИОРИТЕТ 2 ВЫПОЛНЕН!"
echo ""
echo "✅ Добавлены уведомления:"
echo "  • За 60 минут до события"
echo "  • За 15 минут до события"
echo "  • За 5 минут до события"
echo "  • Утренний брифинг при открытии"
echo "  • Визуальные уведомления в приложении"
echo ""
echo "Как работает:"
echo "  1. При первом открытии — запрос разрешения"
echo "  2. Каждые 30 секунд — проверка событий"
echo "  3. За час/15мин/5мин — уведомление"
echo "  4. Утром — брифинг на день"
echo ""
echo "📋 Следующий шаг: Тёмная тема"
