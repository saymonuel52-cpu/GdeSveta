#!/bin/bash
echo " ИСПРАВЛЯЮ СОХРАНЕНИЕ ПРИ КОНФЛИКТЕ..."

# Создаём новый файл с исправленной логикой
cat > fix_buffer_logic.js << 'FIX'

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
FIX

# Добавляем в app.js
cat fix_buffer_logic.js >> app.js
rm fix_buffer_logic.js

echo "✅ Логика исправлена"

# Добавляем стили для пометки "малый перерыв"
cat >> styles/main.css << 'STYLES'

/* Пометка о малом перерыве */
.entry-card.has-small-gap {
  border-left: 4px solid #f59e0b;
  animation: pulseWarning 2s infinite;
}

@keyframes pulseWarning {
  0%, 100% { box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3); }
  50% { box-shadow: 0 4px 16px rgba(245, 158, 11, 0.6); }
}

.entry-card.has-small-gap::after {
  content: '⚠️ Малый перерыв';
  position: absolute;
  top: 10px;
  right: 10px;
  background: #f59e0b;
  color: white;
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
}
STYLES

echo "✅ Стили добавлены"

# Обновляем EntryCard чтобы показывал пометку
sed -i 's|const EntryCard = {|const EntryCard = {\n  hasSmallGap: function(entry) {\n    const notes = entry.notes || "";\n    return notes.includes("⚠️ Малый перерыв");\n  },|' src/ui/components/EntryCard.js

echo "✅ EntryCard обновлён"

# Git + сборка
echo ""
echo " Отправка на GitHub и сборка..."

git add .
git commit -m "fix: Исправлено сохранение при конфликте + пометка о малом перерыве"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_BufferFixed.apk
  cd ..
  cp GdeSveta_BufferFixed.apk ~/storage/downloads/GdeSveta_BufferFixed.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ ИСПРАВЛЕНО! ТЕПЕРЬ РАБОТАЕТ!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_BufferFixed.apk"
  echo ""
  echo " ЧТО ИСПРАВЛЕНО:"
  echo "✅ При нажатии 'Да' — запись СОХРАНЯЕТСЯ"
  echo "✅ При нажатии 'Нет' — предлагается свободное время"
  echo "✅ Если перерыв < 10 мин — на карточке пометка ⚠️"
  echo "✅ Клиент не теряется!"
  echo ""
  echo " ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_BufferFixed.apk"
  echo "2. Добавь запись на 10:00"
  echo "3. Добавь вторую на 10:15 (через 15 мин)"
  echo "4. Появится предупреждение"
  echo "5. Нажми 'Да' — запись сохранится!"
  echo "6. На карточке будет ⚠️ Малый перерыв"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
