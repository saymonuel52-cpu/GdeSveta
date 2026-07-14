#!/bin/bash
echo "🌙 Добавляю тёмную тему..."

# 1. Обновляем CSS — добавляем тёмную тему
cat >> styles/main.css << 'CSS'

/* === ТЁМНАЯ ТЕМА === */
body.dark-theme {
  background: linear-gradient(135deg, #1a1a2e, #16213e);
  color: #eaeaea;
}

body.dark-theme header {
  background: linear-gradient(135deg, #2d3561, #3a4a7a);
  box-shadow: 0 4px 15px rgba(0,0,0,0.3);
}

body.dark-theme .nav-btn {
  background: rgba(255,255,255,0.1);
}

body.dark-theme .nav-btn.active {
  background: #ff6b9d;
  color: white;
}

body.dark-theme .tab-header h2,
body.dark-theme h1,
body.dark-theme h2,
body.dark-theme h3 {
  color: #eaeaea;
}

body.dark-theme .calendar-controls,
body.dark-theme .calendar-grid,
body.dark-theme .filter-bar select,
body.dark-theme .stats-box,
body.dark-theme .entry-card,
body.dark-theme .note-card,
body.dark-theme .client-card,
body.dark-theme .price-item,
body.dark-theme .family-member,
body.dark-theme .modal-content,
body.dark-theme .test-section {
  background: #16213e;
  color: #eaeaea;
  box-shadow: 0 2px 10px rgba(0,0,0,0.3);
}

body.dark-theme .day-cell {
  background: #2d3561;
  color: #eaeaea;
}

body.dark-theme .day-cell.other-month {
  color: #555;
}

body.dark-theme .day-header {
  color: #888;
}

body.dark-theme .entry-compact-name,
body.dark-theme .entry-compact-price,
body.dark-theme .client-name,
body.dark-theme .price-item-name {
  color: #eaeaea;
}

body.dark-theme .entry-details,
body.dark-theme .client-info,
body.dark-theme .price-item-details,
body.dark-theme .family-member-info,
body.dark-theme .note-text {
  color: #aaa;
}

body.dark-theme input,
body.dark-theme select,
body.dark-theme textarea {
  background: #2d3561;
  color: #eaeaea;
  border-color: #3a4a7a;
}

body.dark-theme .duration-btn,
body.dark-theme .status-btn,
body.dark-theme .family-filter,
body.dark-theme .note-filter {
  background: #2d3561;
  color: #eaeaea;
  border-color: #3a4a7a;
}

body.dark-theme .quick-add-btn {
  background: #2d3561;
  border-color: #3a4a7a;
  color: #eaeaea;
}

body.dark-theme .action-btn,
body.dark-theme .cancel-btn {
  background: #2d3561;
  color: #eaeaea;
  border-color: #3a4a7a;
}

body.dark-theme .legend-item {
  color: #aaa;
}

body.dark-theme .empty-state {
  color: #888;
}

body.dark-theme .result {
  background: #2d3561;
}

/* Кнопка переключения темы */
.theme-toggle {
  position: fixed;
  top: 15px;
  right: 15px;
  background: rgba(255,255,255,0.2);
  border: none;
  border-radius: 50%;
  width: 45px;
  height: 45px;
  font-size: 22px;
  cursor: pointer;
  z-index: 1000;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.theme-toggle:hover {
  background: rgba(255,255,255,0.3);
  transform: scale(1.1);
}

.theme-toggle:active {
  transform: scale(0.95);
}

/* Анимация переключения */
body.theme-transition,
body.theme-transition * {
  transition: background 0.3s ease, color 0.3s ease, border-color 0.3s ease !important;
}
CSS

echo "✅ CSS тёмной темы добавлен"

# 2. Добавляем кнопку переключения темы в index.html
sed -i '/<button class="add-btn-fixed"/i \  <button class="theme-toggle" id="themeToggle" title="Переключить тему">🌙</button>' index.html

echo "✅ Кнопка темы добавлена"

# 3. Добавляем логику переключения тем в app.js
cat >> app.js << 'APPJS'

// === ТЁМНАЯ ТЕМА ===
function initTheme() {
  const savedTheme = Storage.get('theme', 'light');
  const body = document.body;
  const toggle = document.getElementById('themeToggle');
  
  if (savedTheme === 'dark') {
    body.classList.add('dark-theme');
    if (toggle) toggle.textContent = '☀️';
  }
  
  if (toggle) {
    toggle.addEventListener('click', () => {
      body.classList.add('theme-transition');
      body.classList.toggle('dark-theme');
      
      const isDark = body.classList.contains('dark-theme');
      Storage.set('theme', isDark ? 'dark' : 'light');
      
      toggle.textContent = isDark ? '☀️' : '';
      
      setTimeout(() => {
        body.classList.remove('theme-transition');
      }, 300);
    });
  }
}

// Вызываем при загрузке
document.addEventListener('DOMContentLoaded', initTheme);
APPJS

echo "✅ Логика тёмной темы добавлена"

# 4. Обновляем NotificationService — уведомления в тёмной теме
cat > src/services/NotificationService.js << 'NOTIFY'
/**
 * NOTIFICATION SERVICE
 * С поддержкой тёмной темы
 */

const NotificationService = {
  permission: 'default',
  enabled: true,
  checkInterval: null,
  
  init() {
    if ('Notification' in window) {
      this.permission = Notification.permission;
    }
    this.startChecking();
    this.morningBriefing();
  },
  
  async requestPermission() {
    if (!('Notification' in window)) return false;
    try {
      const result = await Notification.requestPermission();
      this.permission = result;
      return result === 'granted';
    } catch (error) {
      console.error('[Notification] Error:', error);
      return false;
    }
  },
  
  show(title, options = {}) {
    this.showInApp(title, options.body || '');
    
    if (this.enabled && this.permission === 'granted' && 'Notification' in window) {
      try {
        new Notification(title, {
          body: options.body || '',
          icon: '/assets/icons/icon-192.png',
          badge: '/assets/icons/badge-72.png',
          tag: options.tag || 'gdesveta',
          requireInteraction: options.requireInteraction || false
        });
      } catch (error) {
        console.error('[Notification] Show error:', error);
      }
    }
  },
  
  showInApp(title, message) {
    const container = document.getElementById('notificationContainer');
    if (!container) return;
    
    const isDark = document.body.classList.contains('dark-theme');
    const notification = document.createElement('div');
    notification.className = 'in-app-notification';
    notification.style.cssText = isDark ? 
      'background: #2d3561; border-left-color: #ff8e53; color: #eaeaea;' : '';
    
    notification.innerHTML = `
      <div class="notification-content">
        <div class="notification-title" style="${isDark ? 'color: #eaeaea;' : ''}">${title}</div>
        <div class="notification-message" style="${isDark ? 'color: #aaa;' : ''}">${message}</div>
      </div>
      <button class="notification-close" onclick="this.parentElement.remove()" style="${isDark ? 'color: #aaa;' : ''}">×</button>
    `;
    
    container.appendChild(notification);
    setTimeout(() => { if (notification.parentElement) notification.remove(); }, 5000);
  },
  
  checkUpcoming() {
    const now = new Date();
    const upcoming = EntryService.getUpcoming(10);
    
    upcoming.forEach(entry => {
      const entryTime = new Date(entry.date + 'T' + entry.time);
      const diffMinutes = Math.floor((entryTime - now) / 60000);
      
      if (diffMinutes === 60) {
        this.show(`⏰ Скоро запись: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
      if (diffMinutes === 15) {
        this.show(`⏰ Через 15 минут: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
      if (diffMinutes === 5) {
        this.show(`⏰ Через 5 минут: ${entry.name}`, `${entry.time} — ${entry.service}`);
      }
    });
  },
  
  morningBriefing() {
    const today = Utils.getToday();
    const entries = EntryService.getByDate(today);
    const notes = NoteService.getByDate(today);
    
    if (entries.length === 0 && notes.length === 0) return;
    
    const workEntries = entries.filter(e => e.category === 'work');
    const familyEntries = entries.filter(e => e.category === 'family' || e.category === 'dog');
    
    let message = '';
    if (workEntries.length > 0) message += `💼 ${workEntries.length} клиента\n`;
    if (familyEntries.length > 0) message += `👨‍👩👧 ${familyEntries.length} семейных дел\n`;
    if (notes.length > 0) message += `📝 ${notes.length} заметок`;
    
    setTimeout(() => this.show('☀️ Доброе утро!', message), 1000);
  },
  
  startChecking() {
    this.checkInterval = setInterval(() => this.checkUpcoming(), 30000);
  },
  
  stopChecking() {
    if (this.checkInterval) clearInterval(this.checkInterval);
  },
  
  toggle(enabled) {
    this.enabled = enabled;
    Storage.set('notifications_enabled', enabled);
  },
  
  getStatus() {
    return {
      permission: this.permission,
      enabled: this.enabled,
      supported: 'Notification' in window
    };
  }
};

window.NotificationService = NotificationService;
NOTIFY

echo "✅ NotificationService обновлён для тёмной темы"

# Перезапуск
pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000"
  echo "✅ Приложение открыто!"
fi

echo ""
echo "🌙 ПРИОРИТЕТ 3 ВЫПОЛНЕН!"
echo ""
echo "✅ Добавлена тёмная тема:"
echo "  • Кнопка 🌙 в правом верхнем углу"
echo "  • Плавная анимация переключения"
echo "  • Сохранение выбора в localStorage"
echo "  • Все компоненты адаптированы"
echo "  • Уведомления работают в обеих темах"
echo ""
echo "Как использовать:"
echo "  1. Нажми на  вверху справа"
echo "  2. Тема переключится на тёмную"
echo "  3. При следующем открытии — останется тёмная"
echo ""
echo "📋 Следующий шаг: Семейный доступ"
