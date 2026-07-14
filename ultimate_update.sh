#!/bin/bash
echo "🚀 ULTIMATE UPDATE - Все лучшие функции"
echo "========================================"

# Резервные копии
cp app.js app.js.backup.ultimate.$(date +%s)
cp style.css style.css.backup.ultimate.$(date +%s)
cp index.html index.html.backup.ultimate.$(date +%s)
echo "💾 Бэкапы созданы"

# 1. Обновляем index.html
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
  <link rel="stylesheet" href="style.css?v=5">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <nav>
        <button class="nav-btn active" data-tab="calendar">Календарь</button>
        <button class="nav-btn" data-tab="clients">Клиенты</button>
        <button class="nav-btn" data-tab="stats">Статистика</button>
        <button class="nav-btn" data-tab="settings">⚙️</button>
      </nav>
    </header>

    <main>
      <!-- Вкладка Календарь -->
      <div id="tab-calendar" class="tab-content active">
        <div class="search-bar">
          <input type="text" id="globalSearch" placeholder="🔍 Поиск клиента или телефона...">
        </div>
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
          </select>
        </div>
        <div id="dayEntries"></div>
      </div>

      <!-- Вкладка Клиенты -->
      <div id="tab-clients" class="tab-content">
        <h2>👥 Клиенты</h2>
        <input type="text" id="clientSearch" placeholder="Поиск клиента..." class="search-input">
        <div id="clientsList"></div>
      </div>

      <!-- Вкладка Статистика -->
      <div id="tab-stats" class="tab-content">
        <h2>📊 Статистика</h2>
        <div id="statsContent"></div>
        <div id="incomeChart" class="chart-container"></div>
        <div class="stats-actions">
          <button id="exportBtn" class="action-btn">💾 Экспорт</button>
          <button id="importBtn" class="action-btn">📂 Импорт</button>
          <input type="file" id="importFile" accept=".json" style="display:none">
        </div>
      </div>

      <!-- Вкладка Настройки -->
      <div id="tab-settings" class="tab-content">
        <h2>⚙️ Настройки</h2>
        
        <div class="settings-section">
          <h3> Тема</h3>
          <label class="toggle">
            <input type="checkbox" id="darkThemeToggle">
            <span class="slider"></span>
            <span class="toggle-label">Тёмная тема</span>
          </label>
        </div>

        <div class="settings-section">
          <h3>⏰ Рабочее время</h3>
          <label>Начало:</label>
          <input type="time" id="workStart" value="09:00">
          <label>Конец:</label>
          <input type="time" id="workEnd" value="21:00">
          <label>Выходные:</label>
          <select id="weekends" multiple style="height:100px">
            <option value="0">Понедельник</option>
            <option value="1">Вторник</option>
            <option value="2">Среда</option>
            <option value="3">Четверг</option>
            <option value="4">Пятница</option>
            <option value="5">Суббота</option>
            <option value="6">Воскресенье</option>
          </select>
          <button id="saveWorkHours" class="save-btn" style="margin-top:10px">Сохранить</button>
        </div>

        <div class="settings-section">
          <h3>📋 Шаблоны услуг</h3>
          <div id="templatesList"></div>
          <button id="addTemplateBtn" class="action-btn" style="margin-top:10px">+ Добавить шаблон</button>
        </div>

        <div class="settings-section">
          <h3>💾 Данные</h3>
          <button id="clearAllData" class="action-btn" style="background:#ffebee;color:#d32f2f">🗑️ Очистить все данные</button>
        </div>
      </div>
    </main>
  </div>

  <button id="addAppBtnFixed" class="add-btn-fixed">+ Добавить запись</button>

  <!-- МОДАЛКА -->
  <div id="modal" class="modal">
    <div class="modal-content">
      <span class="close-modal">&times;</span>
      <h3 id="modalTitle">Новая запись</h3>
      
      <form id="entryForm">
        <input type="hidden" id="entryId">
        
        <label>Шаблон услуги</label>
        <select id="serviceTemplate">
          <option value="">-- Выберите шаблон --</option>
        </select>

        <label>Имя клиента *</label>
        <input type="text" id="entryName" required placeholder="Введите имя" list="clientsList">
        <datalist id="clientsList"></datalist>

        <label>Телефон</label>
        <input type="tel" id="entryPhone" placeholder="+7 (999) 999-99-99">

        <label>Дата *</label>
        <input type="date" id="entryDate" required>

        <label>Повторять</label>
        <select id="repeatType">
          <option value="none">Не повторять</option>
          <option value="weekly">Каждую неделю</option>
          <option value="biweekly">Каждые 2 недели</option>
          <option value="monthly">Каждый месяц</option>
        </select>

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

  <!-- МОДАЛКА ИСТОРИИ КЛИЕНТА -->
  <div id="clientHistoryModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeClientHistory()">&times;</span>
      <h3 id="clientHistoryTitle">История клиента</h3>
      <div id="clientHistoryContent"></div>
    </div>
  </div>

  <!-- МОДАЛКА ШАБЛОНА -->
  <div id="templateModal" class="modal">
    <div class="modal-content">
      <span class="close-modal" onclick="closeTemplateModal()">&times;</span>
      <h3>Добавить шаблон услуги</h3>
      <form id="templateForm">
        <label>Название</label>
        <input type="text" id="templateName" required placeholder="Напр. Ноги полностью">
        <label>Услуга</label>
        <select id="templateService">
          <option>Шугаринг</option>
          <option>LPG-массаж</option>
          <option>Другое</option>
        </select>
        <label>Длительность (мин)</label>
        <input type="number" id="templateDuration" value="60" required>
        <label>Цена (₽)</label>
        <input type="number" id="templatePrice" value="1000" required>
        <div class="form-actions">
          <button type="submit" class="save-btn">Сохранить</button>
          <button type="button" class="cancel-btn" onclick="closeTemplateModal()">Отмена</button>
        </div>
      </form>
    </div>
  </div>

  <script src="app.js?v=5"></script>
</body>
</html>
HTML
echo "✅ index.html создан"

echo " Продолжение в следующем сообщении..."
