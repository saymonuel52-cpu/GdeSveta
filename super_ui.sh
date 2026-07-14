#!/bin/bash
echo " СОЗДАЮ СУПЕР-ИНТЕРФЕЙС С ТЕМ..."

# 1. Создаём систему тем (4 темы: Тёмная, Светлая, Розовая, Синяя)
cat > styles/themes.css << 'THEMES'
/* ===========================================
   СИСТЕМА ТЕМ ДЛЯ ГДЕСВЕТА
   =========================================== */

/* === ТЁМНАЯ ТЕМА (Default) === */
body.dark-theme {
  --bg-primary: #0f172a;
  --bg-secondary: #1e293b;
  --bg-card: #1e293b;
  --text-primary: #f8fafc;
  --text-secondary: #94a3b8;
  --accent: #ff6b9d;
  --accent-secondary: #ff8e53;
  --border: #334155;
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --shadow: rgba(0, 0, 0, 0.3);
}

/* === СВЕТЛАЯ ТЕМА === */
body.light-theme {
  --bg-primary: #f8fafc;
  --bg-secondary: #ffffff;
  --bg-card: #ffffff;
  --text-primary: #1e293b;
  --text-secondary: #64748b;
  --accent: #ff6b9d;
  --accent-secondary: #ff8e53;
  --border: #e2e8f0;
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --shadow: rgba(0, 0, 0, 0.1);
}

/* === РОЗОВАЯ ТЕМА === */
body.pink-theme {
  --bg-primary: #fce7f3;
  --bg-secondary: #fbcfe8;
  --bg-card: #ffffff;
  --text-primary: #831843;
  --text-secondary: #be185d;
  --accent: #ec4899;
  --accent-secondary: #f472b6;
  --border: #f9a8d4;
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --shadow: rgba(236, 72, 153, 0.15);
}

/* === СИНИЯ ТЕМА === */
body.blue-theme {
  --bg-primary: #1e3a8a;
  --bg-secondary: #1e40af;
  --bg-card: #1e40af;
  --text-primary: #dbeafe;
  --text-secondary: #93c5fd;
  --accent: #60a5fa;
  --accent-secondary: #93c5fd;
  --border: #3b82f6;
  --success: #34d399;
  --warning: #fbbf24;
  --error: #f87171;
  --shadow: rgba(0, 0, 0, 0.2);
}

/* === ФИОЛЕТОВАЯ ТЕМА === */
body.purple-theme {
  --bg-primary: #2e1065;
  --bg-secondary: #4c1d95;
  --bg-card: #4c1d95;
  --text-primary: #f3e8ff;
  --text-secondary: #d8b4fe;
  --accent: #a855f7;
  --accent-secondary: #c084fc;
  --border: #7c3aed;
  --success: #34d399;
  --warning: #fbbf24;
  --error: #f87171;
  --shadow: rgba(168, 85, 247, 0.2);
}

/* === ПРИМЕНЕНИЕ ПЕРЕМЕННЫХ === */
body {
  background: var(--bg-primary);
  color: var(--text-primary);
  transition: all 0.3s ease;
}

header {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  box-shadow: 0 4px 20px var(--shadow);
}

.nav-btn {
  background: var(--bg-secondary);
  color: var(--text-secondary);
  border: 2px solid var(--border);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.nav-btn.active {
  background: var(--accent);
  color: white;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px var(--shadow);
}

.nav-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px var(--shadow);
}

/* Карточки */
.entry-card, .note-card, .stats-box {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 16px;
  box-shadow: 0 4px 12px var(--shadow);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.entry-card:hover, .note-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px var(--shadow);
}

/* Кнопки */
.add-btn-fixed {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  box-shadow: 0 4px 20px var(--shadow);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

/* Модальные окна */
.modal-content {
  background: var(--bg-card);
  border: 2px solid var(--border);
  border-radius: 20px;
  box-shadow: 0 10px 40px var(--shadow);
}

/* Поля ввода */
input, select, textarea {
  background: var(--bg-secondary);
  border: 2px solid var(--border);
  color: var(--text-primary);
  border-radius: 12px;
  transition: all 0.3s;
}

input:focus, select:focus, textarea:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px rgba(255, 107, 157, 0.1);
  outline: none;
}

/* Календарь */
.day-cell {
  background: var(--bg-secondary);
  border-radius: 12px;
  transition: all 0.2s;
}

.day-cell:hover {
  transform: scale(1.1);
  background: var(--accent);
  color: white;
}

.day-cell.today {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  color: white;
  font-weight: bold;
  box-shadow: 0 4px 12px var(--shadow);
}

/* Статусы */
.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
}

.status-new { background: var(--warning); color: white; }
.status-confirmed { background: var(--accent); color: white; }
.status-done { background: var(--success); color: white; }
.status-cancelled { background: var(--error); color: white; }

/* Утренний брифинг */
#morningBriefing {
  background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
  border-radius: 20px;
  padding: 20px;
  color: white;
  box-shadow: 0 8px 24px var(--shadow);
  animation: slideIn 0.5s ease;
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(-20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Переключатель тем */
.theme-toggle {
  position: fixed;
  top: 15px;
  right: 15px;
  background: var(--bg-secondary);
  border: 2px solid var(--border);
  border-radius: 50%;
  width: 45px;
  height: 45px;
  font-size: 22px;
  cursor: pointer;
  z-index: 1000;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 12px var(--shadow);
}

.theme-toggle:hover {
  transform: rotate(180deg) scale(1.1);
}

/* Скроллбар */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: var(--bg-secondary);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb {
  background: var(--accent);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--accent-secondary);
}
THEMES

echo "✅ Создана система тем (5 тем)"

# 2. Обновляем main.css (добавляем импорт тем)
sed -i '1i @import url("themes.css");' styles/main.css

# 3. Создаём переключатель тем с меню выбора
cat > theme-switcher.js << 'SWITCHER'
// Переключатель тем с выбором из меню
const ThemeSwitcher = {
  themes: ['dark', 'light', 'pink', 'blue', 'purple'],
  currentTheme: Storage.get('theme', 'dark'),
  
  init() {
    this.applyTheme(this.currentTheme);
    this.createMenu();
  },
  
  createMenu() {
    const toggle = document.getElementById('themeToggle');
    if (!toggle) return;
    
    // Создаём меню выбора тем
    const menu = document.createElement('div');
    menu.id = 'themeMenu';
    menu.style.cssText = `
      position: fixed;
      top: 70px;
      right: 15px;
      background: var(--bg-card, #1e293b);
      border: 2px solid var(--border, #334155);
      border-radius: 16px;
      padding: 10px;
      z-index: 1001;
      display: none;
      box-shadow: 0 8px 24px rgba(0,0,0,0.3);
      min-width: 150px;
    `;
    
    const themeNames = {
      dark: '🌙 Тёмная',
      light: '☀️ Светлая',
      pink: '🌸 Розовая',
      blue: '💙 Синяя',
      purple: '💜 Фиолетовая'
    };
    
    this.themes.forEach(theme => {
      const btn = document.createElement('button');
      btn.textContent = themeNames[theme];
      btn.style.cssText = `
        width: 100%;
        padding: 10px;
        margin: 5px 0;
        border: none;
        border-radius: 10px;
        background: var(--bg-secondary, #334155);
        color: var(--text-primary, #f8fafc);
        cursor: pointer;
        transition: all 0.2s;
        font-size: 14px;
      `;
      
      if (theme === this.currentTheme) {
        btn.style.background = 'var(--accent, #ff6b9d)';
        btn.style.color = 'white';
      }
      
      btn.onclick = () => {
        this.setTheme(theme);
        menu.style.display = 'none';
      };
      
      menu.appendChild(btn);
    });
    
    document.body.appendChild(menu);
    
    // Показ/скрытие меню
    toggle.onclick = () => {
      menu.style.display = menu.style.display === 'none' ? 'block' : 'none';
    };
    
    // Закрытие при клике вне
    document.addEventListener('click', (e) => {
      if (!toggle.contains(e.target) && !menu.contains(e.target)) {
        menu.style.display = 'none';
      }
    });
  },
  
  setTheme(theme) {
    this.currentTheme = theme;
    Storage.set('theme', theme);
    this.applyTheme(theme);
    
    // Обновляем активную кнопку в меню
    const menu = document.getElementById('themeMenu');
    if (menu) {
      Array.from(menu.children).forEach((btn, index) => {
        if (this.themes[index] === theme) {
          btn.style.background = 'var(--accent, #ff6b9d)';
          btn.style.color = 'white';
        } else {
          btn.style.background = '';
          btn.style.color = '';
        }
      });
    }
  },
  
  applyTheme(theme) {
    document.body.className = theme + '-theme';
    const toggle = document.getElementById('themeToggle');
    if (toggle) {
      const icons = {
        dark: '🌙',
        light: '☀️',
        pink: '',
        blue: '💙',
        purple: '💜'
      };
      toggle.textContent = icons[theme] || '';
    }
  }
};

// Инициализация при загрузке
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => ThemeSwitcher.init());
} else {
  ThemeSwitcher.init();
}
SWITCHER

# Добавляем скрипт в index.html
sed -i 's|</body>|<script src="theme-switcher.js"></script>\n</body>|' index.html

echo "✅ Создан переключатель тем с меню"

# 4. Улучшаем стили карточек и анимации
cat >> styles/main.css << 'EXTRASTYLES'

/* Дополнительные улучшения */
.entry-card {
  overflow: hidden;
  position: relative;
}

.entry-card::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: linear-gradient(180deg, var(--accent), var(--accent-secondary));
  opacity: 0;
  transition: opacity 0.3s;
}

.entry-card:hover::before {
  opacity: 1;
}

/* Анимация появления элементов */
.entry-card, .note-card {
  animation: fadeInUp 0.4s ease;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Glassmorphism эффекты */
header {
  backdrop-filter: blur(10px);
}

/* Улучшенные кнопки действий */
.entry-actions button, .status-buttons button {
  border-radius: 10px;
  padding: 8px 16px;
  font-weight: 600;
  transition: all 0.2s;
  border: none;
  cursor: pointer;
}

.entry-actions button:hover, .status-buttons button:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px var(--shadow);
}

/* Улучшенный прайс */
.price-item {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 15px;
  margin: 10px 0;
  transition: all 0.3s;
}

.price-item:hover {
  transform: translateX(5px);
  border-color: var(--accent);
}

/* Улучшенная статистика */
.stats-box {
  padding: 20px;
  margin: 10px 0;
}

.stats-box h3 {
  color: var(--accent);
  margin-bottom: 15px;
  font-size: 20px;
}

/* Фильтры */
.filter-bar select, .family-filters button, .note-filters button {
  border-radius: 10px;
  padding: 8px 16px;
  margin: 5px;
  border: 2px solid var(--border);
  background: var(--bg-secondary);
  color: var(--text-primary);
  cursor: pointer;
  transition: all 0.2s;
}

.filter-bar select:focus, .family-filters button:focus, .note-filters button:focus {
  border-color: var(--accent);
  outline: none;
}

.family-filters button.active, .note-filters button.active {
  background: var(--accent);
  color: white;
  border-color: var(--accent);
}
EXTRASTYLES

echo "✅ Добавлены улучшения стилей"

# 5. Git commit + push + сборка APK
echo ""
echo "🔄 Отправка на GitHub и сборка..."

git add .
git commit -m "feat: Добавлен супер-интерфейс с 5 темами и анимациями"
git push origin main

# Сборка APK
echo "📦 Сборка APK (подожди 2-3 минуты)..."
rm -rf android www
mkdir -p www
cp -r index.html manifest.json app.js styles/ src/ icons/ theme-switcher.js www/

npm init -y > /dev/null 2>&1
npm install @capacitor/core @capacitor/cli @capacitor/android --save > /dev/null 2>&1
npx cap init "GdeSveta" "com.gdesveta.app" --web-dir="www" > /dev/null 2>&1
npx cap add android > /dev/null 2>&1
npx cap sync android > /dev/null 2>&1

cd android
chmod +x gradlew
./gradlew assembleDebug > /dev/null 2>&1

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
  cp app/build/outputs/apk/debug/app-debug.apk ../GdeSveta_SuperUI.apk
  cd ..
  cp GdeSveta_SuperUI.apk ~/storage/downloads/GdeSveta_SuperUI.apk 2>/dev/null
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "🎨 СУПЕР-ИНТЕРФЕЙС ГОТОВ!"
  echo "═══════════════════════════════════════════════"
  echo "✅ 5 тем: Тёмная, Светлая, Розовая, Синяя, Фиолетовая"
  echo "✅ Плавные анимации и переходы"
  echo "✅ Glassmorphism эффекты"
  echo "✅ Улучшенные карточки и кнопки"
  echo "✅ Меню выбора тем (нажми на иконку темы)"
  echo ""
  echo "📁 APK: ~/storage/downloads/GdeSveta_SuperUI.apk"
  echo "═══════════════════════════════════════════════"
  echo "Удали старую версию и установи SuperUI!"
else
  echo "❌ Ошибка сборки"
  cd ..
fi
