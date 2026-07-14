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
