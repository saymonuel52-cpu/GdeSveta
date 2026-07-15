#!/bin/bash
echo " ДОБАВЛЯЮ СИСТЕМУ РАБОЧЕГО ВРЕМЕНИ..."

# 1. Создаём модуль правил расписания
cat > src/services/ScheduleRules.js << 'RULES'
/**
 * SCHEDULE RULES
 * Управление рабочим временем и правилами расписания
 */

const ScheduleRules = {
  // Значения по умолчанию
  defaults: {
    workDays: [1, 2, 3, 4, 5, 6], // Пн-Сб (0=Вс, 1=Пн, ..., 6=Сб)
    workStart: '09:00',
    workEnd: '20:00',
    lunchBreak: { start: '13:00', end: '14:00', enabled: false },
    bufferTime: 10, // минут между записями
    maxBookingsPerDay: 8
  },

  // Получить текущие настройки
  getSettings: function() {
    const saved = Storage.get('scheduleRules', null);
    return saved ? JSON.parse(saved) : this.defaults;
  },

  // Сохранить настройки
  saveSettings: function(settings) {
    Storage.set('scheduleRules', JSON.stringify(settings));
  },

  // Проверить, является ли день рабочим
  isWorkDay: function(date) {
    const settings = this.getSettings();
    const dayOfWeek = new Date(date).getDay();
    return settings.workDays.includes(dayOfWeek);
  },

  // Проверить, находится ли время в рабочих часах
  isWorkTime: function(time) {
    const settings = this.getSettings();
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;
    
    const [startHours, startMinutes] = settings.workStart.split(':').map(Number);
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    
    const startInMinutes = startHours * 60 + startMinutes;
    const endInMinutes = endHours * 60 + endMinutes;
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  },

  // Проверить обеденный перерыв
  isLunchBreak: function(time) {
    const settings = this.getSettings();
    if (!settings.lunchBreak.enabled) return false;
    
    const [hours, minutes] = time.split(':').map(Number);
    const timeInMinutes = hours * 60 + minutes;
    
    const [startHours, startMinutes] = settings.lunchBreak.start.split(':').map(Number);
    const [endHours, endMinutes] = settings.lunchBreak.end.split(':').map(Number);
    
    const startInMinutes = startHours * 60 + startMinutes;
    const endInMinutes = endHours * 60 + endMinutes;
    
    return timeInMinutes >= startInMinutes && timeInMinutes <= endInMinutes;
  },

  // Полная проверка времени записи
  validateBooking: function(date, time, duration) {
    const errors = [];
    const warnings = [];
    
    // Проверка рабочего дня
    if (!this.isWorkDay(date)) {
      errors.push('❌ Этот день — выходной');
    }
    
    // Проверка рабочего времени
    if (!this.isWorkTime(time)) {
      errors.push(' Время вне рабочих часов');
    }
    
    // Проверка обеденного перерыва
    if (this.isLunchBreak(time)) {
      errors.push('❌ Время обеда');
    }
    
    // Проверка окончания записи
    const [hours, minutes] = time.split(':').map(Number);
    const endTimeInMinutes = hours * 60 + minutes + duration;
    const settings = this.getSettings();
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    const workEndInMinutes = endHours * 60 + endMinutes;
    
    if (endTimeInMinutes > workEndInMinutes) {
      errors.push('❌ Запись выходит за рабочее время');
    }
    
    // Проверка количества записей в день
    const dayEntries = Store.getEntries().filter(e => e.date === date && e.category === 'work');
    if (dayEntries.length >= settings.maxBookingsPerDay) {
      warnings.push('⚠️ Максимальное количество записей на этот день');
    }
    
    return { valid: errors.length === 0, errors, warnings };
  },

  // Найти свободные окна на дату
  findFreeSlots: function(date, duration) {
    const settings = this.getSettings();
    if (!this.isWorkDay(date)) return [];
    
    const entries = Store.getEntries()
      .filter(e => e.date === date && e.category === 'work')
      .sort((a, b) => a.time.localeCompare(b.time));
    
    const [startHours, startMinutes] = settings.workStart.split(':').map(Number);
    const [endHours, endMinutes] = settings.workEnd.split(':').map(Number);
    
    const dayStart = startHours * 60 + startMinutes;
    const dayEnd = endHours * 60 + endMinutes;
    
    const lunchStart = settings.lunchBreak.enabled ? 
      (parseInt(settings.lunchBreak.start.split(':')[0]) * 60 + parseInt(settings.lunchBreak.start.split(':')[1])) : null;
    const lunchEnd = settings.lunchBreak.enabled ? 
      (parseInt(settings.lunchBreak.end.split(':')[0]) * 60 + parseInt(settings.lunchBreak.end.split(':')[1])) : null;
    
    const slots = [];
    let currentTime = dayStart;
    
    for (const entry of entries) {
      const [entryHours, entryMinutes] = entry.time.split(':').map(Number);
      const entryStart = entryHours * 60 + entryMinutes;
      const entryEnd = entryStart + entry.duration + settings.bufferTime;
      
      // Проверяем окно перед записью
      if (currentTime + duration <= entryStart) {
        // Проверяем обед
        if (!(lunchStart && currentTime < lunchEnd && entryStart > lunchStart)) {
          slots.push({
            start: this.minutesToTime(currentTime),
            end: this.minutesToTime(currentTime + duration)
          });
        }
      }
      
      currentTime = Math.max(currentTime, entryEnd);
    }
    
    // Последнее окно дня
    if (currentTime + duration <= dayEnd) {
      if (!(lunchStart && currentTime < lunchEnd && dayEnd > lunchStart)) {
        slots.push({
          start: this.minutesToTime(currentTime),
          end: this.minutesToTime(currentTime + duration)
        });
      }
    }
    
    return slots;
  },

  minutesToTime: function(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
  }
};

window.ScheduleRules = ScheduleRules;
RULES

echo "✅ ScheduleRules.js создан"

# 2. Добавляем скрипт в index.html
sed -i '/<script src="src\/services\/Predictor.js"><\/script>/a \  <script src="src/services/ScheduleRules.js"></script>' index.html

echo "✅ ScheduleRules.js подключен"

# 3. Создаём UI для настройки рабочего времени
cat > src/ui/components/ScheduleSettings.js << 'SETTINGS'
/**
 * SCHEDULE SETTINGS UI
 * Интерфейс настройки рабочего времени
 */

const ScheduleSettings = {
  open: function() {
    const settings = ScheduleRules.getSettings();
    const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
    
    const content = `
      <form id="scheduleForm" onsubmit="return ScheduleSettings.save(event)">
        <label>Рабочие дни</label>
        <div class="work-days-selector">
          ${[0,1,2,3,4,5,6].map(day => `
            <label class="day-checkbox">
              <input type="checkbox" name="workDays" value="${day}" 
                ${settings.workDays.includes(day) ? 'checked' : ''}>
              <span>${dayNames[day]}</span>
            </label>
          `).join('')}
        </div>
        
        <label>Начало рабочего дня</label>
        <input type="time" id="workStart" value="${settings.workStart}" required>
        
        <label>Конец рабочего дня</label>
        <input type="time" id="workEnd" value="${settings.workEnd}" required>
        
        <label class="checkbox-label">
          <input type="checkbox" id="lunchEnabled" 
            ${settings.lunchBreak.enabled ? 'checked' : ''}
            onchange="document.getElementById('lunchSettings').style.display = this.checked ? 'block' : 'none'">
          <span>Обеденный перерыв</span>
        </label>
        
        <div id="lunchSettings" style="display: ${settings.lunchBreak.enabled ? 'block' : 'none'}">
          <label>Начало обеда</label>
          <input type="time" id="lunchStart" value="${settings.lunchBreak.start}">
          
          <label>Конец обеда</label>
          <input type="time" id="lunchEnd" value="${settings.lunchBreak.end}">
        </div>
        
        <label>Буфер между записями (минут)</label>
        <input type="number" id="bufferTime" value="${settings.bufferTime}" min="0" max="60">
        
        <label>Максимум записей в день</label>
        <input type="number" id="maxBookings" value="${settings.maxBookingsPerDay}" min="1" max="20">
        
        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="Modal.close()">Отмена</button>
        </div>
      </form>
    `;
    
    Modal.form({ title: '⚙️ Настройки рабочего времени', content });
  },

  save: function(e) {
    e.preventDefault();
    
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
      maxBookingsPerDay: parseInt(document.getElementById('maxBookings').value)
    };
    
    ScheduleRules.saveSettings(settings);
    Modal.close();
    Modal.alert('✅ Настройки сохранены!');
    
    return false;
  }
};

window.ScheduleSettings = ScheduleSettings;
SETTINGS

echo "✅ ScheduleSettings.js создан"

# 4. Добавляем в index.html
sed -i '/<script src="src\/ui\/components\/FamilySelect.js"><\/script>/a \  <script src="src/ui/components/ScheduleSettings.js"></script>' index.html

# 5. Интегрируем проверку в форму добавления записей
cat >> app.js << 'INTEGRATION'

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
INTEGRATION

echo "✅ Интеграция проверки добавлена"

# 6. Добавляем кнопку настроек в интерфейс
cat >> styles/main.css << 'STYLES'
/* Стили для настроек расписания */
.work-days-selector {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 8px;
  margin: 10px 0;
}

.day-checkbox {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 10px;
  background: var(--bg-secondary, #f5f5f5);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
}

.day-checkbox input[type="checkbox"] {
  margin-bottom: 5px;
}

.day-checkbox:hover {
  background: var(--accent, #ff6b9d);
  color: white;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 10px 0;
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  width: 20px;
  height: 20px;
}
STYLES

echo "✅ Стили добавлены"

# 7. Добавляем кнопку настроек в шапку вкладки Работа
sed -i 's|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>\n          <button class="tab-action-btn" onclick="ScheduleSettings.open()">⚙️ Настройки</button>|' index.html

echo "✅ Кнопка настроек добавлена"

# 8. Git commit + push + сборка APK
echo ""
echo " Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлена система рабочего времени и правил расписания"
git push origin main

# Сборка APK
echo "📦 Сборка APK (подожди 2-3 минуты)..."
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Schedule.apk
  cd ..
  cp GdeSveta_Schedule.apk ~/storage/downloads/GdeSveta_Schedule.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🕐 СИСТЕМА РАБОЧЕГО ВРЕМЕНИ ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "✅ Настройка рабочих дней (Пн-Сб по умолчанию)"
  echo "✅ Рабочие часы (09:00-20:00 по умолчанию)"
  echo "✅ Обеденный перерыв (опционально)"
  echo "✅ Буфер между записями (10 мин)"
  echo "✅ Автоматическая блокировка записей вне рабочего времени"
  echo "✅ Предупреждения при нарушении правил"
  echo ""
  echo "📱 КАК ИСПОЛЬЗОВАТЬ:"
  echo "1. Открой вкладку 'Работа'"
  echo "2. Нажми '⚙️ Настройки' (рядом с '💰 Прайс')"
  echo "3. Настрой своё расписание"
  echo "4. Попробуй добавить запись в выходной — система заблокирует!"
  echo ""
  echo "📁 APK: ~/storage/downloads/GdeSveta_Schedule.apk"
  echo "═══════════════════════════════════════════════"
else
  echo " Ошибка сборки"
  cd ..
fi
