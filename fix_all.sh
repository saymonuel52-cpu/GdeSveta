#!/bin/bash
echo "🔨 Полная пересборка с правильной модалкой..."

# Резервные копии
cp index.html index.html.backup.final.$(date +%s)
cp app.js app.js.backup.final.$(date +%s)
echo "💾 Бэкапы созданы"

# 1. Создаём новый index.html
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета</title>
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="style.css?v=4">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <nav>
        <button class="nav-btn active" data-tab="calendar">Календарь</button>
        <button class="nav-btn" data-tab="clients">Клиенты</button>
        <button class="nav-btn" data-tab="stats">Статистика</button>
      </nav>
    </header>

    <main>
      <!-- Вкладка Календарь -->
      <div id="tab-calendar" class="tab-content active">
        <div class="calendar-controls">
          <button id="prevMonth">‹</button>
          <h2 id="currentMonth"></h2>
          <button id="nextMonth">›</button>
          <button id="todayBtn" class="small-btn">Сегодня</button>
        </div>
        <div id="calendar" class="calendar-grid"></div>
        <div class="filter-bar">
          <select id="serviceFilter">
            <option value="all">Все услуги</option>
            <option value="Шугаринг">Шугаринг</option>
            <option value="LPG-массаж">LPG-массаж</option>
            <option value="Другое">Другое</option>
          </select>
        </div>
        <div id="dayEntries"></div>
      </div>

      <!-- Вкладка Клиенты -->
      <div id="tab-clients" class="tab-content">
        <h2> Клиенты</h2>
        <div id="clientsList"></div>
      </div>

      <!-- Вкладка Статистика -->
      <div id="tab-stats" class="tab-content">
        <h2>📊 Статистика</h2>
        <div id="statsContent"></div>
        <div class="stats-actions">
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>
    </main>
  </div>

  <!-- Кнопка добавления -->
  <button id="addAppBtnFixed" class="add-btn-fixed">+ Добавить запись</button>

  <!-- МОДАЛКА (полноэкранная снизу) -->
  <div id="modal" class="modal">
    <div class="modal-content">
      <span class="close-modal">&times;</span>
      <h3 id="modalTitle">Новая запись</h3>
      
      <form id="entryForm">
        <input type="hidden" id="entryId">
        
        <label>Имя клиента *</label>
        <input type="text" id="entryName" required placeholder="Введите имя">

        <label>Телефон</label>
        <input type="tel" id="entryPhone" placeholder="+7 (999) 999-99-99">

        <label>Дата *</label>
        <input type="date" id="entryDate" required>

        <label>Время *</label>
        <div class="time-row">
          <input type="time" id="entryTime" required>
          <button type="button" class="quick-time" data-min="0">Сейчас</button>
          <button type="button" class="quick-time" data-min="30">+30</button>
          <button type="button" class="quick-time" data-min="60">+1ч</button>
        </div>

        <label>Длительность</label>
        <div class="duration-row">
          <button type="button" class="duration-btn" data-min="30">30 мин</button>
          <button type="button" class="duration-btn active" data-min="60">1 час</button>
          <button type="button" class="duration-btn" data-min="90">1.5 часа</button>
          <button type="button" class="duration-btn" data-min="120">2 часа</button>
        </div>
        <input type="hidden" id="entryDuration" value="60">
        <div id="timeEndInfo" class="time-end-info" style="display:none"></div>

        <div id="freeSlotsContainer"></div>
        <div id="conflictWarning" class="conflict-warning" style="display:none"></div>

        <label>Услуга</label>
        <select id="entryService">
          <option>Шугаринг</option>
          <option>LPG-массаж</option>
          <option>Другое</option>
        </select>

        <label>Зона</label>
        <input type="text" id="entryZone" placeholder="напр. ноги, руки">

        <label>Цена (₽)</label>
        <input type="number" id="entryPrice" value="1000">

        <label>Заметки</label>
        <textarea id="entryNotes" rows="2" placeholder="Дополнительная информация"></textarea>

        <div id="statusField" style="display:none">
          <label>Статус</label>
          <select id="entryStatus">
            <option value="new">Новая</option>
            <option value="confirmed">Подтверждена</option>
            <option value="done">Выполнена</option>
            <option value="cancelled">Отменена</option>
          </select>
        </div>

        <div class="form-actions">
          <button type="submit" class="save-btn">💾 Сохранить</button>
          <button type="button" class="cancel-btn">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <script src="app.js?v=4"></script>
</body>
</html>
HTML
echo "✅ index.html создан с правильной модалкой"

# 2. Обновляем стили
cat > style.css << 'CSS'
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #f5f5f7;
  color: #333;
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
}
header {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  padding: 15px;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
header h1 { text-align: center; font-size: 20px; margin-bottom: 10px; }
nav { display: flex; gap: 5px; }
.nav-btn {
  flex: 1;
  padding: 8px;
  border: none;
  background: rgba(255,255,255,0.2);
  color: white;
  border-radius: 20px;
  font-size: 13px;
  cursor: pointer;
}
.nav-btn.active { background: white; color: #ff6b9d; font-weight: bold; }
main { padding: 15px; }
.tab-content { display: none; }
.tab-content.active { display: block; }

.calendar-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 15px;
  background: white;
  padding: 10px;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.calendar-controls button {
  background: none;
  border: none;
  font-size: 22px;
  color: #ff6b9d;
  cursor: pointer;
  padding: 5px 12px;
}
.calendar-controls h2 { font-size: 16px; flex: 1; text-align: center; }
.small-btn {
  font-size: 12px !important;
  background: #ff6b9d !important;
  color: white !important;
  border-radius: 15px !important;
  padding: 5px 10px !important;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 3px;
  background: white;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 15px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.day-header { text-align: center; font-size: 11px; color: #999; padding: 5px; font-weight: bold; }
.day-cell {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  cursor: pointer;
  font-size: 13px;
  position: relative;
}
.day-cell:hover { background: #f0f0f0; }
.day-cell.other-month { color: #ccc; }
.day-cell.today { background: #ff6b9d; color: white; font-weight: bold; }
.day-cell.selected { background: #ffb3d1; color: white; }
.day-cell.has-entries::after {
  content: '';
  position: absolute;
  bottom: 3px;
  width: 5px;
  height: 5px;
  background: #ff6b9d;
  border-radius: 50%;
}
.day-cell.today.has-entries::after { background: white; }

.filter-bar { margin-bottom: 15px; }
.filter-bar select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: white;
  font-size: 14px;
}

.entry-card {
  background: white;
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  border-left: 4px solid #ff6b9d;
}
.entry-card.status-new { border-left-color: #2196f3; }
.entry-card.status-confirmed { border-left-color: #4caf50; }
.entry-card.status-done { border-left-color: #9e9e9e; opacity: 0.7; }
.entry-card.status-cancelled { border-left-color: #f44336; opacity: 0.5; }

.entry-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; }
.entry-time { font-weight: bold; color: #ff6b9d; font-size: 15px; }
.entry-name { font-weight: 600; margin-bottom: 3px; }
.entry-details { font-size: 13px; color: #666; }
.entry-actions { display: flex; gap: 5px; margin-top: 8px; }
.entry-actions button {
  flex: 1;
  padding: 6px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
}
.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

.add-btn-fixed {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 50px;
  padding: 15px 30px;
  font-size: 16px;
  font-weight: bold;
  box-shadow: 0 4px 15px rgba(255, 107, 157, 0.5);
  cursor: pointer;
}

/* === МОДАЛКА (BOTTOM SHEET) === */
.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 10000;
  align-items: flex-end;
  justify-content: center;
}
.modal.active { display: flex; }

.modal-content {
  background: white;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  border-radius: 20px 20px 0 0;
  padding: 20px;
  overflow-y: auto;
  position: relative;
  animation: slideUp 0.3s ease;
}
@keyframes slideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

.close-modal {
  position: absolute;
  top: 15px;
  right: 20px;
  font-size: 32px;
  cursor: pointer;
  color: #999;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f5f5f5;
}

.modal-content h3 {
  margin-bottom: 15px;
  color: #333;
  font-size: 20px;
  padding-right: 40px;
}

.modal-content label {
  display: block;
  margin: 12px 0 5px;
  font-size: 14px;
  color: #666;
  font-weight: 500;
}

.modal-content input,
.modal-content select,
.modal-content textarea {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 10px;
  font-size: 15px;
  font-family: inherit;
  background: #fafafa;
}

.modal-content input:focus,
.modal-content select:focus,
.modal-content textarea:focus {
  outline: none;
  border-color: #ff6b9d;
  background: white;
}

.time-row { display: flex; gap: 5px; align-items: center; }
.time-row input { flex: 1; }
.quick-time {
  padding: 10px 12px;
  background: #f0f0f0;
  border: none;
  border-radius: 8px;
  font-size: 12px;
  cursor: pointer;
}

.duration-row { display: flex; gap: 5px; flex-wrap: wrap; margin-top: 5px; }
.duration-btn {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  background: white;
  cursor: pointer;
  font-size: 13px;
}
.duration-btn.active { background: #ff6b9d; color: white; border-color: #ff6b9d; }

.time-end-info {
  background: #fff3e0;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 13px;
  color: #e65100;
  margin-top: 8px;
}

.free-slots {
  background: #e8f5e9;
  padding: 10px;
  border-radius: 8px;
  margin-top: 10px;
  font-size: 13px;
}
.free-slots-title { font-weight: bold; color: #388e3c; margin-bottom: 5px; }
.free-slot-btn {
  display: inline-block;
  padding: 5px 10px;
  margin: 2px;
  background: white;
  border: 1px solid #4caf50;
  border-radius: 15px;
  color: #388e3c;
  font-size: 12px;
  cursor: pointer;
}

.conflict-warning {
  background: #ffebee;
  border-left: 4px solid #f44336;
  padding: 10px;
  border-radius: 6px;
  margin-top: 10px;
  color: #c62828;
  font-size: 13px;
}

.status-badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: bold;
  margin-left: 8px;
}
.status-new { background: #e3f2fd; color: #1976d2; }
.status-confirmed { background: #e8f5e9; color: #388e3c; }
.status-done { background: #f5f5f5; color: #616161; }
.status-cancelled { background: #ffebee; color: #d32f2f; }

.status-buttons { display: flex; gap: 4px; margin-top: 8px; flex-wrap: wrap; }
.status-btn {
  flex: 1;
  min-width: 70px;
  padding: 6px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 11px;
  background: white;
  cursor: pointer;
}
.status-btn.active { background: #ff6b9d; color: white; border-color: #ff6b9d; }

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  padding-bottom: 20px;
}
.save-btn {
  flex: 2;
  padding: 14px;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: bold;
  font-size: 16px;
  cursor: pointer;
}
.cancel-btn {
  flex: 1;
  padding: 14px;
  background: #f0f0f0;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  cursor: pointer;
}

.client-card {
  background: white;
  padding: 12px;
  margin-bottom: 8px;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.client-name { font-weight: bold; font-size: 15px; }
.client-info { font-size: 13px; color: #666; margin-top: 3px; }

.stats-box {
  background: white;
  padding: 15px;
  margin-bottom: 10px;
  border-radius: 10px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 6px 0;
  border-bottom: 1px solid #f0f0f0;
}
.stat-row:last-child { border: none; }
.stat-label { color: #666; font-size: 14px; }
.stat-value { font-weight: bold; color: #333; }

.stats-actions { display: flex; gap: 10px; margin-top: 15px; }
.action-btn {
  flex: 1;
  padding: 12px;
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
}

.empty-state { text-align: center; padding: 30px; color: #999; }
CSS
echo "✅ style.css обновлён"

# 3. Перезапуск сервера
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# 4. Открываем браузер
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "🌐 Браузер открыт!"
else
  echo " Открой вручную: http://localhost:8000"
fi

echo ""
echo "✅ ГОТОВО!"
echo "✨ Теперь модалка должна открываться снизу"
echo "✨ Закрывай браузер и открой заново (полная перезагрузка)"
