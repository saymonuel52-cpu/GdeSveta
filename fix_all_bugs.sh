#!/bin/bash
echo "🔧 Исправляю все найденные баги..."

# 1. ИСПРАВЛЕНИЕ: Кнопка закрытия модалки (крестик)
echo "1. Исправляю кнопку закрытия модалки..."

# Добавляем обработчик для крестика в Modal.js
cat > src/ui/components/Modal.js << 'MODAL'
/**
 * MODAL COMPONENT
 */
const Modal = {
  currentModal: null,
  
  create(options) {
    const modal = document.createElement('div');
    modal.className = 'modal active';
    modal.innerHTML = `
      <div class="modal-content">
        <span class="close-modal" id="modalCloseBtn">&times;</span>
        <h3>${options.title || ''}</h3>
        <div class="modal-body">${options.content || ''}</div>
      </div>
    `;
    
    document.body.appendChild(modal);
    this.currentModal = modal;
    
    // Обработчик для крестика
    const closeBtn = modal.querySelector('#modalCloseBtn');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => {
        this.close();
      });
    }
    
    // Закрытие по клику на фон
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        this.close();
      }
    });
    
    // Закрытие по Escape
    const escapeHandler = (e) => {
      if (e.key === 'Escape') {
        this.close();
        document.removeEventListener('keydown', escapeHandler);
      }
    };
    document.addEventListener('keydown', escapeHandler);
    
    return modal;
  },
  
  close() {
    if (this.currentModal) {
      this.currentModal.remove();
      this.currentModal = null;
    }
  },
  
  alert(message, title = 'Внимание') {
    const modal = this.create({
      title,
      content: `<p>${message}</p><button class="save-btn" style="margin-top:15px;" id="alertOkBtn">OK</button>`
    });
    
    const okBtn = modal.querySelector('#alertOkBtn');
    if (okBtn) {
      okBtn.addEventListener('click', () => this.close());
    }
  },
  
  confirm(message, onConfirm, onCancel) {
    const modal = this.create({
      title: 'Подтверждение',
      content: `
        <p>${message}</p>
        <div style="display:flex;gap:10px;margin-top:15px;">
          <button class="save-btn" id="confirmYes">Да</button>
          <button class="cancel-btn" id="confirmNo">Нет</button>
        </div>
      `
    });
    
    modal.querySelector('#confirmYes').addEventListener('click', () => {
      this.close();
      if (onConfirm) onConfirm();
    });
    
    modal.querySelector('#confirmNo').addEventListener('click', () => {
      this.close();
      if (onCancel) onCancel();
    });
  },
  
  form(options) {
    const modal = this.create({
      title: options.title || 'Форма',
      content: options.content || ''
    });
    
    return modal;
  }
};

window.Modal = Modal;
MODAL

echo "✅ Modal.js исправлен"

# 2. ИСПРАВЛЕНИЕ: Функция удаления записей
echo "2. Исправляю удаление записей..."

# Добавляем явную функцию deleteEntry в app.js
if ! grep -q "window.deleteEntry" app.js; then
  cat >> app.js << 'DELETEFUNC'

// Глобальная функция для удаления записей
window.deleteEntry = function(id) {
  Modal.confirm('Удалить эту запись?', () => {
    try {
      EntryService.delete(id);
      Modal.alert('✅ Запись удалена!');
      // Обновляем текущий вид
      if (currentTab === 'calendar') {
        CalendarView.render();
      } else if (currentTab === 'work') {
        WorkView.render();
      } else if (currentTab === 'family') {
        FamilyView.render();
      }
    } catch (error) {
      Modal.alert('❌ Ошибка: ' + error.message);
    }
  });
};
DELETEFUNC
  echo "✅ Функция deleteEntry добавлена"
else
  echo "⚠️  Функция deleteEntry уже существует"
fi

# 3. ИСПРАВЛЕНИЕ: Тёмная тема
echo "3. Исправляю тёмную тему..."

# Добавляем принудительное применение тёмной темы
cat >> app.js << 'DARKFIX'

// Принудительная проверка и применение тёмной темы
function applyDarkTheme() {
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) {
      toggle.textContent = '☀️';
      toggle.onclick = () => toggleTheme();
    }
  } else {
    if (toggle) {
      toggle.textContent = '🌙';
      toggle.onclick = () => toggleTheme();
    }
  }
}

// Функция переключения темы
function toggleTheme() {
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  body.classList.toggle('dark-theme');
  const isDark = body.classList.contains('dark-theme');
  
  Storage.set('theme', isDark ? 'dark' : 'light');
  
  if (toggle) {
    toggle.textContent = isDark ? '☀️' : '🌙';
  }
}

// Применяем тему при загрузке
document.addEventListener('DOMContentLoaded', applyDarkTheme);
DARKFIX

echo "✅ Тёмная тема исправлена"

# 4. ДОБАВЛЕНИЕ: Загрузочный экран (Splash Screen)
echo "4. Добавляю загрузочный экран..."

# Создаём splash.html
cat > splash.html << 'SPLASH'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ГдеСвета - Загрузка</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #ff6b9d, #ff8e53);
      height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }
    
    .splash-container {
      text-align: center;
      animation: fadeIn 1s ease;
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: scale(0.8); }
      to { opacity: 1; transform: scale(1); }
    }
    
    .logo {
      font-size: 80px;
      margin-bottom: 20px;
      animation: bounce 1s infinite;
    }
    
    @keyframes bounce {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-20px); }
    }
    
    .app-name {
      font-size: 32px;
      color: white;
      font-weight: bold;
      margin-bottom: 10px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
    }
    
    .tagline {
      font-size: 16px;
      color: rgba(255,255,255,0.9);
      margin-bottom: 40px;
    }
    
    .loader {
      width: 60px;
      height: 60px;
      border: 5px solid rgba(255,255,255,0.3);
      border-top: 5px solid white;
      border-radius: 50%;
      margin: 0 auto;
      animation: spin 1s linear infinite;
    }
    
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    .features {
      margin-top: 40px;
      display: flex;
      gap: 20px;
      justify-content: center;
      flex-wrap: wrap;
    }
    
    .feature {
      background: rgba(255,255,255,0.2);
      padding: 15px 20px;
      border-radius: 15px;
      color: white;
      font-size: 14px;
      backdrop-filter: blur(10px);
      animation: slideUp 0.5s ease;
      animation-fill-mode: both;
    }
    
    .feature:nth-child(1) { animation-delay: 0.2s; }
    .feature:nth-child(2) { animation-delay: 0.4s; }
    .feature:nth-child(3) { animation-delay: 0.6s; }
    .feature:nth-child(4) { animation-delay: 0.8s; }
    
    @keyframes slideUp {
      from {
        opacity: 0;
        transform: translateY(30px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    .feature-icon {
      font-size: 24px;
      margin-bottom: 5px;
    }
  </style>
</head>
<body>
  <div class="splash-container">
    <div class="logo"></div>
    <div class="app-name">ГдеСвета</div>
    <div class="tagline">Твой семейный ежедневник</div>
    
    <div class="loader"></div>
    
    <div class="features">
      <div class="feature">
        <div class="feature-icon">💼</div>
        <div>Работа</div>
      </div>
      <div class="feature">
        <div class="feature-icon">👨‍👩‍</div>
        <div>Семья</div>
      </div>
      <div class="feature">
        <div class="feature-icon">✅</div>
        <div>Задачи</div>
      </div>
      <div class="feature">
        <div class="feature-icon">📝</div>
        <div>Заметки</div>
      </div>
    </div>
  </div>
  
  <script>
    // Автоматический переход на главную страницу через 2 секунды
    setTimeout(() => {
      window.location.href = 'index.html';
    }, 2000);
  </script>
</body>
</html>
SPLASH

echo "✅ Splash screen создан: splash.html"

# Обновляем manifest.json чтобы использовать splash
cat > manifest.json << 'MANIFEST'
{
  "name": "GdeSveta - Family Planner",
  "short_name": "GdeSveta",
  "description": "Daily planner for mom-master: work, family, kids, dog",
  "start_url": "./splash.html",
  "display": "standalone",
  "background_color": "#ff6b9d",
  "theme_color": "#ff6b9d",
  "orientation": "portrait",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
MANIFEST

echo "✅ Manifest обновлён (теперь начинает со splash.html)"

echo ""
echo "═══════════════════════════════════════"
echo "✅ ВСЕ ИСПРАВЛЕНИЯ ВНЕСЕНЫ!"
echo "═══════════════════════════════════════"
echo ""
echo "📋 Что исправлено:"
echo "  1. ✅ Кнопка закрытия модалки (крестик)"
echo "  2. ✅ Функция удаления записей"
echo "  3. ✅ Тёмная тема"
echo "  4. ✅ Добавлен загрузочный экран (splash.html)"
echo ""
echo "🧪 ТЕСТИРОВАНИЕ В БРАУЗЕРЕ:"
echo ""
echo "1. Запусти сервер:"
echo "   python -m http.server 8000"
echo ""
echo "2. Открой в браузере:"
echo "   http://localhost:8000/splash.html"
echo ""
echo "3. Проверь:"
echo "   • Крестик закрывает модалку"
echo "   • Записи удаляются"
echo "   • Тёмная тема переключается"
echo "   • Splash screen красивый"
echo ""
echo "4. Если всё работает - пересобери APK"
