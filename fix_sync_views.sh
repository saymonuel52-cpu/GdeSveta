#!/bin/bash
echo "🔧 ИСПРАВЛЯЮ СИНХРОНИЗАЦИЮ ВСЕХ VIEW"

# 1. ИСПРАВЛЯЕМ globals.js — обновляем ВСЕ views
echo "1. 🔧 Исправляю globals.js..."

cat > src/globals.js << 'GLOBALS'
/**
 * GLOBALS.JS v2.0
 * Обновляем ВСЕ views при изменении
 */

console.log(' globals.js загружен');

// === ОБНОВЛЕНИЕ ВСЕХ VIEW ===
function refreshAllViews() {
  console.log(' Обновляю все views...');
  if (typeof CalendarView !== 'undefined') CalendarView.render();
  if (typeof WorkView !== 'undefined') WorkView.render();
  if (typeof FamilyView !== 'undefined') FamilyView.render();
  if (typeof NotesView !== 'undefined') NotesView.render();
  if (typeof TasksView !== 'undefined') TasksView.render();
  console.log('✅ Все views обновлены');
}

function refreshCurrentView() {
  if (typeof currentTab === 'undefined') {
    refreshAllViews();
    return;
  }
  
  if (currentTab === 'calendar' && typeof CalendarView !== 'undefined') {
    CalendarView.render();
  } else if (currentTab === 'work' && typeof WorkView !== 'undefined') {
    WorkView.render();
  } else if (currentTab === 'family' && typeof FamilyView !== 'undefined') {
    FamilyView.render();
  } else if (currentTab === 'notes' && typeof NotesView !== 'undefined') {
    NotesView.render();
  } else if (currentTab === 'tasks' && typeof TasksView !== 'undefined') {
    TasksView.render();
  }
  
  // Дополнительно обновляем календарь (он главный)
  if (currentTab !== 'calendar' && typeof CalendarView !== 'undefined') {
    setTimeout(() => CalendarView.render(), 100);
  }
}

// === УПРАВЛЕНИЕ ЗАПИСЯМИ ===

window.changeStatus = function(id, status) {
  console.log('🔴 changeStatus:', id, status);
  try {
    if (typeof EntryService === 'undefined') {
      alert('❌ EntryService не загружен!');
      return;
    }
    EntryService.changeStatus(id, status);
    refreshAllViews(); // Обновляем ВСЕ views
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
      alert(' Store не загружен!');
      return;
    }
    const entry = Store.getEntries().find(e => e.id === id);
    if (!entry) {
      alert('❌ Запись не найдена!');
      return;
    }
    
    if (entry.category === 'work') {
      if (typeof openWorkForm !== 'undefined') openWorkForm(id);
      else alert(' openWorkForm не найдена!');
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
    if (!entry) {
      alert('❌ Запись не найдена!');
      return;
    }
    
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
        const currentDay = newDate.getDay();
        let daysToAdd = (dayOfWeek - currentDay + 7) % 7;
        if (week > 0) daysToAdd += week * 7;
        
        newDate.setDate(newDate.getDate() + daysToAdd);
        
        if (newDate.toISOString().split('T')[0] === entry.date) continue;
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
      refreshAllViews(); // Обновляем ВСЕ views
    }, 100);
    
  } catch (error) {
    alert('❌ Ошибка: ' + error.message);
  }
};

window.deleteEntry = function(id) {
  console.log(' deleteEntry:', id);
  try {
    if (typeof Modal === 'undefined') {
      if (confirm('Удалить эту запись?')) {
        EntryService.delete(id);
        refreshAllViews(); // Обновляем ВСЕ views
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
          refreshAllViews(); // Обновляем ВСЕ views
        }, 100);
      } catch (error) {
        Modal.alert('❌ Ошибка: ' + error.message);
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

console.log('✅ Все глобальные функции зарегистрированы');
console.log('   refreshAllViews:', typeof refreshAllViews);
console.log('   deleteEntry:', typeof window.deleteEntry);
console.log('   changeStatus:', typeof window.changeStatus);
GLOBALS

echo "✅ globals.js обновлён — refreshAllViews()"

# 2. ОБНОВЛЯЕМ app.js — используем refreshAllViews
echo "2. 🔧 Обновляю app.js..."

# Добавляем refreshAllViews в app.js
cat >> app.js << 'APPEND'

// Глобальная функция для обновления всех views
window.refreshAllViews = function() {
  if (typeof CalendarView !== 'undefined') CalendarView.render();
  if (typeof WorkView !== 'undefined') WorkView.render();
  if (typeof FamilyView !== 'undefined') FamilyView.render();
  if (typeof NotesView !== 'undefined') NotesView.render();
  if (typeof TasksView !== 'undefined') TasksView.render();
};
APPEND

echo "✅ app.js обновлён"

# 3. Перезапуск
echo "3. 🚀 Перезапуск..."

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
echo "✅ СИНХРОНИЗАЦИЯ ИСПРАВЛЕНА!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 ЧТО ИСПРАВЛЕНО:"
echo "  1. ✅ refreshAllViews() — обновляет ВСЕ вкладки"
echo "  2. ✅ deleteEntry() — вызывает refreshAllViews()"
echo "  3. ✅ changeStatus() — вызывает refreshAllViews()"
echo "  4. ✅ duplicateEntryWithDays() — refreshAllViews()"
echo ""
echo " ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Добавь запись (Работа)"
echo "2. Перейди на вкладку Календарь"
echo "3. Удали запись"
echo "   → Запись должна удалиться ВЕЗДЕ"
echo ""
echo "4. Перейди на вкладку Работа"
echo "   → Записи НЕ должно быть"
echo ""
echo "5. Попробуй изменить статус"
echo "   → Изменится во всех вкладках"
echo ""
echo "Теперь ВСЕ вкладки синхронизированы!"
echo "Напиши 'работает' или опиши проблему!"
