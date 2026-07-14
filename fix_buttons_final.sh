#!/bin/bash
echo "🔧 ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ КНОПОК"

# 1. Создаём globals.js — ВСЕ глобальные функции в одном месте
echo "1. 📦 Создаю globals.js..."

cat > src/globals.js << 'GLOBALS'
/**
 * GLOBALS.JS
 * ВСЕ глобальные функции приложения
 * Загружается ПОСЛЕ app.js — гарантирует доступность
 */

console.log(' globals.js загружен');

// === УПРАВЛЕНИЕ ЗАПИСЯМИ ===

window.changeStatus = function(id, status) {
  console.log('🔴 changeStatus:', id, status);
  try {
    if (typeof EntryService === 'undefined') {
      alert('❌ EntryService не загружен!');
      return;
    }
    EntryService.changeStatus(id, status);
    refreshCurrentView();
    console.log('✅ changeStatus выполнена');
  } catch (e) {
    console.error('❌ Ошибка changeStatus:', e);
    alert('Ошибка: ' + e.message);
  }
};

window.editEntry = function(id) {
  console.log('🔴 editEntry:', id);
  try {
    if (typeof Store === 'undefined') {
      alert('❌ Store не загружен!');
      return;
    }
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) {
      alert(' Запись не найдена!');
      return;
    }
    
    if (entry.category === 'work') {
      if (typeof openWorkForm !== 'undefined') openWorkForm(id);
      else alert('❌ openWorkForm не найдена!');
    } else if (entry.category === 'family' || entry.category === 'dog') {
      if (typeof openFamilyForm !== 'undefined') openFamilyForm(id);
      else alert('❌ openFamilyForm не найдена!');
    }
    console.log('✅ editEntry выполнена');
  } catch (e) {
    console.error('❌ Ошибка editEntry:', e);
    alert('Ошибка: ' + e.message);
  }
};

window.duplicateEntry = function(id) {
  console.log(' duplicateEntry:', id);
  try {
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) {
      alert('❌ Запись не найдена!');
      return;
    }
    
    if (typeof Modal === 'undefined') {
      alert('❌ Modal не загружен!');
      return;
    }
    
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
          refreshCurrentView();
        }, 100);
        
      } catch (error) {
        Modal.alert('❌ Ошибка: ' + error.message);
      }
    });
    console.log('✅ duplicateEntry выполнена');
  } catch (e) {
    console.error('❌ Ошибка duplicateEntry:', e);
    alert('Ошибка: ' + e.message);
  }
};

window.deleteEntry = function(id) {
  console.log('🔴 deleteEntry:', id);
  try {
    if (typeof Modal === 'undefined') {
      // Fallback если Modal не загружен
      if (confirm('Удалить эту запись?')) {
        EntryService.delete(id);
        refreshCurrentView();
        alert('✅ Запись удалена!');
      }
      return;
    }
    
    Modal.confirm('Удалить эту запись?', () => {
      try {
        EntryService.delete(id);
        Modal.close();
        setTimeout(() => {
          Modal.alert('✅ Запись удалена!');
          refreshCurrentView();
        }, 100);
      } catch (error) {
        Modal.alert(' Ошибка: ' + error.message);
      }
    });
    console.log('✅ deleteEntry выполнена');
  } catch (e) {
    console.error('❌ Ошибка deleteEntry:', e);
    alert('Ошибка: ' + e.message);
  }
};

// === ВСПОМОГАТЕЛЬНЫЕ ===

window.toggleCard = function(id) {
  const details = document.getElementById(`details-${id}`);
  const status = document.getElementById(`status-${id}`);
  const actions = document.getElementById(`actions-${id}`);
  
  if (details && status && actions) {
    const isHidden = details.style.display === 'none' || details.style.display === '';
    details.style.display = isHidden ? 'block' : 'none';
    status.style.display = isHidden ? 'block' : 'none';
    actions.style.display = isHidden ? 'block' : 'none';
  }
};

function refreshCurrentView() {
  if (typeof currentTab === 'undefined') return;
  
  if (currentTab === 'calendar' && typeof CalendarView !== 'undefined') {
    CalendarView.render();
  } else if (currentTab === 'work' && typeof WorkView !== 'undefined') {
    WorkView.render();
  } else if (currentTab === 'family' && typeof FamilyView !== 'undefined') {
    FamilyView.render();
  }
}

console.log('✅ Все глобальные функции зарегистрированы');
console.log('   deleteEntry:', typeof window.deleteEntry);
console.log('   changeStatus:', typeof window.changeStatus);
console.log('   editEntry:', typeof window.editEntry);
console.log('   duplicateEntry:', typeof window.duplicateEntry);
GLOBALS

echo "✅ globals.js создан"

# 2. Упрощаем EntryCard.js — только генерация HTML
echo "2. 🎨 Упрощаю EntryCard.js..."

cat > src/ui/components/EntryCard.js << 'ENTRYCARD'
/**
 * ENTRY CARD COMPONENT v5.0
 * Только генерация HTML. Все функции — в globals.js
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
          ${entry.notes ? `<div style="margin-top:5px;font-style:italic;"> ${entry.notes}</div>` : ''}
        </div>
        
        <div class="status-buttons" id="status-${entry.id}" style="display:none;">
          <button class="status-btn ${entry.status==='new'?'active':''}" onclick="window.changeStatus(${entry.id}, 'new')">Новая</button>
          <button class="status-btn ${entry.status==='confirmed'?'active':''}" onclick="window.changeStatus(${entry.id}, 'confirmed')">Подтв.</button>
          <button class="status-btn ${entry.status==='done'?'active':''}" onclick="window.changeStatus(${entry.id}, 'done')">Выполн.</button>
          <button class="status-btn ${entry.status==='cancelled'?'active':''}" onclick="window.changeStatus(${entry.id}, 'cancelled')">Отмена</button>
        </div>
        
        <div class="entry-actions" id="actions-${entry.id}" style="display:none;">
          <button class="btn-edit" onclick="window.editEntry(${entry.id})">✏️ Изменить</button>
          <button class="btn-dup" onclick="window.duplicateEntry(${entry.id})">📋 Копировать</button>
          <button class="btn-del" onclick="window.deleteEntry(${entry.id})">🗑️ Удалить</button>
        </div>
      </div>
    `;
  }
};

window.EntryCard = EntryCard;
ENTRYCARD

echo "✅ EntryCard.js упрощён"

# 3. Обновляем index.html — добавляем globals.js ПОСЛЕ app.js
echo "3. 📄 Обновляю index.html..."

cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="styles/main.css?v=4">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <button class="theme-toggle" id="themeToggle" title="Переключить тему">🌙</button>
      <nav>
        <button class="nav-btn active" data-tab="calendar">📅</button>
        <button class="nav-btn" data-tab="work">💼</button>
        <button class="nav-btn" data-tab="family">👨‍👩‍</button>
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
          <h2>👨‍👩‍ Семья</h2>
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
          <button id="pinBtn" class="action-btn" onclick="openPinSettings()"> PIN</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>

    <button class="add-btn-fixed" onclick="openQuickAdd()">+ Добавить</button>
  </div>

  <div id="notificationContainer"></div>
  <div id="modalContainer"></div>

  <!-- ЯДРО -->
  <script src="src/core/storage.js?v=4"></script>
  <script src="src/core/events.js?v=4"></script>
  <script src="src/core/utils.js?v=4"></script>
  <script src="src/core/store.js?v=4"></script>
  
  <!-- МОДЕЛИ -->
  <script src="src/models/Entry.js?v=4"></script>
  <script src="src/models/Note.js?v=4"></script>
  <script src="src/models/PriceItem.js?v=4"></script>
  <script src="src/models/FamilyMember.js?v=4"></script>
  
  <!-- СЕРВИСЫ -->
  <script src="src/services/EntryService.js?v=4"></script>
  <script src="src/services/NoteService.js?v=4"></script>
  <script src="src/services/PriceService.js?v=4"></script>
  <script src="src/services/FamilyService.js?v=4"></script>
  <script src="src/services/ConflictChecker.js?v=4"></script>
  <script src="src/services/NotificationService.js?v=4"></script>
  <script src="src/services/FamilyShare.js?v=4"></script>
  <script src="src/services/TemplateService.js?v=4"></script>
  
  <!-- UI КОМПОНЕНТЫ -->
  <script src="src/ui/components/Modal.js?v=4"></script>
  <script src="src/ui/components/Calendar.js?v=4"></script>
  <script src="src/ui/components/EntryCard.js?v=4"></script>
  <script src="src/ui/components/NoteCard.js?v=4"></script>
  <script src="src/ui/components/FamilySelect.js?v=4"></script>
  
  <!-- VIEWS -->
  <script src="src/views/CalendarView.js?v=4"></script>
  <script src="src/views/WorkView.js?v=4"></script>
  <script src="src/views/FamilyView.js?v=4"></script>
  <script src="src/views/NotesView.js?v=4"></script>
  <script src="src/views/StatsView.js?v=4"></script>
  <script src="src/views/TasksView.js?v=4"></script>
  
  <!-- ГЛАВНАЯ ЛОГИКА -->
  <script src="app.js?v=4"></script>
  
  <!-- ГЛОБАЛЬНЫЕ ФУНКЦИИ (ЗАГРУЖАЕТСЯ ПОСЛЕДНИМ!) -->
  <script src="src/globals.js?v=4"></script>
</body>
</html>
HTML

echo "✅ index.html обновлён — globals.js загружается последним"

# 4. Перезапуск
echo ""
echo "4. 🚀 Перезапуск..."

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
echo "✅ КНОПКИ ИСПРАВЛЕНЫ!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО СДЕЛАНО:"
echo "  1. ✅ Создан globals.js — все функции в одном месте"
echo "  2. ✅ globals.js загружается ПОСЛЕ app.js"
echo "  3. ✅ EntryCard.js только генерирует HTML"
echo "  4. ✅ Все onclick используют window.functionName"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Добавь запись (Работа или Семья)"
echo "2. Нажми на запись — раскрой детали"
echo "3. Нажми '🗑️ Удалить' → подтверди"
echo "   → Запись должна УДАЛИТЬСЯ"
echo ""
echo "4. Добавь запись"
echo "5. Нажми '📋 Копировать' → подтверди"
echo "   → Должно создаться 7 копий"
echo ""
echo "6. Нажми 'Подтв.' или 'Выполн.'"
echo "   → Статус должен измениться"
echo ""
echo "Открой консоль браузера (F12) и смотри логи:"
echo "  🔴 changeStatus вызвана: ..."
echo "  ✅ changeStatus выполнена"
echo ""
echo "Напиши 'работает' или скинь скриншот консоли!"
