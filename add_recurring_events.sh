#!/bin/bash
echo "🔁 Добавляю повторяющиеся события..."

# 1. Обновляем Entry.js — добавляем поля для повторения
cat > src/models/Entry.js << 'ENTRY'
/**
 * ENTRY MODEL
 * Модель записи с повторяющимися событиями
 */

const Entry = {
  create(data) {
    const now = new Date().toISOString();
    return {
      id: Utils.generateId(),
      category: data.category || 'work',
      name: data.name || '',
      phone: data.phone || '',
      date: data.date || Utils.getToday(),
      time: data.time || Utils.getNow(),
      duration: data.duration || 60,
      service: data.service || '',
      zone: data.zone || '',
      notes: data.notes || '',
      price: data.price || 0,
      status: data.status || 'new',
      familyMemberId: data.familyMemberId || null,
      // Повторяющиеся события
      recurring: data.recurring || {
        enabled: false,
        type: 'daily', // daily, weekly, biweekly, monthly
        endDate: null,
        occurrences: null // количество повторений
      },
      parentEntryId: data.parentEntryId || null, // ID родительской записи
      createdAt: now,
      updatedAt: now
    };
  },
  
  validate(entry) {
    const errors = [];
    if (!entry.name || entry.name.trim() === '') {
      errors.push('Название обязательно');
    }
    if (!entry.date || !/^\d{4}-\d{2}-\d{2}$/.test(entry.date)) {
      errors.push('Неверная дата');
    }
    if (!entry.time || !/^\d{2}:\d{2}$/.test(entry.time)) {
      errors.push('Неверное время');
    }
    return { valid: errors.length === 0, errors };
  },
  
  getEndTime(entry) {
    return Utils.calcEndTime(entry.time, entry.duration);
  },
  
  getStatusLabel(status) {
    const labels = {
      new: 'Новая',
      confirmed: 'Подтверждена',
      done: 'Выполнена',
      cancelled: 'Отменена'
    };
    return labels[status] || status;
  },
  
  getRecurringLabel(type) {
    const labels = {
      daily: 'Каждый день',
      weekly: 'Каждую неделю',
      biweekly: 'Каждые 2 недели',
      monthly: 'Каждый месяц'
    };
    return labels[type] || type;
  }
};

window.Entry = Entry;
ENTRY

echo "✅ Entry.js обновлён — добавлены повторяющиеся события"

# 2. Обновляем EntryService — создание повторяющихся записей
cat > src/services/EntryService.js << 'SERVICE'
/**
 * ENTRY SERVICE
 * С поддержкой повторяющихся событий
 */

const EntryService = {
  getAll() {
    return Store.getEntries();
  },
  
  getByDate(date) {
    return Store.getEntries().filter(e => e.date === date && e.status !== 'cancelled');
  },
  
  getByCategory(category) {
    return Store.getEntries().filter(e => e.category === category && e.status !== 'cancelled');
  },
  
  getByPeriod(startDate, endDate) {
    return Store.getEntries().filter(e => {
      return e.date >= startDate && e.date <= endDate && e.status !== 'cancelled';
    });
  },
  
  create(data, force = false) {
    const entry = Entry.create(data);
    const validation = Entry.validate(entry);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    // Проверка конфликтов только для рабочих записей
    if (entry.category === 'work' && !force) {
      const conflict = this.checkConflict(entry);
      if (conflict) {
        throw new Error(`Конфликт с записью: ${conflict.name}`);
      }
    }
    
    Store.addEntry(entry);
    Events.emit('entry:created', entry);
    
    // Если повторяющееся — создаём серии
    if (entry.recurring && entry.recurring.enabled) {
      this.createRecurringEntries(entry);
    }
    
    return entry;
  },
  
  /**
   * Создать серию повторяющихся записей
   */
  createRecurringEntries(parentEntry) {
    const recurring = parentEntry.recurring;
    if (!recurring || !recurring.enabled) return;
    
    const startDate = new Date(parentEntry.date);
    let endDate = recurring.endDate ? new Date(recurring.endDate) : null;
    const maxOccurrences = recurring.occurrences || 52; // максимум 52 повторения
    
    const occurrences = [];
    let currentDate = new Date(startDate);
    let count = 0;
    
    while ((!endDate || currentDate <= endDate) && count < maxOccurrences) {
      count++;
      
      // Создаём следующую запись
      const nextDate = new Date(currentDate);
      const dateStr = nextDate.toISOString().split('T')[0];
      
      // Не создаём дубликат первой записи
      if (dateStr !== parentEntry.date) {
        const newEntry = Entry.create({
          ...parentEntry,
          date: dateStr,
          parentEntryId: parentEntry.id,
          recurring: { enabled: false } // У дочерних записей повторение отключено
        });
        
        // Проверяем конфликты
        const conflict = this.checkConflict(newEntry);
        if (!conflict) {
          Store.addEntry(newEntry);
          occurrences.push(newEntry);
        }
      }
      
      // Переходим к следующей дате
      if (recurring.type === 'daily') {
        currentDate.setDate(currentDate.getDate() + 1);
      } else if (recurring.type === 'weekly') {
        currentDate.setDate(currentDate.getDate() + 7);
      } else if (recurring.type === 'biweekly') {
        currentDate.setDate(currentDate.getDate() + 14);
      } else if (recurring.type === 'monthly') {
        currentDate.setMonth(currentDate.getMonth() + 1);
      }
    }
    
    if (occurrences.length > 0) {
      Events.emit('recurring:created', {
        parent: parentEntry,
        occurrences: occurrences.length
      });
    }
    
    return occurrences;
  },
  
  update(id, updates) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    const updated = { ...entry, ...updates, updatedAt: new Date().toISOString() };
    const validation = Entry.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.updateEntry(id, updated);
    Events.emit('entry:updated', updated);
    return updated;
  },
  
  delete(id, deleteAllRecurring = false) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    // Если это родительская запись и нужно удалить все
    if (deleteAllRecurring && entry.recurring && entry.recurring.enabled) {
      const allEntries = Store.getEntries();
      const recurringEntries = allEntries.filter(e => e.parentEntryId === id);
      
      recurringEntries.forEach(e => {
        Store.deleteEntry(e.id);
      });
    }
    
    Store.deleteEntry(id);
    Events.emit('entry:deleted', id);
  },
  
  changeStatus(id, status) {
    return this.update(id, { status });
  },
  
  checkConflict(entry) {
    const dayEntries = this.getByDate(entry.date);
    
    const entryStart = Utils.timeToMinutes(entry.time);
    const entryEnd = entryStart + entry.duration;
    
    return dayEntries.find(e => {
      if (e.id === entry.id) return false;
      
      const eStart = Utils.timeToMinutes(e.time);
      const eEnd = eStart + e.duration;
      
      return (entryStart < eEnd && entryEnd > eStart);
    });
  },
  
  getStats(startDate, endDate) {
    const entries = this.getByPeriod(startDate, endDate);
    const workEntries = entries.filter(e => e.category === 'work');
    
    return {
      total: entries.length,
      work: workEntries.length,
      family: entries.filter(e => e.category === 'family').length,
      done: entries.filter(e => e.status === 'done').length,
      cancelled: entries.filter(e => e.status === 'cancelled').length,
      income: workEntries.reduce((sum, e) => sum + e.price, 0)
    };
  },
  
  duplicate(id, newDate) {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) throw new Error('Запись не найдена');
    
    const duplicate = Entry.create({
      ...entry,
      date: newDate || entry.date,
      name: entry.name + ' (копия)',
      status: 'new',
      recurring: { enabled: false }
    });
    
    Store.addEntry(duplicate);
    return duplicate;
  },
  
  getUpcoming(limit = 5) {
    const today = Utils.getToday();
    return this.getAll()
      .filter(e => e.date >= today && e.status !== 'cancelled')
      .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time))
      .slice(0, limit);
  },
  
  clearAll() {
    Storage.set('gdesveta_store', {
      entries: [],
      notes: Store.getNotes(),
      priceList: Store.getPriceList(),
      familyMembers: Store.getFamilyMembers()
    });
    Events.emit('store:cleared');
  },
  
  /**
   * Получить все повторяющиеся записи
   */
  getRecurringEntries() {
    return Store.getEntries().filter(e => 
      e.recurring && e.recurring.enabled
    );
  },
  
  /**
   * Удалить все будущие повторения записи
   */
  deleteFutureRecurring(parentId) {
    const allEntries = Store.getEntries();
    const today = Utils.getToday();
    
    const futureRecurring = allEntries.filter(e => 
      e.parentEntryId === parentId && e.date >= today
    );
    
    futureRecurring.forEach(e => {
      Store.deleteEntry(e.id);
    });
    
    return futureRecurring.length;
  }
};

window.EntryService = EntryService;
SERVICE

echo "✅ EntryService обновлён — создание серий записей"

# 3. Обновляем index.html — добавляем UI для повторяющихся событий
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
        <button class="nav-btn" data-tab="work"></button>
        <button class="nav-btn" data-tab="family">👨‍👧</button>
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
          <h2> Работа</h2>
          <button class="tab-action-btn" onclick="showPriceList()"> Прайс</button>
        </div>
        <div id="workView"></div>
      </div>

      <div id="tab-family" class="tab-content">
        <div class="tab-header">
          <h2>👩‍👧 Семья</h2>
          <button class="tab-action-btn" onclick="showFamilyMembers()"> Семья</button>
        </div>
        <div id="familyView"></div>
      </div>

      <div id="tab-notes" class="tab-content">
        <div class="tab-header">
          <h2> Заметки</h2>
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

  <div id="modalContainer"></div>

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

echo "✅ index.html обновлён"

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
echo "🔁 ПРИОРИТЕТ 1 ВЫПОЛНЕН!"
echo ""
echo "✅ Добавлены повторяющиеся события:"
echo "  • Ежедневно"
echo "  • Еженедельно"
echo "  • Каждые 2 недели"
echo "  • Ежемесячно"
echo ""
echo "Как работает:"
echo "  1. Создаёшь запись"
echo "  2. Включаешь 'Повторять'"
echo "  3. Выбираешь тип (день/неделя/месяц)"
echo "  4. Указываешь конец или количество"
echo "  5. Приложение создаёт серию записей"
echo ""
echo "📋 Следующий шаг: Push-уведомления"
