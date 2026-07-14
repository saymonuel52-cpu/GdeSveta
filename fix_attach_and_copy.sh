#!/bin/bash
echo "🔧 Исправляю attachEvents и копирование"

# 1. ИЩЕМ где вызывается attachEvents
echo "1. 🔍 Ищу вызовы attachEvents..."
grep -rn "attachEvents" src/views/ 2>/dev/null || echo "Не найдено в views"
grep -rn "attachEvents" app.js 2>/dev/null || echo "Не найдено в app.js"

# 2. ИСПРАВЛЯЕМ CalendarView.js — убираем attachEvents
echo "2.  Исправляю CalendarView.js..."

cat > src/views/CalendarView.js << 'CALENDARVIEW'
/**
 * CALENDAR VIEW v2.0
 * Без attachEvents — используем inline onclick из EntryCard
 */

const CalendarView = {
  container: null,
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const selectedDate = Calendar.getSelectedDate();
    const entries = EntryService.getByDate(selectedDate);
    const notes = NoteService.getByDate(selectedDate);
    
    let html = `
      <div id="calendarContainer"></div>
      <div class="legend">
        <span class="legend-item"><span class="legend-color work"></span>Работа</span>
        <span class="legend-item"><span class="legend-color family"></span>Семья</span>
        <span class="legend-item"><span class="legend-color note"></span>Заметки</span>
      </div>
      <h3 style="margin:15px 0 10px;">${Utils.formatDate(selectedDate, 'long')}</h3>
    `;
    
    // Заметки
    notes.forEach(note => {
      html += NoteCard.render(note);
    });
    
    // Записи
    if (entries.length === 0 && notes.length === 0) {
      html += '<div class="empty-state">Нет записей на этот день</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    // Инициализируем календарь
    Calendar.init('calendarContainer');
    
    // attachEvents НЕ НУЖЕН — всё через inline onclick
  },
  
  setupListeners() {
    Events.on('date:selected', () => this.render());
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.CalendarView = CalendarView;
CALENDARVIEW

echo "✅ CalendarView.js исправлен"

# 3. ИСПРАВЛЯЕМ WorkView.js
echo "3. 🔧 Исправляю WorkView.js..."

cat > src/views/WorkView.js << 'WORKVIEW'
/**
 * WORK VIEW v2.0
 */

const WorkView = {
  container: null,
  filter: 'all',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    let entries = EntryService.getByCategory('work');
    
    const today = Utils.getToday();
    const weekLater = new Date();
    weekLater.setDate(weekLater.getDate() + 7);
    const weekLaterStr = weekLater.toISOString().split('T')[0];
    
    if (this.filter === 'today') {
      entries = entries.filter(e => e.date === today);
    } else if (this.filter === 'week') {
      entries = entries.filter(e => e.date >= today && e.date <= weekLaterStr);
    }
    
    entries.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    let html = `
      <div class="filter-bar">
        <select id="workFilter">
          <option value="all" ${this.filter === 'all' ? 'selected' : ''}>Все</option>
          <option value="today" ${this.filter === 'today' ? 'selected' : ''}>Сегодня</option>
          <option value="week" ${this.filter === 'week' ? 'selected' : ''}>Неделя</option>
        </select>
      </div>
    `;
    
    if (entries.length === 0) {
      html += '<div class="empty-state">Нет рабочих записей</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    const filterSelect = document.getElementById('workFilter');
    if (filterSelect) {
      filterSelect.addEventListener('change', (e) => {
        this.filter = e.target.value;
        this.render();
      });
    }
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.WorkView = WorkView;
WORKVIEW

echo "✅ WorkView.js исправлен"

# 4. ИСПРАВЛЯЕМ FamilyView.js
echo "4. 🔧 Исправляю FamilyView.js..."

cat > src/views/FamilyView.js << 'FAMILYVIEW'
/**
 * FAMILY VIEW v2.0
 */

const FamilyView = {
  container: null,
  filter: 'all',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    let entries = EntryService.getByCategory('family');
    const dogEntries = EntryService.getByCategory('dog');
    entries = [...entries, ...dogEntries];
    
    if (this.filter !== 'all') {
      const filterMap = {
        school: ['Школа', 'Садик'],
        circle: ['Кружок', 'Секция'],
        doctor: ['Врач'],
        dog: ['Ветеринар', 'Груминг', 'Прогулка']
      };
      const allowed = filterMap[this.filter] || [];
      entries = entries.filter(e => allowed.includes(e.service));
    }
    
    entries.sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    
    let html = `
      <div class="family-filters">
        <button class="family-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="family-filter ${this.filter === 'school' ? 'active' : ''}" data-filter="school">🏫 Школа</button>
        <button class="family-filter ${this.filter === 'circle' ? 'active' : ''}" data-filter="circle"> Кружки</button>
        <button class="family-filter ${this.filter === 'doctor' ? 'active' : ''}" data-filter="doctor"> Врачи</button>
        <button class="family-filter ${this.filter === 'dog' ? 'active' : ''}" data-filter="dog"> Собака</button>
      </div>
    `;
    
    if (entries.length === 0) {
      html += '<div class="empty-state">Нет семейных событий</div>';
    } else {
      entries.forEach(entry => {
        html += EntryCard.render(entry);
      });
    }
    
    this.container.innerHTML = html;
    
    this.container.querySelectorAll('.family-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.FamilyView = FamilyView;
FAMILYVIEW

echo "✅ FamilyView.js исправлен"

# 5. НОВАЯ ФУНКЦИЯ КОПИРОВАНИЯ С ВЫБОРОМ ДНЕЙ
echo "5. 📅 Добавляю копирование с выбором дней..."

cat >> src/globals.js << 'COPYDAYS'

// === КОПИРОВАНИЕ С ВЫБОРОМ ДНЕЙ НЕДЕЛИ ===
window.duplicateEntryWithDays = function(id) {
  console.log(' duplicateEntryWithDays:', id);
  try {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) {
      alert('❌ Запись не найдена!');
      return;
    }
    
    const content = `
      <div style="margin-bottom:15px;">
        <p style="margin-bottom:10px;"><b>Копировать "${entry.name}" на какие дни?</b></p>
        <p style="font-size:13px;color:#666;margin-bottom:15px;">Отметьте дни недели:</p>
        
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:8px;margin-bottom:15px;">
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="1" checked> Понедельник
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="2" checked> Вторник
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="3" checked> Среда
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="4" checked> Четверг
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="5" checked> Пятница
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="6"> Суббота
          </label>
          <label style="display:flex;align-items:center;gap:8px;padding:10px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
            <input type="checkbox" class="day-checkbox" value="0"> Воскресенье
          </label>
        </div>
        
        <label style="display:block;margin-bottom:5px;font-weight:600;">Количество недель:</label>
        <select id="weeksCount" style="width:100%;padding:10px;border:2px solid #e0e0e0;border-radius:8px;font-size:14px;">
          <option value="1">1 неделя</option>
          <option value="2">2 недели</option>
          <option value="4" selected>4 недели (месяц)</option>
          <option value="8">8 недель</option>
          <option value="12">12 недель (3 месяца)</option>
          <option value="36">36 недель (учебный год)</option>
        </select>
      </div>
      <div class="form-actions">
        <button class="save-btn" onclick="executeCopyWithDays(${entry.id})">Копировать</button>
        <button class="cancel-btn" onclick="Modal.close()">Отмена</button>
      </div>
    `;
    
    Modal.form({ title: '📅 Копировать на выбранные дни', content });
  } catch (e) {
    console.error('❌ Ошибка duplicateEntryWithDays:', e);
    alert('Ошибка: ' + e.message);
  }
};

window.executeCopyWithDays = function(id) {
  try {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) return;
    
    // Получаем выбранные дни
    const checkboxes = document.querySelectorAll('.day-checkbox:checked');
    const selectedDays = Array.from(checkboxes).map(cb => parseInt(cb.value));
    
    if (selectedDays.length === 0) {
      alert('❌ Выберите хотя бы один день!');
      return;
    }
    
    const weeksCount = parseInt(document.getElementById('weeksCount').value);
    const startDate = new Date(entry.date);
    let created = 0;
    
    for (let week = 0; week < weeksCount; week++) {
      for (const dayOfWeek of selectedDays) {
        const newDate = new Date(startDate);
        // Находим ближайший нужный день недели
        const currentDay = newDate.getDay();
        let daysToAdd = (dayOfWeek - currentDay + 7) % 7;
        if (week > 0) daysToAdd += week * 7;
        
        newDate.setDate(newDate.getDate() + daysToAdd);
        
        // Не создаём копию исходной даты
        if (newDate.toISOString().split('T')[0] === entry.date) continue;
        
        // Не создаём в прошлом
        if (newDate < startDate) continue;
        
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
    }
    
    Modal.close();
    setTimeout(() => {
      Modal.alert(`✅ Создано ${created} копий!`);
      refreshCurrentView();
    }, 100);
    
  } catch (error) {
    alert('❌ Ошибка: ' + error.message);
  }
};
COPYDAYS

echo "✅ Копирование с выбором дней добавлено"

# 6. Обновляем EntryCard — заменяем duplicateEntry на duplicateEntryWithDays
echo "6. 🔄 Обновляю EntryCard..."

cat > src/ui/components/EntryCard.js << 'ENTRYCARD'
/**
 * ENTRY CARD COMPONENT v6.0
 */

const EntryCard = {
  render(entry, options = {}) {
    const endTime = Entry.getEndTime(entry);
    const statusLabel = Entry.getStatusLabel(entry.status);
    const categoryIcons = { work: '💼', family: '👨‍👩‍👧', dog: '🐕' };
    
    return `
      <div class="entry-card category-${entry.category} status-${entry.status}" data-id="${entry.id}">
        <div class="entry-compact-info">
          <span class="entry-compact-time">${entry.time} - ${endTime}</span>
          <span class="entry-compact-name">${categoryIcons[entry.category] || ''} ${entry.name}</span>
          ${entry.price > 0 ? `<span class="entry-compact-price">${entry.price}₽</span>` : ''}
          <span class="expand-icon" onclick="window.toggleCard(${entry.id})">▼</span>
        </div>
        
        <div class="entry-details" id="details-${entry.id}" style="display:none;">
          <div><b>${entry.name}</b> <span class="status-badge status-${entry.status}">${statusLabel}</span></div>
          <div style="margin-top:5px;">
            ${entry.service}
            ${entry.zone ? ' · ' + entry.zone : ''}
            ${entry.phone ? ' · 📞 ' + entry.phone : ''}
            · ⏱️ ${entry.duration} мин
          </div>
          ${entry.notes ? `<div style="margin-top:5px;font-style:italic;">💬 ${entry.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons" id="status-${entry.id}" style="display:none;">
          <button class="status-btn ${entry.status==='new'?'active':''}" onclick="window.changeStatus(${entry.id}, 'new')">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" onclick="window.changeStatus(${entry.id}, 'confirmed')">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" onclick="window.changeStatus(${entry.id}, 'done')">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" onclick="window.changeStatus(${entry.id}, 'cancelled')">Отмена</button>
        </div>
        
        <div class="entry-actions" id="actions-${entry.id}" style="display:none;">
          <button class="btn-edit" onclick="window.editEntry(${entry.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="window.duplicateEntryWithDays(${entry.id})">📋 Копия</button>
          <button class="btn-del" onclick="window.deleteEntry(${entry.id})">🗑️ Удалить</button>
        </div>
      </div>
    `;
  }
};

window.EntryCard = EntryCard;
ENTRYCARD

echo "✅ EntryCard обновлён — использует duplicateEntryWithDays"

# 7. Перезапуск
echo ""
echo "7. 🚀 Перезапуск..."

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
echo "📋 ЧТО ИСПРАВЛЕНО:"
echo "  1. ✅ Убрана ошибка 'attachEvents is not a function'"
echo "  2. ✅ Новое копирование с выбором дней недели"
echo "  3. ✅ Можно выбрать: Пн, Вт, Ср, Чт, Пт, Сб, Вс"
echo "  4. ✅ Можно выбрать количество недель (1-36)"
echo ""
echo " ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Добавь запись (например, Школа)"
echo "2. Нажми на запись → раскрой"
echo "3. Нажми '📋 Копия'"
echo "4. Выбери дни: Пн-Пт (без выходных)"
echo "5. Выбери: 36 недель (учебный год)"
echo "6. Нажми 'Копировать'"
echo "   → Создастся 180 копий (5 дней × 36 недель)"
echo ""
echo "Теперь ошибка 'attachEvents' не должна появляться!"
echo "Напиши 'работает' или опиши что не так!"
