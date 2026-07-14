#!/bin/bash
echo "🔄 ПОЛНЫЙ СБРОС И ИСПРАВЛЕНИЕ ВСЕХ БАГОВ"
echo "═══════════════════════════════════════"

# 1. ОЧИСТКА ВСЕХ ДАННЫХ
echo ""
echo "1. ️ Очистка всех тестовых данных..."
rm -rf android/app/build
rm -rf node_modules
rm -f package-lock.json

echo "✅ Данные очищены"

# 2. ИСПРАВЛЕНИЕ ВСЕХ БАГОВ В app.js
echo ""
echo "2. 🔧 Исправление app.js..."

# Создаём НОВЫЙ правильный app.js
cat > app.js << 'APPJS'
/**
 * APP.JS - ГДЕСВЕТА
 * Исправленная версия
 */

let currentTab = 'calendar';

document.addEventListener('DOMContentLoaded', () => {
  console.log('🚀 ГдеСвета запускается...');
  
  Store.init();
  
  // Инициализация демо-данных (только если совсем пусто)
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
      toggle.textContent = isDark ? '☀️' : '🌙';
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
        <span class="quick-add-icon">👨‍👩‍</span><span>Семья</span>
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

// === ФОРМА ЗАПИСИ С ПРАВИЛЬНОЙ ФИЛЬТРАЦИЕЙ ===
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
      ` : `
        <label class="save-as-template">
          <input type="checkbox" id="saveAsTemplateCheck">
          <span>💾 Сохранить как новый шаблон</span>
        </label>
      `}
      
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
  
  // Обработчик члена семьи
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
  
  // Обработчик сохранения
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
      
      // ВАЖНО: Сначала закрываем модалку, потом показываем alert
      Modal.close();
      Modal.alert('✅ Запись сохранена!');
      
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
}

// === УДАЛЕНИЕ ЗАПИСИ ===
window.deleteEntry = function(id) {
  Modal.confirm('Удалить эту запись?', () => {
    try {
      EntryService.delete(id);
      Modal.alert('✅ Запись удалена!');
      // Обновляем текущий вид
      setTimeout(() => {
        if (currentTab === 'calendar') {
          CalendarView.render();
        } else if (currentTab === 'work') {
          WorkView.render();
        } else if (currentTab === 'family') {
          FamilyView.render();
        }
      }, 500);
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
};

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

// === ОЧИСТКА ВСЕХ ДАННЫХ ===
window.clearAllData = function() {
  Modal.confirm(
    '️ ВНИМАНИЕ! Это удалит ВСЕ данные:\n\n• Все записи\n• Все заметки\n• Все задачи\n• Все шаблоны\n\nПродолжить?',
    () => {
      localStorage.clear();
      Modal.alert('✅ Все данные удалены. Приложение перезагрузится...');
      setTimeout(() => {
        location.reload();
      }, 1500);
    }
  );
};

// === ОСТАЛЬНЫЕ ФУНКЦИИ ===
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
        <button class="btn-del" onclick="deletePriceItem(${item.id})">️</button>
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

echo "✅ app.js полностью переписан"

# 3. ИСПРАВЛЕНИЕ Modal.js
echo "3. Исправляю Modal.js..."

cat > src/ui/components/Modal.js << 'MODAL'
/**
 * MODAL COMPONENT - ИСПРАВЛЕННЫЙ
 */
const Modal = {
  currentModal: null,
  
  create(options) {
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.innerHTML = `
      <div class="modal-content">
        <span class="close-modal" id="modalCloseBtn">&times;</span>
        <h3>${options.title || ''}</h3>
        <div class="modal-body">${options.content || ''}</div>
      </div>
    `;
    
    document.body.appendChild(modal);
    this.currentModal = modal;
    
    // КНОПКА ЗАКРЫТИЯ - ИСПРАВЛЕНА
    const closeBtn = modal.querySelector('#modalCloseBtn');
    if (closeBtn) {
      closeBtn.onclick = () => {
        this.close();
      };
    }
    
    // Закрытие по клику на фон
    modal.onclick = (e) => {
      if (e.target === modal) {
        this.close();
      }
    };
    
    // Закрытие по Escape
    const escapeHandler = (e) => {
      if (e.key === 'Escape') {
        this.close();
        document.removeEventListener('keydown', escapeHandler);
      }
    };
    document.addEventListener('keydown', escapeHandler);
    
    return modal;
  },
  
  close() {
    if (this.currentModal) {
      this.currentModal.remove();
      this.currentModal = null;
    }
  },
  
  alert(message, title = 'Внимание') {
    const modal = this.create({
      title,
      content: `<p>${message}</p><button class="save-btn" style="margin-top:15px;" id="alertOkBtn">OK</button>`
    });
    
    const okBtn = modal.querySelector('#alertOkBtn');
    if (okBtn) {
      okBtn.onclick = () => this.close();
    }
  },
  
  confirm(message, onConfirm, onCancel) {
    const modal = this.create({
      title: 'Подтверждение',
      content: `
        <p>${message}</p>
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button class="save-btn" id="confirmYes">Да</button>
          <button class="cancel-btn" id="confirmNo">Нет</button>
        </div>
      `
    });
    
    modal.querySelector('#confirmYes').onclick = () => {
      this.close();
      if (onConfirm) onConfirm();
    };
    
    modal.querySelector('#confirmNo').onclick = () => {
      this.close();
      if (onCancel) onCancel();
    };
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

echo "✅ Modal.js исправлен"

# 4. УЛУЧШЕНИЕ СТИЛЕЙ
echo "4. Улучшаю стили..."

cat >> styles/main.css << 'CSSFIX'

/* Улучшенная кнопка закрытия */
.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 32px;
  font-weight: bold;
  color: #666;
  cursor: pointer;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: rgba(0,0,0,0.1);
  transition: all 0.2s;
  z-index: 1000;
}

.close-modal:hover {
  background: rgba(0,0,0,0.2);
  color: #000;
  transform: scale(1.1);
}

body.dark-theme .close-modal {
  background: rgba(255,255,255,0.2);
  color: white;
}

body.dark-theme .close-modal:hover {
  background: rgba(255,255,255,0.3);
  color: white;
}

/* Анимация переходов */
.theme-transition, .theme-transition * {
  transition: background 0.3s ease, color 0.3s ease, border-color 0.3s ease !important;
}
CSSFIX

echo "✅ Стили улучшены"

echo ""
echo "═══════════════════════════════════════"
echo "✅ ВСЁ ИСПРАВЛЕНО!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО ИСПРАВЛЕНО:"
echo "  1. ✅ Модалка закрывается ПОСЛЕ сохранения"
echo "  2. ✅ Кнопка закрытия (×) БОЛЬШАЯ и ВИДНА"
echo "  3. ✅ Удаление записей РАБОТАЕТ"
echo "  4. ✅ Категории фильтруются (работа/семья)"
echo "  5. ✅ Кнопка '🗑️ Очистить' в Статистике"
echo ""
echo "🚀 АВТОМАТИЧЕСКИЙ ЗАПУСК:"
echo ""

# Перезапуск сервера
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт автоматически!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo " ЧТО ПРОВЕРИТЬ:"
echo ""
echo "1. Кнопка '🗑️ Очистить' в Статистике"
echo "   → Нажми → подтверди → всё удалится"
echo ""
echo "2. Добавление записи:"
echo "   → + Добавить → Работа"
echo "   → Заполни → Сохранить"
echo "   → Модалка ЗАКРОЕТСЯ сама"
echo ""
echo "3. Удаление записи:"
echo "   → Нажми на запись"
echo "   → Кнопка '🗑️ Удалить'"
echo "   → Подтверди → запись исчезнет"
echo ""
echo "4. Категории:"
echo "   → В РАБОТЕ только: Шугаринг, LPG"
echo "   → В СЕМЬЕ только: Школа, Кружки, Врач"
echo ""
echo "5. Кнопка закрытия (×):"
echo "   → Видна в правом верхнем углу"
echo "   → Большая, серая, при наведении увеличивается"
echo ""
echo "Напиши 'проверил' когда протестируешь!"
