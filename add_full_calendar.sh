#!/bin/bash
echo "📅 ДОБАВЛЯЮ ПОЛНОЦЕННЫЙ КАЛЕНДАРЬ..."

# 1. Создаём полноценный CalendarView
cat > src/views/CalendarView.js << 'CALENDARVIEW'
const CalendarView = {
  currentDate: new Date(),
  
  render: function() {
    const container = document.getElementById('calendarView');
    if (!container) return;
    
    const year = this.currentDate.getFullYear();
    const month = this.currentDate.getMonth();
    const today = new Date();
    
    const monthNames = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
    const dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    
    // Первый день месяца
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    
    // Смещение (понедельник = 0)
    let startDay = firstDay.getDay() - 1;
    if (startDay < 0) startDay = 6;
    
    let html = '<div style="padding:20px;">';
    
    // Навигация по месяцам
    html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">';
    html += '<button onclick="CalendarView.prevMonth()" style="padding:8px 16px;background:#f0f0f0;border:none;border-radius:8px;cursor:pointer;font-size:18px;">‹</button>';
    html += '<h3 style="margin:0;color:#1e293b;">' + monthNames[month] + ' ' + year + '</h3>';
    html += '<button onclick="CalendarView.nextMonth()" style="padding:8px 16px;background:#f0f0f0;border:none;border-radius:8px;cursor:pointer;font-size:18px;">›</button>';
    html += '</div>';
    
    // Сетка дней недели
    html += '<div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:10px;">';
    dayNames.forEach(day => {
      html += '<div style="text-align:center;font-size:12px;color:#94a3b8;font-weight:600;">' + day + '</div>';
    });
    html += '</div>';
    
    // Сетка дней
    html += '<div style="display:grid;grid-template-columns:repeat(7,1fr);gap:8px;">';
    
    // Пустые ячейки до первого дня
    for (let i = 0; i < startDay; i++) {
      html += '<div></div>';
    }
    
    // Дни месяца
    for (let day = 1; day <= daysInMonth; day++) {
      const date = new Date(year, month, day);
      const dateStr = date.toISOString().split('T')[0];
      const isToday = date.toDateString() === today.toDateString();
      
      // Проверяем есть ли записи на этот день
      const dayEntries = Store.getEntries().filter(e => e.date === dateStr);
      const hasEntries = dayEntries.length > 0;
      
      let style = 'text-align:center;padding:12px 8px;border-radius:12px;cursor:pointer;transition:all 0.2s;';
      
      if (isToday) {
        style += 'background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;font-weight:700;';
      } else if (hasEntries) {
        style += 'background:#fff0f3;color:#ff6b9d;font-weight:600;';
      } else {
        style += 'background:#f8fafc;color:#1e293b;';
      }
      
      html += '<div onclick="CalendarView.selectDate(\'' + dateStr + '\')" style="' + style + '">';
      html += day;
      if (hasEntries) {
        html += '<div style="font-size:10px;margin-top:4px;">' + dayEntries.length + ' зап.</div>';
      }
      html += '</div>';
    }
    
    html += '</div></div>';
    
    container.innerHTML = html;
    console.log('✅ CalendarView отрисован');
  },
  
  prevMonth: function() {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1);
    this.render();
  },
  
  nextMonth: function() {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1);
    this.render();
  },
  
  selectDate: function(dateStr) {
    console.log('📅 Выбрана дата:', dateStr);
    // Открываем форму добавления с выбранной датой
    if (typeof window.openWorkForm === 'function') {
      window.openWorkForm(null, dateStr);
    }
  }
};

window.CalendarView = CalendarView;
console.log('✅ CalendarView загружен');
CALENDARVIEW

echo "✅ CalendarView.js создан"

# 2. Создаём форму добавления записей
cat >> app.js << 'WORKFORM'

// === ФОРМА ДОБАВЛЕНИЯ ЗАПИСИ ===
window.openWorkForm = function(entryId = null, presetDate = null) {
  console.log('📝 Открытие формы записи');
  
  const isEdit = entryId !== null;
  let entry = null;
  
  if (isEdit) {
    entry = Store.getEntries().find(e => e.id === entryId);
  }
  
  const dateValue = presetDate || (entry ? entry.date : new Date().toISOString().split('T')[0]);
  const timeValue = entry ? entry.time : '10:00';
  const durationValue = entry ? entry.duration : 60;
  const nameValue = entry ? entry.name : '';
  const serviceValue = entry ? entry.service : '';
  const priceValue = entry ? entry.price : '';
  const phoneValue = entry ? entry.phone : '';
  const notesValue = entry ? entry.notes : '';
  
  const html = `
    <div style="padding:20px;">
      <h3 style="margin:0 0 20px 0;color:#1e293b;">${isEdit ? '✏️ Редактировать запись' : '➕ Новая запись'}</h3>
      
      <form id="workEntryForm" onsubmit="return saveWorkEntry(event, ${entryId})">
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Имя клиента *</label>
        <input type="text" id="entryName" value="${nameValue}" required 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Телефон</label>
        <input type="tel" id="entryPhone" value="${phoneValue}" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:15px;">
          <div>
            <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Дата *</label>
            <input type="date" id="entryDate" value="${dateValue}" required 
              style="width:100%;padding:12px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
          </div>
          <div>
            <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Время *</label>
            <input type="time" id="entryTime" value="${timeValue}" required 
              style="width:100%;padding:12px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
          </div>
        </div>
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Длительность (мин) *</label>
        <input type="number" id="entryDuration" value="${durationValue}" min="15" max="480" required 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Услуга</label>
        <input type="text" id="entryService" value="${serviceValue}" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Цена (₽)</label>
        <input type="number" id="entryPrice" value="${priceValue}" min="0" 
          style="width:100%;padding:12px;margin-bottom:15px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">
        
        <label style="display:block;margin-bottom:5px;font-weight:600;color:#1e293b;">Заметки</label>
        <textarea id="entryNotes" rows="3" 
          style="width:100%;padding:12px;margin-bottom:20px;border:2px solid #e0e0e0;border-radius:10px;font-size:16px;">${notesValue}</textarea>
        
        <div style="display:flex;gap:10px;">
          <button type="submit" 
            style="flex:1;padding:15px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
            💾 Сохранить
          </button>
          <button type="button" onclick="closeModal()" 
            style="flex:1;padding:15px;background:#e0e0e0;color:#333;border:none;border-radius:12px;font-weight:700;font-size:16px;cursor:pointer;">
            Отмена
          </button>
        </div>
      </form>
    </div>
  `;
  
  showModal(html);
};

// Сохранение записи
window.saveWorkEntry = function(e, entryId) {
  e.preventDefault();
  console.log('💾 Сохранение записи...');
  
  const entryData = {
    name: document.getElementById('entryName').value,
    phone: document.getElementById('entryPhone').value,
    date: document.getElementById('entryDate').value,
    time: document.getElementById('entryTime').value,
    duration: parseInt(document.getElementById('entryDuration').value),
    service: document.getElementById('entryService').value,
    price: parseInt(document.getElementById('entryPrice').value) || 0,
    notes: document.getElementById('entryNotes').value,
    category: 'work',
    status: 'new'
  };
  
  if (entryId) {
    // Редактирование
    Store.updateEntry(entryId, entryData);
    console.log('✅ Запись обновлена:', entryId);
  } else {
    // Новая запись
    Store.addEntry(entryData);
    console.log('✅ Запись создана');
  }
  
  closeModal();
  
  // Обновляем текущую вкладку
  setTimeout(() => {
    const currentTab = AppState.currentTab;
    if (currentTab === 'calendar') {
      CalendarView.render();
    } else if (currentTab === 'work') {
      WorkView.render();
    }
  }, 200);
  
  return false;
};

// Модальное окно
window.showModal = function(content) {
  const modal = document.createElement('div');
  modal.id = 'modalOverlay';
  modal.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:2000;display:flex;align-items:center;justify-content:center;padding:20px;';
  
  const modalContent = document.createElement('div');
  modalContent.style.cssText = 'background:white;border-radius:20px;max-width:500px;width:100%;max-height:90vh;overflow-y:auto;box-shadow:0 10px 40px rgba(0,0,0,0.3);';
  modalContent.innerHTML = content;
  
  modal.appendChild(modalContent);
  document.body.appendChild(modal);
  
  modal.addEventListener('click', function(e) {
    if (e.target === modal) {
      closeModal();
    }
  });
};

window.closeModal = function() {
  const modal = document.getElementById('modalOverlay');
  if (modal) {
    modal.remove();
  }
};

console.log('✅ Форма добавления записей загружена');
WORKFORM

echo "✅ Форма добавления создана"

# 3. Обновляем WorkView для отображения записей
cat > src/views/WorkView.js << 'WORKVIEW'
const WorkView = {
  render: function() {
    const container = document.getElementById('workView');
    if (!container) return;
    
    const entries = Store.getEntries().filter(e => e.category === 'work');
    
    let html = '<div style="padding:20px;">';
    html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">';
    html += '<h3 style="margin:0;color:#1e293b;">💼 Работа</h3>';
    html += '<button onclick="openWorkForm()" style="padding:10px 20px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">+ Добавить</button>';
    html += '</div>';
    
    if (entries.length === 0) {
      html += '<div style="background:#f8fafc;padding:40px;border-radius:16px;text-align:center;">';
      html += '<p style="color:#94a3b8;margin:0;">Нет записей</p>';
      html += '<button onclick="openWorkForm()" style="margin-top:15px;padding:12px 30px;background:linear-gradient(135deg,#ff6b9d,#ff8e53);color:white;border:none;border-radius:12px;font-weight:600;cursor:pointer;">+ Добавить первую запись</button>';
      html += '</div>';
    } else {
      html += '<div style="display:flex;flex-direction:column;gap:12px;">';
      entries.forEach(entry => {
        html += '<div style="background:white;padding:16px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);border-left:4px solid #ff6b9d;">';
        html += '<div style="display:flex;justify-content:space-between;align-items:center;">';
        html += '<div style="flex:1;">';
        html += '<div style="font-weight:600;color:#1e293b;margin-bottom:5px;">' + (entry.name || 'Клиент') + '</div>';
        html += '<div style="font-size:13px;color:#64748b;">📅 ' + entry.date + ' • ⏰ ' + entry.time + ' • ' + entry.duration + ' мин</div>';
        if (entry.service) {
          html += '<div style="font-size:13px;color:#64748b;margin-top:3px;">💅 ' + entry.service + '</div>';
        }
        html += '</div>';
        if (entry.price) {
          html += '<div style="font-weight:700;color:#ff6b9d;font-size:18px;">' + entry.price + '₽</div>';
        }
        html += '</div>';
        html += '<div style="display:flex;gap:8px;margin-top:12px;">';
        html += '<button onclick="openWorkForm(' + entry.id + ')" style="padding:6px 12px;background:#3b82f6;color:white;border:none;border-radius:8px;font-size:13px;cursor:pointer;">✏️ Изменить</button>';
        html += '<button onclick="deleteEntry(' + entry.id + ')" style="padding:6px 12px;background:#ef4444;color:white;border:none;border-radius:8px;font-size:13px;cursor:pointer;">🗑️ Удалить</button>';
        html += '</div>';
        html += '</div>';
      });
      html += '</div>';
    }
    
    html += '</div>';
    container.innerHTML = html;
    console.log('✅ WorkView отрисован, записей:', entries.length);
  }
};

window.WorkView = WorkView;

// Удаление записи
window.deleteEntry = function(id) {
  if (confirm('Удалить эту запись?')) {
    Store.deleteEntry(id);
    WorkView.render();
    console.log('✅ Запись удалена:', id);
  }
};

console.log('✅ WorkView загружен');
WORKVIEW

echo "✅ WorkView обновлён"

# 4. Git + сборка
echo ""
echo "🔄 Отправка на GitHub..."
git add .
git commit -m "feat: Полноценный календарь и форма добавления записей"
git push origin main

echo ""
echo "📦 Сборка APK..."
rm -rf android www node_modules
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
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_v12.apk
  cd ..
  cp GdeSveta_v12.apk ~/storage/downloads/GdeSveta_v12.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "✅ v12.0 ГОТОВА!"
  echo "═══════════════════════════════════════════════"
  echo "📁 APK: ~/storage/downloads/GdeSveta_v12.apk"
  echo ""
  echo "🎯 ЧТО ДОБАВЛЕНО:"
  echo "✅ Полноценный календарь с сеткой месяца"
  echo "✅ Навигация по месяцам (‹ ›)"
  echo "✅ Выделение сегодняшнего дня"
  echo "✅ Отметки дней с записями"
  echo "✅ Клик на дату → форма добавления"
  echo "✅ Форма добавления записи с полями:"
  echo "   - Имя клиента"
  echo "   - Телефон"
  echo "   - Дата и время"
  echo "   - Длительность"
  echo "   - Услуга"
  echo "   - Цена"
  echo "   - Заметки"
  echo "✅ Список записей во вкладке Работа"
  echo "✅ Кнопки Изменить и Удалить"
  echo ""
  echo "📱 УСТАНОВКА:"
  echo "1. Удали старое приложение"
  echo "2. Установи GdeSveta_v12.apk"
  echo "3. Проверь календарь и добавление записей"
  echo "═══════════════════════════════════════════════"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
