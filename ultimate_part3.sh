#!/bin/bash
echo "🎨 Добавляем стили..."

# 3. Создаём стили с тёмной темой
cat > style.css << 'CSSEOF'
* { margin: 0; padding: 0; box-sizing: border-box; }

:root {
  --primary: #ff6b9d;
  --primary-light: #ff8e53;
  --bg: #fef9f9;
  --surface: white;
  --text: #333;
  --text-secondary: #666;
  --border: #e0e0e0;
  --shadow: rgba(0,0,0,0.05);
}

body.dark-theme {
  --bg: #1a1a2e;
  --surface: #16213e;
  --text: #eaeaea;
  --text-secondary: #b0b0b0;
  --border: #2d3561;
  --shadow: rgba(0,0,0,0.3);
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  padding-bottom: 100px;
  max-width: 480px;
  margin: 0 auto;
  min-height: 100vh;
  transition: background 0.3s, color 0.3s;
}

header {
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
  color: white;
  padding: 20px 15px;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 4px 20px rgba(255, 107, 157, 0.3);
  border-radius: 0 0 20px 20px;
}

header h1 {
  text-align: center;
  font-size: 22px;
  margin-bottom: 12px;
  font-weight: 700;
  letter-spacing: 0.5px;
}

nav { display: flex; gap: 8px; }

.nav-btn {
  flex: 1;
  padding: 10px 8px;
  border: none;
  background: rgba(255,255,255,0.25);
  color: white;
  border-radius: 25px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.nav-btn.active {
  background: white;
  color: var(--primary);
  font-weight: 700;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

main { padding: 15px; }
.tab-content { display: none; animation: fadeIn 0.3s ease; }
.tab-content.active { display: block; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* === ПОИСК === */
.search-bar { margin-bottom: 15px; }
.search-bar input, .search-input {
  width: 100%;
  padding: 12px 15px;
  border: 2px solid var(--border);
  border-radius: 12px;
  font-size: 15px;
  background: var(--surface);
  color: var(--text);
}

/* === КАЛЕНДАРЬ === */
.calendar-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 15px;
  background: var(--surface);
  padding: 12px;
  border-radius: 15px;
  box-shadow: 0 2px 10px var(--shadow);
}

.calendar-controls button {
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  border: none;
  font-size: 18px;
  color: white;
  cursor: pointer;
  padding: 8px 14px;
  border-radius: 10px;
  font-weight: bold;
}

.calendar-controls h2 {
  font-size: 17px;
  flex: 1;
  text-align: center;
  font-weight: 600;
  color: var(--text);
}

.small-btn { font-size: 12px !important; padding: 6px 12px !important; }

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  background: var(--surface);
  padding: 12px;
  border-radius: 15px;
  margin-bottom: 15px;
  box-shadow: 0 2px 10px var(--shadow);
}

.day-header {
  text-align: center;
  font-size: 11px;
  color: var(--text-secondary);
  padding: 8px 5px;
  font-weight: 600;
}

.day-cell {
  aspect-ratio: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  cursor: pointer;
  font-size: 14px;
  position: relative;
  transition: all 0.2s ease;
  font-weight: 500;
  color: var(--text);
}

.day-cell:active { transform: scale(0.9); }
.day-cell.other-month { color: #ddd; }
.day-cell.weekend { background: #fff5f7; }
body.dark-theme .day-cell.weekend { background: #2d3561; }

.day-cell.today {
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  font-weight: 700;
  box-shadow: 0 2px 8px rgba(255, 107, 157, 0.4);
}

.day-cell.selected {
  background: #ffb3d1;
  color: white;
  font-weight: 700;
}

.day-cell.load-low { background: #fff5f7; }
.day-cell.load-medium { background: #ffe0e8; }
.day-cell.load-high { background: #ffb3c7; color: #333; }
.day-cell.load-full { 
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  font-weight: 700;
}

.day-cell.today.load-low,
.day-cell.today.load-medium,
.day-cell.today.load-high,
.day-cell.today.load-full {
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
}

.load-indicator {
  display: flex;
  gap: 2px;
  margin-top: 3px;
  position: absolute;
  bottom: 4px;
}

.load-dot {
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: var(--primary);
}

.day-cell.today .load-dot,
.day-cell.load-full .load-dot { background: white; }

.load-percent {
  position: absolute;
  top: 2px;
  right: 3px;
  font-size: 8px;
  color: var(--primary);
  font-weight: 700;
}

.day-cell.today .load-percent,
.day-cell.load-full .load-percent { color: white; }

.income-label {
  position: absolute;
  bottom: 2px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 7px;
  color: var(--primary);
  font-weight: 700;
}

/* === ФИЛЬТР === */
.filter-bar { margin-bottom: 15px; }
.filter-bar select {
  width: 100%;
  padding: 12px;
  border: 2px solid var(--border);
  border-radius: 12px;
  background: var(--surface);
  color: var(--text);
  font-size: 14px;
}

/* === ЗАПИСИ === */
.entry-card {
  background: var(--surface);
  padding: 14px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px var(--shadow);
  border-left: 5px solid var(--primary);
  cursor: pointer;
  transition: all 0.3s ease;
  color: var(--text);
}

.entry-card:active { transform: scale(0.98); }

.entry-card.status-new { border-left-color: #2196f3; }
.entry-card.status-confirmed { border-left-color: #4caf50; }
.entry-card.status-done { border-left-color: #9e9e9e; opacity: 0.7; }
.entry-card.status-cancelled { border-left-color: #f44336; opacity: 0.5; }

.entry-compact-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 5px 0;
}

.entry-compact-time {
  font-weight: 700;
  font-size: 16px;
  letter-spacing: 0.5px;
}

.entry-compact-name {
  font-weight: 600;
  font-size: 15px;
  flex: 1;
  margin-left: 15px;
  color: var(--text);
}

.entry-compact-price {
  font-weight: 700;
  color: var(--text);
  font-size: 15px;
}

.expand-icon {
  margin-left: 10px;
  color: var(--text-secondary);
  font-size: 12px;
  transition: transform 0.3s;
}

.entry-card.expanded .expand-icon { transform: rotate(180deg); }

.entry-card.compact .entry-details,
.entry-card.compact .status-buttons,
.entry-card.compact .entry-actions { display: none; }

.entry-card.expanded .entry-details,
.entry-card.expanded .status-buttons,
.entry-card.expanded .entry-actions {
  display: block;
  animation: slideDown 0.3s ease;
}

@keyframes slideDown {
  from { opacity: 0; max-height: 0; }
  to { opacity: 1; max-height: 500px; }
}

.entry-details {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--border);
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
  margin-left: 8px;
}

.status-new { background: #e3f2fd; color: #1976d2; }
.status-confirmed { background: #e8f5e9; color: #388e3c; }
.status-done { background: #f5f5f5; color: #616161; }
.status-cancelled { background: #ffebee; color: #d32f2f; }

.status-buttons {
  display: flex;
  gap: 6px;
  margin-top: 12px;
  flex-wrap: wrap;
}

.status-btn {
  flex: 1;
  min-width: 70px;
  padding: 8px;
  border: 2px solid var(--border);
  border-radius: 10px;
  font-size: 12px;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
  font-weight: 500;
}

.status-btn.active {
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  border-color: var(--primary);
}

.entry-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
}

.entry-actions button {
  flex: 1;
  padding: 10px;
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
}

.btn-edit { background: #e3f2fd; color: #1976d2; }
.btn-message { background: #c8e6c9; color: #2e7d32; }
.btn-dup { background: #fff3e0; color: #f57c00; }
.btn-del { background: #ffebee; color: #d32f2f; }

/* === КНОПКА ДОБАВЛЕНИЯ === */
.add-btn-fixed {
  position: fixed;
  bottom: 25px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 9999;
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  border: none;
  border-radius: 50px;
  padding: 16px 35px;
  font-size: 17px;
  font-weight: 700;
  box-shadow: 0 6px 20px rgba(255, 107, 157, 0.5);
  cursor: pointer;
}

/* === МОДАЛКИ === */
.modal {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  z-index: 10000;
  align-items: flex-end;
  justify-content: center;
  backdrop-filter: blur(5px);
}

.modal.active { display: flex; }

.modal-content {
  background: var(--surface);
  color: var(--text);
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  border-radius: 25px 25px 0 0;
  padding: 25px 20px;
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
  font-size: 28px;
  cursor: pointer;
  color: var(--text-secondary);
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: var(--border);
}

.modal-content h3 {
  margin-bottom: 20px;
  color: var(--text);
  font-size: 22px;
  font-weight: 700;
  padding-right: 40px;
}

.modal-content label {
  display: block;
  margin: 15px 0 6px;
  font-size: 13px;
  color: var(--text-secondary);
  font-weight: 600;
}

.modal-content input,
.modal-content select,
.modal-content textarea {
  width: 100%;
  padding: 14px;
  border: 2px solid var(--border);
  border-radius: 12px;
  font-size: 15px;
  background: var(--bg);
  color: var(--text);
}

.modal-content input:focus,
.modal-content select:focus,
.modal-content textarea:focus {
  outline: none;
  border-color: var(--primary);
  background: var(--surface);
}

.time-row { display: flex; gap: 6px; align-items: center; }
.time-row input { flex: 1; }

.quick-time {
  padding: 10px 14px;
  background: var(--border);
  border: none;
  border-radius: 10px;
  font-size: 13px;
  cursor: pointer;
  font-weight: 600;
  color: var(--text);
}

.duration-row { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 8px; }

.duration-btn {
  padding: 10px 16px;
  border: 2px solid var(--border);
  border-radius: 10px;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
}

.duration-btn.active {
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  border-color: var(--primary);
}

.time-end-info {
  background: linear-gradient(135deg, #fff3e0, #ffe0b2);
  padding: 12px;
  border-radius: 12px;
  font-size: 14px;
  color: #e65100;
  margin-top: 10px;
}

.free-slots {
  background: linear-gradient(135deg, #e8f5e9, #c8e6c9);
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
}

.free-slots-title {
  font-weight: 700;
  color: #2e7d32;
  margin-bottom: 8px;
}

.free-slot-btn {
  display: inline-block;
  padding: 8px 14px;
  margin: 3px;
  background: white;
  border: 2px solid #4caf50;
  border-radius: 20px;
  color: #2e7d32;
  font-size: 13px;
  cursor: pointer;
}

.conflict-warning {
  background: linear-gradient(135deg, #ffebee, #ffcdd2);
  border-left: 4px solid #f44336;
  padding: 12px;
  border-radius: 12px;
  margin-top: 10px;
  color: #c62828;
}

.form-actions {
  display: flex;
  gap: 12px;
  margin-top: 25px;
  padding-bottom: 20px;
}

.save-btn {
  flex: 2;
  padding: 16px;
  background: linear-gradient(135deg, var(--primary), var(--primary-light));
  color: white;
  border: none;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
}

.cancel-btn {
  flex: 1;
  padding: 16px;
  background: var(--border);
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  color: var(--text);
}

/* === КЛИЕНТЫ === */
.client-card {
  background: var(--surface);
  padding: 15px;
  margin-bottom: 10px;
  border-radius: 15px;
  box-shadow: 0 2px 10px var(--shadow);
  color: var(--text);
}

.client-name {
  font-weight: 700;
  font-size: 16px;
  color: var(--text);
  margin-bottom: 5px;
}

.client-info {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

/* === СТАТИСТИКА === */
.stats-box {
  background: var(--surface);
  padding: 18px;
  margin-bottom: 12px;
  border-radius: 15px;
  box-shadow: 0 2px 10px var(--shadow);
  color: var(--text);
}

.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid var(--border);
}

.stat-row:last-child { border: none; }
.stat-label { color: var(--text-secondary); font-size: 14px; }
.stat-value { font-weight: 700; color: var(--text); font-size: 15px; }

.chart-container { margin-top: 15px; }
.chart {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  height: 150px;
  padding: 10px;
  gap: 5px;
}

.chart-bar {
  flex: 1;
  background: linear-gradient(180deg, var(--primary), var(--primary-light));
  border-radius: 8px 8px 0 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 5px;
  min-height: 20px;
  transition: all 0.3s;
}

.chart-bar:hover { opacity: 0.8; }

.chart-value {
  font-size: 11px;
  font-weight: 700;
  color: white;
}

.chart-label {
  font-size: 10px;
  color: white;
  font-weight: 600;
}

.stats-actions { display: flex; gap: 12px; margin-top: 15px; }

.action-btn {
  flex: 1;
  padding: 14px;
  background: var(--surface);
  border: 2px solid var(--border);
  border-radius: 12px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  color: var(--text);
}

/* === НАСТРОЙКИ === */
.settings-section {
  background: var(--surface);
  padding: 20px;
  margin-bottom: 15px;
  border-radius: 15px;
  box-shadow: 0 2px 10px var(--shadow);
}

.settings-section h3 {
  margin-bottom: 15px;
  color: var(--text);
  font-size: 16px;
}

.settings-section label {
  display: block;
  margin: 10px 0 5px;
  color: var(--text-secondary);
  font-size: 13px;
}

.settings-section input,
.settings-section select {
  width: 100%;
  padding: 10px;
  border: 2px solid var(--border);
  border-radius: 10px;
  background: var(--bg);
  color: var(--text);
}

.toggle {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.toggle input { display: none; }

.slider {
  width: 50px;
  height: 26px;
  background: var(--border);
  border-radius: 13px;
  position: relative;
  transition: 0.3s;
}

.slider:before {
  content: '';
  position: absolute;
  width: 22px;
  height: 22px;
  background: white;
  border-radius: 50%;
  top: 2px;
  left: 2px;
  transition: 0.3s;
}

input:checked + .slider { background: var(--primary); }
input:checked + .slider:before { transform: translateX(24px); }

.toggle-label {
  font-size: 15px;
  color: var(--text);
}

.template-card {
  background: var(--bg);
  padding: 12px;
  margin: 8px 0;
  border-radius: 10px;
  position: relative;
}

.template-name {
  font-weight: 600;
  color: var(--text);
  margin-bottom: 5px;
}

.template-info {
  font-size: 13px;
  color: var(--text-secondary);
}

.template-card .btn-del {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 5px 10px;
  font-size: 12px;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-secondary);
  font-size: 15px;
}
CSSEOF
echo "✅ style.css создан"

# 4. Обновляем manifest.json
cat > manifest.json << 'MANIFEST'
{
  "name": "ГдеСвета",
  "short_name": "ГдеСвета",
  "description": "Календарь для мастера шугаринга и LPG",
  "start_url": "./",
  "display": "standalone",
  "background_color": "#fef9f9",
  "theme_color": "#ff6b9d",
  "orientation": "portrait"
}
MANIFEST

# 5. Отключаем Service Worker
cat > service-worker.js << 'SW'
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(clients.claim()));
self.addEventListener('fetch', () => {});
SW

# Перезапуск сервера
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo " Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "🎉 ULTIMATE v3.0 ГОТОВА!"
echo ""
echo "✨ Новые функции:"
echo "  📋 Шаблоны услуг (быстрое заполнение)"
echo "  🔄 Повторяющиеся записи (еженедельно/ежемесячно)"
echo "  👥 История клиента (все визиты)"
echo "  🔍 Быстрый поиск по имени/телефону"
echo "  💬 Кнопка сообщения (SMS/мессенджеры)"
echo "  🎨 Тёмная тема"
echo "  📊 График доходов"
echo "  ⏰ Рабочие часы и выходные"
echo "   Цвета для услуг"
echo ""
echo "💡 Все данные сохранены!"
