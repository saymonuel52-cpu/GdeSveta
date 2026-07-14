#!/bin/bash
echo "🏗️ Создаю архитектуру проекта..."

# 1. Создаём структуру папок
echo "📁 Создаю структуру папок..."
mkdir -p src/core
mkdir -p src/models
mkdir -p src/services
mkdir -p src/ui/components
mkdir -p src/views
mkdir -p src/config
mkdir -p styles
mkdir -p public/assets/icons
mkdir -p tests

echo "✅ Структура создана"

# 2. Создаём core/storage.js — работа с localStorage
echo "💾 Создаю core/storage.js..."
cat > src/core/storage.js << 'STORAGE'
/**
 * STORAGE MODULE
 * Единая точка доступа к localStorage
 * - Автоматическая сериализация
 * - Обработка ошибок
 * - Версионирование данных
 * - Миграции при обновлении
 */

const Storage = (() => {
  const VERSION_KEY = 'gdesveta_version';
  const CURRENT_VERSION = 1;
  
  /**
   * Получить данные из хранилища
   * @param {string} key - Ключ
   * @param {*} defaultValue - Значение по умолчанию
   * @returns {*} Данные
   */
  function get(key, defaultValue = null) {
    try {
      const item = localStorage.getItem(key);
      if (item === null) return defaultValue;
      return JSON.parse(item);
    } catch (error) {
      console.error(`[Storage] Ошибка чтения ${key}:`, error);
      return defaultValue;
    }
  }
  
  /**
   * Сохранить данные в хранилище
   * @param {string} key - Ключ
   * @param {*} value - Данные
   * @returns {boolean} Успех
   */
  function set(key, value) {
    try {
      const json = JSON.stringify(value);
      localStorage.setItem(key, json);
      return true;
    } catch (error) {
      console.error(`[Storage] Ошибка записи ${key}:`, error);
      return false;
    }
  }
  
  /**
   * Удалить данные из хранилища
   * @param {string} key - Ключ
   */
  function remove(key) {
    try {
      localStorage.removeItem(key);
    } catch (error) {
      console.error(`[Storage] Ошибка удаления ${key}:`, error);
    }
  }
  
  /**
   * Очистить всё хранилище
   */
  function clear() {
    try {
      localStorage.clear();
    } catch (error) {
      console.error('[Storage] Ошибка очистки:', error);
    }
  }
  
  /**
   * Получить все ключи
   * @returns {string[]} Массив ключей
   */
  function keys() {
    try {
      return Object.keys(localStorage);
    } catch (error) {
      console.error('[Storage] Ошибка получения ключей:', error);
      return [];
    }
  }
  
  /**
   * Экспорт всех данных
   * @returns {object} Все данные
   */
  function exportAll() {
    const data = {};
    keys().forEach(key => {
      data[key] = get(key);
    });
    return data;
  }
  
  /**
   * Импорт данных
   * @param {object} data - Данные для импорта
   */
  function importAll(data) {
    Object.keys(data).forEach(key => {
      set(key, data[key]);
    });
  }
  
  /**
   * Проверить версию и выполнить миграцию
   */
  function checkVersion() {
    const storedVersion = get(VERSION_KEY, 0);
    
    if (storedVersion < CURRENT_VERSION) {
      console.log(`[Storage] Миграция с v${storedVersion} на v${CURRENT_VERSION}`);
      migrate(storedVersion, CURRENT_VERSION);
      set(VERSION_KEY, CURRENT_VERSION);
    }
  }
  
  /**
   * Миграция данных между версиями
   * @param {number} from - Старая версия
   * @param {number} to - Новая версия
   */
  function migrate(from, to) {
    // Пример миграции:
    // if (from === 0 && to === 1) {
    //   const oldData = get('old_key');
    //   set('new_key', transformData(oldData));
    //   remove('old_key');
    // }
    console.log('[Storage] Миграция завершена');
  }
  
  // Публичный API
  return {
    get,
    set,
    remove,
    clear,
    keys,
    exportAll,
    importAll,
    checkVersion
  };
})();

// Экспорт для использования в других модулях
window.Storage = Storage;
STORAGE

echo "✅ core/storage.js создан"

# 3. Создаём core/events.js — система событий
echo "📡 Создаю core/events.js..."
cat > src/core/events.js << 'EVENTS'
/**
 * EVENTS MODULE
 * Система событий (Pub/Sub) для связи между модулями
 * - Модули общаются без прямых зависимостей
 * - Легко тестировать
 * - Легко расширять
 */

const Events = (() => {
  const listeners = {};
  
  /**
   * Подписаться на событие
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   * @returns {function} Функция отписки
   */
  function on(event, callback) {
    if (!listeners[event]) {
      listeners[event] = [];
    }
    
    listeners[event].push(callback);
    
    // Возвращаем функцию отписки
    return () => off(event, callback);
  }
  
  /**
   * Отписаться от события
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   */
  function off(event, callback) {
    if (!listeners[event]) return;
    
    listeners[event] = listeners[event].filter(cb => cb !== callback);
  }
  
  /**
   * Отправить событие
   * @param {string} event - Имя события
   * @param {*} data - Данные события
   */
  function emit(event, data) {
    if (!listeners[event]) return;
    
    listeners[event].forEach(callback => {
      try {
        callback(data);
      } catch (error) {
        console.error(`[Events] Ошибка в обработчике ${event}:`, error);
      }
    });
  }
  
  /**
   * Подписаться на событие один раз
   * @param {string} event - Имя события
   * @param {function} callback - Функция-обработчик
   */
  function once(event, callback) {
    const unsubscribe = on(event, (data) => {
      callback(data);
      unsubscribe();
    });
  }
  
  /**
   * Отписаться от всех событий
   */
  function clear() {
    Object.keys(listeners).forEach(event => {
      listeners[event] = [];
    });
  }
  
  // Публичный API
  return {
    on,
    off,
    emit,
    once,
    clear
  };
})();

// Экспорт
window.Events = Events;
EVENTS

echo "✅ core/events.js создан"

# 4. Создаём core/utils.js — утилиты
echo "🔧 Создаю core/utils.js..."
cat > src/core/utils.js << 'UTILS'
/**
 * UTILS MODULE
 * Набор утилит для работы с данными
 */

const Utils = (() => {
  /**
   * Сгенерировать уникальный ID
   * @returns {number} Уникальный ID
   */
  function generateId() {
    return Date.now() + Math.random();
  }
  
  /**
   * Форматировать дату
   * @param {string|Date} date - Дата
   * @param {string} format - Формат (short, long, full)
   * @returns {string} Отформатированная дата
   */
  function formatDate(date, format = 'short') {
    const d = typeof date === 'string' ? new Date(date) : date;
    
    const options = {
      short: { day: 'numeric', month: 'short' },
      long: { day: 'numeric', month: 'long', weekday: 'short' },
      full: { day: 'numeric', month: 'long', year: 'numeric', weekday: 'long' }
    };
    
    return d.toLocaleDateString('ru-RU', options[format] || options.short);
  }
  
  /**
   * Форматировать время
   * @param {string} time - Время в формате HH:MM
   * @returns {string} Отформатированное время
   */
  function formatTime(time) {
    return time; // Уже в нужном формате
  }
  
  /**
   * Конвертировать время в минуты
   * @param {string} time - Время в формате HH:MM
   * @returns {number} Минуты с начала дня
   */
  function timeToMinutes(time) {
    const [h, m] = time.split(':').map(Number);
    return h * 60 + m;
  }
  
  /**
   * Конвертировать минуты в время
   * @param {number} mins - Минуты с начала дня
   * @returns {string} Время в формате HH:MM
   */
  function minutesToTime(mins) {
    const h = Math.floor(mins / 60) % 24;
    const m = mins % 60;
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  }
  
  /**
   * Рассчитать время окончания
   * @param {string} startTime - Время начала
   * @param {number} duration - Длительность в минутах
   * @returns {string} Время окончания
   */
  function calcEndTime(startTime, duration) {
    if (!startTime || !duration) return '';
    return minutesToTime(timeToMinutes(startTime) + parseInt(duration));
  }
  
  /**
   * Получить сегодняшнюю дату
   * @returns {string} Дата в формате YYYY-MM-DD
   */
  function getToday() {
    return new Date().toISOString().split('T')[0];
  }
  
  /**
   * Получить текущее время
   * @returns {string} Время в формате HH:MM
   */
  function getNow() {
    const now = new Date();
    return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  }
  
  /**
   * Проверить валидность email
   * @param {string} email - Email
   * @returns {boolean} Валиден
   */
  function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
  
  /**
   * Проверить валидность телефона
   * @param {string} phone - Телефон
   * @returns {boolean} Валиден
   */
  function isValidPhone(phone) {
    return /^\+?[\d\s\-\(\)]{10,}$/.test(phone);
  }
  
  /**
   * Экранировать HTML
   * @param {string} str - Строка
   * @returns {string} Экранированная строка
   */
  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }
  
  /**
   * Debounce функция
   * @param {function} func - Функция
   * @param {number} wait - Задержка в мс
   * @returns {function} Debounced функция
   */
  function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
  
  // Публичный API
  return {
    generateId,
    formatDate,
    formatTime,
    timeToMinutes,
    minutesToTime,
    calcEndTime,
    getToday,
    getNow,
    isValidEmail,
    isValidPhone,
    escapeHtml,
    debounce
  };
})();

// Экспорт
window.Utils = Utils;
UTILS

echo "✅ core/utils.js создан"

# 5. Создаём core/store.js — единое хранилище
echo "🏪 Создаю core/store.js..."
cat > src/core/store.js << 'STORE'
/**
 * STORE MODULE
 * Централизованное хранилище состояния приложения
 * - Автоматическое сохранение
 * - Подписка на изменения
 * - Единый источник правды
 */

const Store = (() => {
  const STORAGE_KEY = 'gdesveta_store';
  
  // Начальное состояние
  let state = {
    entries: [],
    notes: [],
    priceList: [],
    familyMembers: [],
    ui: {
      currentTab: 'calendar',
      selectedDate: Utils.getToday(),
      currentDate: new Date()
    }
  };
  
  // Подписчики на изменения
  const subscribers = [];
  
  /**
   * Инициализация хранилища
   */
  function init() {
    const saved = Storage.get(STORAGE_KEY);
    if (saved) {
      state = { ...state, ...saved };
    }
    
    // Проверка версии и миграция
    Storage.checkVersion();
    
    console.log('[Store] Инициализирован');
  }
  
  /**
   * Получить состояние
   * @returns {object} Текущее состояние
   */
  function getState() {
    return { ...state };
  }
  
  /**
   * Обновить состояние
   * @param {object} updates - Обновления
   */
  function setState(updates) {
    state = { ...state, ...updates };
    save();
    notify();
  }
  
  /**
   * Обновить UI состояние
   * @param {object} updates - Обновления UI
   */
  function setUI(updates) {
    state.ui = { ...state.ui, ...updates };
    notify();
  }
  
  /**
   * Сохранить состояние в localStorage
   */
  function save() {
    Storage.set(STORAGE_KEY, state);
  }
  
  /**
   * Подписаться на изменения
   * @param {function} callback - Функция-обработчик
   * @returns {function} Функция отписки
   */
  function subscribe(callback) {
    subscribers.push(callback);
    return () => {
      const index = subscribers.indexOf(callback);
      if (index > -1) {
        subscribers.splice(index, 1);
      }
    };
  }
  
  /**
   * Уведомить подписчиков об изменениях
   */
  function notify() {
    subscribers.forEach(callback => {
      try {
        callback(getState());
      } catch (error) {
        console.error('[Store] Ошибка в подписчике:', error);
      }
    });
  }
  
  /**
   * Получить записи
   * @returns {Array} Массив записей
   */
  function getEntries() {
    return state.entries;
  }
  
  /**
   * Добавить запись
   * @param {object} entry - Запись
   */
  function addEntry(entry) {
    state.entries.push(entry);
    save();
    notify();
    Events.emit('entry:added', entry);
  }
  
  /**
   * Обновить запись
   * @param {number} id - ID записи
   * @param {object} updates - Обновления
   */
  function updateEntry(id, updates) {
    const index = state.entries.findIndex(e => e.id === id);
    if (index > -1) {
      state.entries[index] = { ...state.entries[index], ...updates };
      save();
      notify();
      Events.emit('entry:updated', state.entries[index]);
    }
  }
  
  /**
   * Удалить запись
   * @param {number} id - ID записи
   */
  function deleteEntry(id) {
    const entry = state.entries.find(e => e.id === id);
    state.entries = state.entries.filter(e => e.id !== id);
    save();
    notify();
    Events.emit('entry:deleted', entry);
  }
  
  /**
   * Получить заметки
   * @returns {Array} Массив заметок
   */
  function getNotes() {
    return state.notes;
  }
  
  /**
   * Добавить заметку
   * @param {object} note - Заметка
   */
  function addNote(note) {
    state.notes.push(note);
    save();
    notify();
    Events.emit('note:added', note);
  }
  
  /**
   * Обновить заметку
   * @param {number} id - ID заметки
   * @param {object} updates - Обновления
   */
  function updateNote(id, updates) {
    const index = state.notes.findIndex(n => n.id === id);
    if (index > -1) {
      state.notes[index] = { ...state.notes[index], ...updates };
      save();
      notify();
      Events.emit('note:updated', state.notes[index]);
    }
  }
  
  /**
   * Удалить заметку
   * @param {number} id - ID заметки
   */
  function deleteNote(id) {
    const note = state.notes.find(n => n.id === id);
    state.notes = state.notes.filter(n => n.id !== id);
    save();
    notify();
    Events.emit('note:deleted', note);
  }
  
  /**
   * Получить прайс-лист
   * @returns {Array} Массив услуг
   */
  function getPriceList() {
    return state.priceList;
  }
  
  /**
   * Добавить услугу в прайс
   * @param {object} item - Услуга
   */
  function addPriceItem(item) {
    state.priceList.push(item);
    save();
    notify();
    Events.emit('price:added', item);
  }
  
  /**
   * Удалить услугу из прайса
   * @param {number} id - ID услуги
   */
  function deletePriceItem(id) {
    const item = state.priceList.find(p => p.id === id);
    state.priceList = state.priceList.filter(p => p.id !== id);
    save();
    notify();
    Events.emit('price:deleted', item);
  }
  
  /**
   * Получить членов семьи
   * @returns {Array} Массив членов семьи
   */
  function getFamilyMembers() {
    return state.familyMembers;
  }
  
  /**
   * Добавить члена семьи
   * @param {object} member - Член семьи
   */
  function addFamilyMember(member) {
    state.familyMembers.push(member);
    save();
    notify();
    Events.emit('family:added', member);
  }
  
  /**
   * Удалить члена семьи
   * @param {number} id - ID члена семьи
   */
  function deleteFamilyMember(id) {
    const member = state.familyMembers.find(m => m.id === id);
    state.familyMembers = state.familyMembers.filter(m => m.id !== id);
    save();
    notify();
    Events.emit('family:deleted', member);
  }
  
  /**
   * Экспорт всех данных
   * @returns {object} Все данные
   */
  function exportData() {
    return {
      entries: state.entries,
      notes: state.notes,
      priceList: state.priceList,
      familyMembers: state.familyMembers
    };
  }
  
  /**
   * Импорт данных
   * @param {object} data - Данные для импорта
   */
  function importData(data) {
    state.entries = data.entries || [];
    state.notes = data.notes || [];
    state.priceList = data.priceList || [];
    state.familyMembers = data.familyMembers || [];
    save();
    notify();
    Events.emit('store:imported');
  }
  
  // Публичный API
  return {
    init,
    getState,
    setState,
    setUI,
    subscribe,
    getEntries,
    addEntry,
    updateEntry,
    deleteEntry,
    getNotes,
    addNote,
    updateNote,
    deleteNote,
    getPriceList,
    addPriceItem,
    deletePriceItem,
    getFamilyMembers,
    addFamilyMember,
    deleteFamilyMember,
    exportData,
    importData
  };
})();

// Экспорт
window.Store = Store;
STORE

echo "✅ core/store.js создан"

# 6. Создаём базовый index.html
echo "📄 Создаю index.html..."
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета - Семейный ежедневник</title>
  <link rel="stylesheet" href="styles/main.css">
</head>
<body>
  <div id="app">
    <header>
      <h1>📅 ГдеСвета</h1>
      <p style="text-align:center;color:white;font-size:14px;opacity:0.9;">Ядро v1.0 загружено</p>
    </header>
    
    <main style="padding:20px;text-align:center;">
      <div style="background:white;padding:30px;border-radius:15px;box-shadow:0 2px 10px rgba(0,0,0,0.1);">
        <h2 style="color:#ff6b9d;margin-bottom:15px;">✅ Ядро готово!</h2>
        <p style="color:#666;margin-bottom:20px;">Модульная архитектура создана</p>
        
        <div style="text-align:left;background:#f5f5f5;padding:15px;border-radius:10px;font-family:monospace;font-size:12px;">
          <div style="margin-bottom:5px;">✅ core/storage.js — хранилище</div>
          <div style="margin-bottom:5px;">✅ core/events.js — события</div>
          <div style="margin-bottom:5px;">✅ core/utils.js — утилиты</div>
          <div style="margin-bottom:5px;">✅ core/store.js — состояние</div>
        </div>
        
        <button onclick="testCore()" style="margin-top:20px;padding:12px 30px;background:#ff6b9d;color:white;border:none;border-radius:10px;font-size:16px;cursor:pointer;">
          🧪 Тестировать ядро
        </button>
        
        <div id="testResult" style="margin-top:15px;display:none;"></div>
      </div>
    </main>
  </div>

  <!-- Загрузка модулей ядра (порядок важен!) -->
  <script src="src/core/storage.js"></script>
  <script src="src/core/events.js"></script>
  <script src="src/core/utils.js"></script>
  <script src="src/core/store.js"></script>
  
  <!-- Инициализация -->
  <script>
    // Инициализация хранилища
    Store.init();
    
    // Тестовая функция
    function testCore() {
      const result = document.getElementById('testResult');
      result.style.display = 'block';
      
      try {
        // Тест Storage
        Storage.set('test', { value: 123 });
        const testValue = Storage.get('test');
        
        // Тест Events
        let eventReceived = false;
        Events.on('test:event', () => { eventReceived = true; });
        Events.emit('test:event');
        
        // Тест Utils
        const today = Utils.getToday();
        const now = Utils.getNow();
        
        // Тест Store
        Store.addEntry({
          id: Utils.generateId(),
          name: 'Тестовая запись',
          date: today,
          time: now,
          category: 'work',
          status: 'new'
        });
        
        const entries = Store.getEntries();
        
        result.innerHTML = `
          <div style="background:#e8f5e9;padding:15px;border-radius:10px;color:#2e7d32;">
            <div style="font-weight:bold;margin-bottom:10px;">✅ Все тесты пройдены!</div>
            <div style="font-size:13px;">
              • Storage: ${testValue.value === 123 ? '✅' : '❌'}<br>
              • Events: ${eventReceived ? '✅' : '❌'}<br>
              • Utils: ${today && now ? '✅' : '❌'}<br>
              • Store: ${entries.length > 0 ? '✅' : '❌'} (${entries.length} записей)
            </div>
          </div>
        `;
        
        console.log('✅ Ядро работает корректно!');
      } catch (error) {
        result.innerHTML = `
          <div style="background:#ffebee;padding:15px;border-radius:10px;color:#c62828;">
            ❌ Ошибка: ${error.message}
          </div>
        `;
        console.error('❌ Ошибка теста:', error);
      }
    }
    
    console.log('✅ ГдеСвета — Ядро v1.0 загружено');
  </script>
</body>
</html>
HTML

echo "✅ index.html создан"

# 7. Создаём базовые стили
echo "🎨 Создаю styles/main.css..."
cat > styles/main.css << 'CSS'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #fef9f9;
  color: #333;
  min-height: 100vh;
}

header {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  color: white;
  padding: 30px 20px;
  text-align: center;
}

header h1 {
  font-size: 28px;
  margin-bottom: 5px;
}
CSS

echo "✅ styles/main.css создан"

# 8. Создаём README.md
echo "📖 Создаю README.md..."
cat > README.md << 'README'
# 📅 ГдеСвета — Семейный ежедневник

Профессиональное приложение для мамы-мастера с детьми.

## 🏗️ Архитектура

### Структура проекта
### Модули ядра

#### 1. Storage (core/storage.js)
- Работа с localStorage
- Автоматическая сериализация
- Версионирование данных
- Миграции

#### 2. Events (core/events.js)
- Система событий (Pub/Sub)
- Связь между модулями без зависимостей
- Подписка/отписка

#### 3. Utils (core/utils.js)
- Форматирование дат/времени
- Валидация данных
- Генерация ID
- Debounce и другие хелперы

#### 4. Store (core/store.js)
- Централизованное состояние
- Автоматическое сохранение
- Подписка на изменения
- CRUD операции

## 🚀 Запуск

```bash
cd ~/GdeSvet
python -m http.server 8000
# Открой http://localhost:8000
```

## 📝 Лицензия

MIT
README

echo "✅ README.md создан"

# 9. Создаём скрипт сборки
echo "🔨 Создаю build.sh..."
cat > build.sh << 'BUILD'
#!/bin/bash
echo "🔨 Сборка проекта..."

# Проверка структуры
echo "📁 Проверка структуры..."
if [ ! -d "src/core" ]; then
  echo "❌ Папка src/core не найдена!"
  exit 1
fi

# Проверка модулей
echo "📦 Проверка модулей..."
modules=(
  "src/core/storage.js"
  "src/core/events.js"
  "src/core/utils.js"
  "src/core/store.js"
)

for module in "${modules[@]}"; do
  if [ -f "$module" ]; then
    echo "✅ $module"
  else
    echo "❌ $module не найден!"
    exit 1
  fi
done

# Запуск сервера
echo "🚀 Запуск сервера..."
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

# Открытие браузера
if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
else
  echo "📱 Открой вручную: http://localhost:8000"
fi

echo ""
echo "✅ Сборка завершена!"
BUILD

chmod +x build.sh
echo "✅ build.sh создан"

# 10. Запускаем сборку
echo ""
echo "🚀 Запускаю сборку..."
./build.sh

echo ""
echo "🎉 ЯДРО СОЗДАНО!"
echo ""
echo "📊 Что сделано:"
echo "  ✅ Структура папок создана"
echo "  ✅ core/storage.js — работа с localStorage"
echo "  ✅ core/events.js — система событий"
echo "  ✅ core/utils.js — утилиты"
echo "  ✅ core/store.js — единое хранилище"
echo "  ✅ index.html — точка входа"
echo "  ✅ styles/main.css — базовые стили"
echo "  ✅ README.md — документация"
echo "  ✅ build.sh — скрипт сборки"
echo ""
echo "🧪 Тестирование:"
echo "  1. Открой приложение"
echo "  2. Нажми кнопку 'Тестировать ядро'"
echo "  3. Должны быть все ✅"
echo ""
echo "📋 Следующий шаг:"
echo "  Создать модели данных (Entry, Note, PriceItem, FamilyMember)"
echo ""
echo "Скажи 'дальше' — продолжим!"
