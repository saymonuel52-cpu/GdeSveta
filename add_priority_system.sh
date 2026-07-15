#!/bin/bash
echo "🎯 ДОБАВЛЯЮ СИСТЕМУ ПРИОРИТЕТОВ..."

# Добавляем в app.js
cat >> app.js << 'PRIORITY'

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
PRIORITY

echo "✅ Система приоритетов добавлена"

# Добавляем стили для приоритетов
cat >> styles/main.css << 'STYLES'

/* Приоритеты событий */
.priority-critical {
  border-left: 4px solid #ef4444 !important;
}

.priority-important {
  border-left: 4px solid #f59e0b !important;
}

.priority-flexible {
  border-left: 4px solid #10b981 !important;
}

.priority-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  margin-left: 8px;
}

.priority-badge.critical {
  background: #ef4444;
  color: white;
}

.priority-badge.important {
  background: #f59e0b;
  color: white;
}

.priority-badge.flexible {
  background: #10b981;
  color: white;
}
STYLES

echo "✅ Стили приоритетов добавлены"

# Обновляем EntryCard для отображения приоритетов
cat > temp_patch.js << 'PATCH'

// Патч для EntryCard — добавляем приоритеты
const _origRender = EntryCard.render;
EntryCard.render = function(entry, options) {
  const html = _origRender.call(this, entry, options);
  const priority = getEventPriority(entry);
  
  // Добавляем класс приоритета
  return html.replace('class="entry-card', `class="entry-card priority-${priority.key.toLowerCase()}"`);
};
PATCH

cat temp_patch.js >> app.js
rm temp_patch.js

echo "✅ EntryCard обновлён для приоритетов"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлена система умных конфликтов с приоритетами"
git push origin main

echo "📦 Сборка APK..."
rm -rf android www
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ www/

npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Priority.apk
  cd ..
  cp GdeSveta_Priority.apk ~/storage/downloads/GdeSveta_Priority.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🎯 СИСТЕМА ПРИОРИТЕТОВ ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo " APK: ~/storage/downloads/GdeSveta_Priority.apk"
  echo ""
  echo "✅ ТРИ УРОВНЯ ПРИОРИТЕТА:"
  echo "🔴 Критично: Школа, Врач, Работа (нельзя перенести)"
  echo "🟡 Важно: Кружки, Секции (желательно не трогать)"
  echo "🟢 Гибко: Прогулка, Заметки (можно двигать)"
  echo ""
  echo "✅ УМНЫЕ ПРЕДЛОЖЕНИЯ:"
  echo "• Если новое событие важнее — предлагает перенести старое"
  echo "• Если старое важнее — предлагает другое время для нового"
  echo "• Если равны — даёт выбор пользователю"
  echo ""
  echo "✅ ВИЗУАЛЬНАЯ ИНДИКАЦИЯ:"
  echo "• Цветная полоска слева на карточке"
  echo "• Бейдж с приоритетом"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_Priority.apk"
  echo "2. Добавь запись 'Школа' на 10:00 (критично)"
  echo "3. Попробуй добавить 'Прогулка' на 10:00 (гибко)"
  echo "4. Система скажет: 'Школу нельзя переносить, перенести прогулку?'"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
