#!/bin/bash
echo "📅 ДОБАВЛЯЮ ПОВТОРЯЮЩИЕСЯ СОБЫТИЯ С ДАТАМИ..."

# 1. Создаём сервис повторяющихся событий
cat > src/services/RecurringService.js << 'RECURRING'
/**
 * RECURRING SERVICE
 * Управление повторяющимися событиями
 */

const RecurringService = {
  // Типы повторений
  repeatTypes: {
    daily: { label: 'Ежедневно', value: 'daily' },
    weekdays: { label: 'По будням (Пн-Пт)', value: 'weekdays' },
    weekly: { label: 'Еженедельно', value: 'weekly' },
    monthly: { label: 'Ежемесячно', value: 'monthly' }
  },

  // Создать повторяющееся событие
  create: function(data) {
    const recurring = {
      id: Utils.generateId(),
      name: data.name,
      service: data.service,
      time: data.time,
      duration: data.duration,
      category: data.category,
      repeatType: data.repeatType,
      startDate: data.startDate,
      endDate: data.endDate,
      daysOfWeek: data.daysOfWeek || [], // для weekly: [1,3,5] = Пн,Ср,Пт
      excludeDates: data.excludeDates || [], // праздники, каникулы
      price: data.price || 0,
      notes: data.notes || '',
      createdAt: new Date().toISOString()
    };

    // Сохраняем в специальное хранилище
    const recurringList = JSON.parse(Storage.get('recurringEvents', '[]'));
    recurringList.push(recurring);
    Storage.set('recurringEvents', JSON.stringify(recurringList));

    // Генерируем события до указанной даты
    this.generateEvents(recurring);

    return recurring;
  },

  // Сгенерировать события из шаблона
  generateEvents: function(recurring) {
    const start = new Date(recurring.startDate);
    const end = new Date(recurring.endDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let currentDate = new Date(start);
    const generatedEntries = [];

    while (currentDate <= end) {
      const dateStr = currentDate.toISOString().split('T')[0];
      const dayOfWeek = currentDate.getDay();

      // Проверяем, подходит ли день
      let shouldCreate = false;

      switch (recurring.repeatType) {
        case 'daily':
          shouldCreate = true;
          break;
        case 'weekdays':
          shouldCreate = dayOfWeek >= 1 && dayOfWeek <= 5; // Пн-Пт
          break;
        case 'weekly':
          shouldCreate = recurring.daysOfWeek.includes(dayOfWeek);
          break;
        case 'monthly':
          shouldCreate = currentDate.getDate() === start.getDate();
          break;
      }

      // Проверяем, не исключена ли дата
      const isExcluded = recurring.excludeDates.some(exclude => {
        const excludeDate = new Date(exclude).toISOString().split('T')[0];
        return excludeDate === dateStr;
      });

      // Создаём событие если нужно и дата не в прошлом
      if (shouldCreate && !isExcluded && currentDate >= today) {
        const entry = {
          id: Utils.generateId(),
          name: recurring.name,
          service: recurring.service,
          category: recurring.category,
          date: dateStr,
          time: recurring.time,
          duration: recurring.duration,
          price: recurring.price,
          notes: recurring.notes + ' (повторяющееся)',
          status: 'new',
          recurringId: recurring.id,
          createdAt: new Date().toISOString()
        };

        // Проверяем, нет ли уже такого события
        const exists = Store.getEntries().some(e => 
          e.date === entry.date && 
          e.time === entry.time && 
          e.recurringId === recurring.id
        );

        if (!exists) {
          Store.addEntry(entry);
          generatedEntries.push(entry);
        }
      }

      // Переходим к следующему дню
      currentDate.setDate(currentDate.getDate() + 1);
    }

    Events.emit('entry:created', generatedEntries);
    return generatedEntries;
  },

  // Получить все повторяющиеся шаблоны
  getAll: function() {
    return JSON.parse(Storage.get('recurringEvents', '[]'));
  },

  // Удалить шаблон и все связанные события
  delete: function(id) {
    const recurringList = this.getAll();
    const filtered = recurringList.filter(r => r.id !== id);
    Storage.set('recurringEvents', JSON.stringify(filtered));

    // Удаляем все события этого шаблона
    const entries = Store.getEntries();
    const filteredEntries = entries.filter(e => e.recurringId !== id);
    Storage.set('entries', JSON.stringify(filteredEntries));

    Events.emit('entry:deleted', id);
  },

  // Обновить шаблон
  update: function(id, data) {
    const recurringList = this.getAll();
    const index = recurringList.findIndex(r => r.id === id);
    
    if (index !== -1) {
      recurringList[index] = { ...recurringList[index], ...data };
      Storage.set('recurringEvents', JSON.stringify(recurringList));
      
      // Перегенерируем события
      this.generateEvents(recurringList[index]);
      
      Events.emit('entry:updated', id);
    }
  }
};

window.RecurringService = RecurringService;
console.log('✅ RecurringService загружен');
RECURRING

echo "✅ RecurringService.js создан"

# 2. Добавляем в index.html
sed -i '/<script src="src\/services\/DogService.js"><\/script>/a \  <script src="src/services/RecurringService.js"></script>' index.html

# 3. Добавляем форму создания повторяющегося события в app.js
cat >> app.js << 'RECURRINGFORM'

// === ФОРМА ПОВТОРЯЮЩЕГОСЯ СОБЫТИЯ ===

window.openRecurringForm = function() {
  const repeatOptions = Object.entries(RecurringService.repeatTypes).map(([key, val]) => 
    `<option value="${val.value}">${val.label}</option>`
  ).join('');

  const content = `
    <form id="recurringForm" onsubmit="return saveRecurringEvent(event)">
      <label>Название события *</label>
      <input type="text" id="recurringName" placeholder="Напр. Школа, Кружок Танцы" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Категория</label>
      <select id="recurringCategory"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        <option value="family">👨‍👩‍👧 Семья</option>
        <option value="work">💼 Работа</option>
        <option value="dog">🐕 Собака</option>
      </select>

      <label>Тип услуги / события</label>
      <input type="text" id="recurringService" placeholder="Напр. Школа №5, Танцы"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Время *</label>
      <input type="time" id="recurringTime" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Длительность (минут) *</label>
      <input type="number" id="recurringDuration" value="60" min="10" max="480" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Тип повторения *</label>
      <select id="recurringType" required onchange="toggleDaysOfWeek()"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        ${repeatOptions}
      </select>

      <div id="daysOfWeekSelector" style="display:none;margin-bottom:15px;">
        <label>Дни недели:</label>
        <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-top:5px;">
          ${['Вс','Пн','Вт','Ср','Чт','Пт','Сб'].map((day, idx) => `
            <label style="display:flex;flex-direction:column;align-items:center;padding:8px;background:#f5f5f5;border-radius:8px;cursor:pointer;">
              <input type="checkbox" class="day-checkbox" value="${idx}" style="margin-bottom:5px;">
              <span style="font-size:12px;">${day}</span>
            </label>
          `).join('')}
        </div>
      </div>

      <label>Дата начала *</label>
      <input type="date" id="recurringStartDate" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>Дата окончания *</label>
      <input type="date" id="recurringEndDate" required
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>💰 Стоимость (за одно событие)</label>
      <input type="number" id="recurringPrice" placeholder="Напр. 1500" min="0"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">

      <label>💬 Примечания</label>
      <textarea id="recurringNotes" placeholder="Напр. С собой форма, пропуск" rows="2"
        style="width:100%;padding:12px;margin:5px 0 15px 0;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;"></textarea>

      <div style="background:#e0f2fe;padding:12px;border-radius:10px;margin:15px 0;font-size:14px;">
        💡 <b>Совет:</b> Система автоматически создаст события до указанной даты.
        Можно исключить праздники и каникулы вручную.
      </div>

      <div style="display:flex;gap:10px;margin-top:20px;">
        <button type="submit"
          style="flex:1;padding:15px;background:linear-gradient(135deg,#8b5cf6,#a78bfa);color:white;border:none;border-radius:12px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(139,92,246,0.4);">
          📅 Создать повторяющееся событие
        </button>
        <button type="button" onclick="Modal.close()"
          style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;cursor:pointer;">
          Отмена
        </button>
      </div>
    </form>
  `;

  Modal.form({ title: '📅 Повторяющееся событие', content });

  // Установить сегодняшнюю дату
  setTimeout(() => {
    document.getElementById('recurringStartDate').value = new Date().toISOString().split('T')[0];
    const nextMonth = new Date();
    nextMonth.setMonth(nextMonth.getMonth() + 1);
    document.getElementById('recurringEndDate').value = nextMonth.toISOString().split('T')[0];
  }, 100);
};

// Переключение селектора дней недели
window.toggleDaysOfWeek = function() {
  const type = document.getElementById('recurringType').value;
  const selector = document.getElementById('daysOfWeekSelector');
  if (selector) {
    selector.style.display = type === 'weekly' ? 'block' : 'none';
  }
};

// Сохранение повторяющегося события
window.saveRecurringEvent = function(e) {
  e.preventDefault();

  const daysOfWeek = Array.from(document.querySelectorAll('.day-checkbox:checked')).map(cb => parseInt(cb.value));

  const data = {
    name: document.getElementById('recurringName').value,
    category: document.getElementById('recurringCategory').value,
    service: document.getElementById('recurringService').value,
    time: document.getElementById('recurringTime').value,
    duration: parseInt(document.getElementById('recurringDuration').value),
    repeatType: document.getElementById('recurringType').value,
    daysOfWeek: daysOfWeek,
    startDate: document.getElementById('recurringStartDate').value,
    endDate: document.getElementById('recurringEndDate').value,
    price: parseInt(document.getElementById('recurringPrice').value || 0),
    notes: document.getElementById('recurringNotes').value
  };

  RecurringService.create(data);
  Modal.close();
  Modal.alert('✅ Повторяющееся событие создано!\n\nСобытия автоматически добавлены в календарь.');
  setTimeout(() => {
    if (typeof CalendarView !== 'undefined') CalendarView.render();
    if (typeof WorkView !== 'undefined') WorkView.render();
    if (typeof FamilyView !== 'undefined') FamilyView.render();
  }, 200);

  return false;
};

console.log('✅ Функции повторяющихся событий загружены');
RECURRINGFORM

echo "✅ Форма повторяющихся событий добавлена"

# 4. Добавляем кнопку в интерфейс (в календарь или работу)
sed -i 's|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>|<button class="tab-action-btn" onclick="showPriceList()">💰 Прайс</button>\n          <button class="tab-action-btn" onclick="openRecurringForm()" style="background:#8b5cf6;color:white;border:none;padding:12px 20px;border-radius:10px;font-weight:600;cursor:pointer;"> Повтор</button>|' index.html

echo "✅ Кнопка 'Повтор' добавлена"

# Git + сборка
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлены повторяющиеся события с датами (школа, кружки)"
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_Recurring.apk
  cd ..
  cp GdeSveta_Recurring.apk ~/storage/downloads/GdeSveta_Recurring.apk 2>/dev/null

  echo ""
  echo "═══════════════════════════════════════════════"
  echo "📅 ПОВТОРЯЮЩИЕСЯ СОБЫТИЯ ГОТОВЫ!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_Recurring.apk"
  echo ""
  echo "✅ ЧТО ДОБАВЛЕНО:"
  echo "• Кнопка '📅 Повтор' во вкладке Работа"
  echo "• Типы повторений:"
  echo "  - Ежедневно"
  echo "  - По будням (Пн-Пт)"
  echo "  - Еженедельно (выбор дней)"
  echo "  - Ежемесячно"
  echo "• Дата начала и окончания"
  echo "• Автоматическое создание событий"
  echo "• Примеры:"
  echo "  • Школа: Пн-Пт, 08:00, с 1 сен по 25 мая"
  echo "  • Танцы: Вт и Чт, 16:00, весь год"
  echo ""
  echo "📱 ТЕСТИРОВАНИЕ:"
  echo "1. Установи GdeSveta_Recurring.apk"
  echo "2. Открой вкладку 'Работа'"
  echo "3. Нажми '📅 Повтор'"
  echo "4. Заполни:"
  echo "   - Название: 'Школа'"
  echo "   - Тип: 'По будням (Пн-Пт)'"
  echo "   - Время: 08:00"
  echo "   - Дата начала: 01.09.2026"
  echo "   - Дата окончания: 25.05.2027"
  echo "5. Сохрани — события создадутся автоматически!"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
