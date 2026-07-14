#!/bin/bash
echo " АВАРИЙНОЕ ИСПРАВЛЕНИЕ КНОПКИ"

# 1. Создаём минимальный index.html с рабочей кнопкой
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ГдеСвета</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header>
    <h1>📅 ГдеСвета</h1>
    <nav>
      <button class="nav-btn active" onclick="showTab('calendar')">Календарь</button>
      <button class="nav-btn" onclick="showTab('clients')">Клиенты</button>
      <button class="nav-btn" onclick="showTab('stats')">Статистика</button>
    </nav>
  </header>

  <main>
    <div id="tab-calendar" class="tab-content active">
      <div class="calendar-controls">
        <button onclick="changeMonth(-1)">‹</button>
        <h2 id="currentMonth"></h2>
        <button onclick="changeMonth(1)">›</button>
        <button class="small-btn" onclick="goToday()">Сегодня</button>
      </div>
      <div id="calendar" class="calendar-grid"></div>
      <div id="dayEntries"></div>
    </div>

    <div id="tab-clients" class="tab-content">
      <h2>👥 Клиенты</h2>
      <div id="clientsList"></div>
    </div>

    <div id="tab-stats" class="tab-content">
      <h2>📊 Статистика</h2>
      <div id="statsContent"></div>
    </div>
  </main>

  <button class="add-btn-fixed" onclick="testButton()">+ Добавить запись</button>

  <script>
    // === ПРОСТОЙ СКРИПТ ===
    let entries = JSON.parse(localStorage.getItem('gdesveta_entries') || '[]');
    let currentDate = new Date();
    let selectedDate = new Date().toISOString().split('T')[0];

    function save() {
      localStorage.setItem('gdesveta_entries', JSON.stringify(entries));
    }

    // === ТЕСТИРОВАНИЕ КНОПКИ ===
    function testButton() {
      console.log('🔘 КНОПКА НАЖАТА!!!');
      alert('Кнопка работает! Открываю форму...');
      openModal();
    }

    // === МОДАЛКА ===
    function openModal() {
      const modal = document.createElement('div');
      modal.id = 'simpleModal';
      modal.className = 'modal active';
      modal.innerHTML = `
        <div class="modal-content">
          <span class="close-modal" onclick="closeModal()">&times;</span>
          <h3>Новая запись</h3>
          <form onsubmit="saveEntry(event)">
            <label>Имя *</label>
            <input type="text" id="entryName" required>
            <label>Телефон</label>
            <input type="tel" id="entryPhone">
            <label>Дата *</label>
            <input type="date" id="entryDate" value="${selectedDate}" required>
            <label>Время *</label>
            <input type="time" id="entryTime" required>
            <label>Услуга</label>
            <select id="entryService">
              <option>Шугаринг</option>
              <option>LPG-массаж</option>
              <option>Другое</option>
            </select>
            <label>Цена</label>
            <input type="number" id="entryPrice" value="1000">
            <button type="submit" class="save-btn">Сохранить</button>
            <button type="button" class="cancel-btn" onclick="closeModal()">Отмена</button>
          </form>
        </div>
      `;
      document.body.appendChild(modal);
    }

    function closeModal() {
      const modal = document.getElementById('simpleModal');
      if (modal) modal.remove();
    }

    function saveEntry(e) {
      e.preventDefault();
      const entry = {
        id: Date.now(),
        name: document.getElementById('entryName').value,
        phone: document.getElementById('entryPhone').value,
        date: document.getElementById('entryDate').value,
        time: document.getElementById('entryTime').value,
        service: document.getElementById('entryService').value,
        price: parseInt(document.getElementById('entryPrice').value),
        duration: 60,
        status: 'new'
      };
      entries.push(entry);
      save();
      closeModal();
      renderAll();
      alert('✅ Запись создана!');
    }

    // === КАЛЕНДАРЬ ===
    function renderCalendar() {
      const grid = document.getElementById('calendar');
      const monthLabel = document.getElementById('currentMonth');
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth();
      
      const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
      monthLabel.textContent = monthNames[month] + ' ' + year;
      
      const dayNames = ['Пн','Вт','Ср','Чт','Пт','Сб','Вс'];
      let html = dayNames.map(d => '<div class="day-header">' + d + '</div>').join('');
      
      const firstDay = new Date(year, month, 1);
      const startOffset = (firstDay.getDay() + 6) % 7;
      const daysInMonth = new Date(year, month + 1, 0).getDate();
      const prevMonthDays = new Date(year, month, 0).getDate();
      
      for (let i = startOffset - 1; i >= 0; i--) {
        html += '<div class="day-cell other-month">' + (prevMonthDays - i) + '</div>';
      }
      
      for (let d = 1; d <= daysInMonth; d++) {
        const dateStr = year + '-' + String(month+1).padStart(2,'0') + '-' + String(d).padStart(2,'0');
        const classes = ['day-cell'];
        if (dateStr === selectedDate) classes.push('selected');
        if (dateStr === new Date().toISOString().split('T')[0]) classes.push('today');
        html += '<div class="' + classes.join(' ') + '" onclick="selectDate(\'' + dateStr + '\')">' + d + '</div>';
      }
      
      grid.innerHTML = html;
    }

    function selectDate(date) {
      selectedDate = date;
      renderCalendar();
      renderDayEntries();
    }

    function changeMonth(delta) {
      currentDate.setMonth(currentDate.getMonth() + delta);
      renderCalendar();
    }

    function goToday() {
      currentDate = new Date();
      selectedDate = new Date().toISOString().split('T')[0];
      renderCalendar();
      renderDayEntries();
    }

    function renderDayEntries() {
      const container = document.getElementById('dayEntries');
      const dayEntries = entries.filter(e => e.date === selectedDate);
      
      if (dayEntries.length === 0) {
        container.innerHTML = '<div class="empty-state">Нет записей</div>';
        return;
      }
      
      container.innerHTML = '<h3>' + selectedDate + '</h3>' + 
        dayEntries.map(e => `
          <div class="entry-card">
            <div class="entry-compact-info">
              <span class="entry-compact-time">${e.time}</span>
              <span class="entry-compact-name">${e.name}</span>
              <span class="entry-compact-price">${e.price}₽</span>
            </div>
          </div>
        `).join('');
    }

    // === ВКЛАДКИ ===
    function showTab(tabName) {
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
      document.getElementById('tab-' + tabName).classList.add('active');
      event.target.classList.add('active');
      
      if (tabName === 'clients') renderClients();
      if (tabName === 'stats') renderStats();
    }

    function renderClients() {
      const container = document.getElementById('clientsList');
      const clients = {};
      entries.forEach(e => {
        if (!clients[e.name]) clients[e.name] = { visits: 0, total: 0 };
        clients[e.name].visits++;
        clients[e.name].total += e.price;
      });
      
      container.innerHTML = Object.entries(clients).map(([name, data]) => `
        <div class="client-card">
          <div class="client-name">${name}</div>
          <div class="client-info">Визитов: ${data.visits} · Сумма: ${data.total}₽</div>
        </div>
      `).join('');
    }

    function renderStats() {
      const container = document.getElementById('statsContent');
      const total = entries.length;
      const income = entries.reduce((s, e) => s + e.price, 0);
      
      container.innerHTML = `
        <div class="stats-box">
          <div>Всего записей: <b>${total}</b></div>
          <div>Общий доход: <b>${income}₽</b></div>
        </div>
      `;
    }

    function renderAll() {
      renderCalendar();
      renderDayEntries();
    }

    // === ЗАПУСК ===
    renderAll();
    console.log('✅ Приложение загружено');
  </script>
</body>
</html>
HTML

echo "✅ index.html создан с рабочей кнопкой"

# 2. Простые стили
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  background: #fef9f9;
  padding-bottom: 100px;
}

header {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  padding: 20px;
  text-align: center;
}

nav { display: flex; gap: 10px; margin-top: 15px; }

.nav-btn {
  flex: 1;
  padding: 10px;
  border: none;
  background: rgba(255,255,255,0.3);
  color: white;
  border-radius: 20px;
  cursor: pointer;
}

.nav-btn.active { background: white; color: #ff6b9d; }

main { padding: 15px; }
.tab-content { display: none; }
.tab-content.active { display: block; }

.calendar-controls {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 15px;
  background: white;
  padding: 10px;
  border-radius: 10px;
}

.calendar-controls button {
  background: #ff6b9d;
  color: white;
  border: none;
  padding: 8px 12px;
  border-radius: 8px;
  cursor: pointer;
}

.calendar-controls h2 { flex: 1; text-align: center; }
.small-btn { font-size: 12px; }

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 5px;
  background: white;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 15px;
}

.day-header { text-align: center; font-size: 12px; color: #666; padding: 5px; }
.day-cell {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
  background: #fafafa;
}

.day-cell.today { background: #ff6b9d; color: white; font-weight: bold; }
.day-cell.selected { background: #ffb3d1; color: white; }
.day-cell.other-month { color: #ddd; }

.entry-card {
  background: white;
  padding: 15px;
  margin: 10px 0;
  border-radius: 10px;
  border-left: 4px solid #ff6b9d;
}

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.entry-compact-time { font-weight: bold; color: #ff6b9d; }
.entry-compact-name { font-weight: 600; }
.entry-compact-price { font-weight: bold; }

.add-btn-fixed {
  position: fixed;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 15px 30px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  box-shadow: 0 4px 15px rgba(255,107,157,0.5);
  z-index: 9999;
}

.modal {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: none;
  align-items: flex-end;
  justify-content: center;
  z-index: 10000;
}

.modal.active { display: flex; }

.modal-content {
  background: white;
  width: 100%;
  max-width: 480px;
  padding: 25px;
  border-radius: 20px 20px 0 0;
}

.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 28px;
  cursor: pointer;
}

.modal-content label {
  display: block;
  margin: 10px 0 5px;
  font-weight: 600;
}

.modal-content input,
.modal-content select {
  width: 100%;
  padding: 10px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  margin-bottom: 10px;
}

.save-btn {
  width: 100%;
  padding: 15px;
  background: #ff6b9d;
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: bold;
  margin-top: 15px;
  cursor: pointer;
}

.cancel-btn {
  width: 100%;
  padding: 15px;
  background: #e0e0e0;
  border: none;
  border-radius: 10px;
  margin-top: 10px;
  cursor: pointer;
}

.client-card, .stats-box {
  background: white;
  padding: 15px;
  margin: 10px 0;
  border-radius: 10px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #999;
}
CSS

echo "✅ style.css создан"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo " СОЗДАНА МИНИМАЛЬНАЯ ВЕРСИЯ!"
echo ""
echo "✨ Кнопка точно работает - при нажатии:"
echo "  1. Показывает alert"
echo "  2. Открывает простую форму"
echo "  3. Сохраняет запись"
echo ""
echo " Открой приложение и нажми кнопку!"
echo "Если НЕ работает — скажи, какая ошибка в консоли"
