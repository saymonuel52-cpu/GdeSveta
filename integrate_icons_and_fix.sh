#!/bin/bash
echo "🎨 ИНТЕГРАЦИЯ ИКОНОК И ИСПРАВЛЕНИЕ ПРИЛОЖЕНИЯ..."

# 1. Создаём папку для иконок
mkdir -p icons
mkdir -p icons/light
mkdir -p icons/dark

echo "✅ Папки созданы"

# 2. Создаём CSS с новыми стилями иконок
cat > styles/icons.css << 'ICONS_CSS'
/* === ИКОНКИ И НАВИГАЦИЯ === */

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.95);
  border: none;
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  min-width: 70px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.nav-item:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 12px rgba(255, 107, 157, 0.25);
}

.nav-item.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  box-shadow: 0 4px 16px rgba(255, 107, 157, 0.4);
}

.nav-item.active .nav-icon {
  filter: brightness(0) invert(1);
}

.nav-item.active .nav-label {
  color: white;
  font-weight: 600;
}

.nav-icon {
  width: 28px;
  height: 28px;
  object-fit: contain;
  transition: transform 0.2s;
}

.nav-item:hover .nav-icon {
  transform: scale(1.1);
}

.nav-label {
  font-size: 11px;
  color: #64748b;
  font-weight: 500;
  text-align: center;
  transition: color 0.2s;
}

/* Floating Action Button */
.fab {
  position: fixed;
  bottom: 30px;
  left: 50%;
  transform: translateX(-50%);
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
  border: none;
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 6px 24px rgba(255, 107, 157, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 1000;
}

.fab:hover {
  transform: translateX(-50%) scale(1.1) rotate(90deg);
  box-shadow: 0 8px 32px rgba(255, 107, 157, 0.5);
}

.fab:active {
  transform: translateX(-50%) scale(0.95);
}

.fab .material-icons-round,
.fab .icon-plus {
  font-size: 32px;
  color: white;
  font-weight: 300;
}

/* Theme Toggle */
.theme-toggle {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.3);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s;
  backdrop-filter: blur(10px);
}

.theme-toggle:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: rotate(180deg);
}

.theme-icon {
  width: 24px;
  height: 24px;
  transition: opacity 0.3s;
}

/* Dark theme adjustments */
body.dark-theme .nav-item {
  background: rgba(30, 41, 59, 0.95);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

body.dark-theme .nav-item.active {
  background: linear-gradient(135deg, #ff6b9d, #ff8e53);
}

body.dark-theme .nav-label {
  color: #94a3b8;
}
ICONS_CSS

echo "✅ CSS для иконок создан"

# 3. Обновляем index.html с новыми иконками
cat > index.html << 'INDEX_HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta name="theme-color" content="#ff6b9d">
  <title>ГдеСвета — Умный планировщик</title>
  
  <link rel="stylesheet" href="styles/main.css">
  <link rel="stylesheet" href="styles/icons.css">
  <link rel="manifest" href="manifest.json">
  
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet">
</head>
<body>
  <!-- Header -->
  <header class="modern-header">
    <div class="header-content">
      <div class="logo">
        <span class="logo-icon"></span>
        <div class="logo-text">
          <h1>ГдеСвета</h1>
          <span class="date" id="currentDate">17 Июля</span>
        </div>
      </div>
      
      <button class="theme-toggle" id="themeToggle" title="Сменить тему">
        <span class="material-icons-round" id="themeIcon">dark_mode</span>
      </button>
    </div>
  </header>

  <!-- Navigation -->
  <nav class="modern-nav">
    <button class="nav-item active" data-tab="calendar">
      <span class="material-icons-round nav-icon">calendar_today</span>
      <span class="nav-label">Календарь</span>
    </button>
    <button class="nav-item" data-tab="work">
      <span class="material-icons-round nav-icon">work</span>
      <span class="nav-label">Работа</span>
    </button>
    <button class="nav-item" data-tab="family">
      <span class="material-icons-round nav-icon">family_restroom</span>
      <span class="nav-label">Семья</span>
    </button>
    <button class="nav-item" data-tab="tasks">
      <span class="material-icons-round nav-icon">check_circle</span>
      <span class="nav-label">Задачи</span>
    </button>
    <button class="nav-item" data-tab="notes">
      <span class="material-icons-round nav-icon">note_alt</span>
      <span class="nav-label">Заметки</span>
    </button>
    <button class="nav-item" data-tab="stats">
      <span class="material-icons-round nav-icon">insights</span>
      <span class="nav-label">Статистика</span>
    </button>
  </nav>

  <!-- Main Content -->
  <main class="modern-main">
    <div id="tab-calendar" class="tab-content active">
      <div id="calendarView"></div>
    </div>
    
    <div id="tab-work" class="tab-content">
      <div class="tab-header">
        <h2><span class="material-icons-round">work</span> Работа</h2>
      </div>
      <div id="workView"></div>
    </div>
    
    <div id="tab-family" class="tab-content">
      <div class="tab-header">
        <h2><span class="material-icons-round">family_restroom</span> Семья</h2>
      </div>
      <div id="familyView"></div>
    </div>
    
    <div id="tab-tasks" class="tab-content">
      <div class="tab-header">
        <h2><span class="material-icons-round">check_circle</span> Задачи</h2>
      </div>
      <div id="tasksView"></div>
    </div>
    
    <div id="tab-notes" class="tab-content">
      <div class="tab-header">
        <h2><span class="material-icons-round">note_alt</span> Заметки</h2>
      </div>
      <div id="notesView"></div>
    </div>
    
    <div id="tab-stats" class="tab-content">
      <div class="tab-header">
        <h2><span class="material-icons-round">insights</span> Статистика</h2>
      </div>
      <div id="statsView"></div>
    </div>
  </main>

  <!-- Floating Action Button -->
  <button class="fab" onclick="openQuickAdd()" title="Добавить">
    <span class="material-icons-round" style="font-size: 32px;">add</span>
  </button>

  <!-- Scripts -->
  <script src="src/core/storage.js"></script>
  <script src="src/core/events.js"></script>
  <script src="src/core/utils.js"></script>
  <script src="src/core/store.js"></script>
  
  <script src="src/models/Entry.js"></script>
  <script src="src/models/Note.js"></script>
  <script src="src/models/PriceItem.js"></script>
  <script src="src/models/FamilyMember.js"></script>
  
  <script src="src/services/EntryService.js"></script>
  <script src="src/services/NoteService.js"></script>
  <script src="src/services/PriceService.js"></script>
  <script src="src/services/FamilyService.js"></script>
  
  <script src="src/views/CalendarView.js"></script>
  <script src="src/views/WorkView.js"></script>
  <script src="src/views/FamilyView.js"></script>
  <script src="src/views/NotesView.js"></script>
  <script src="src/views/StatsView.js"></script>
  <script src="src/views/TasksView.js"></script>
  
  <script src="app.js"></script>
</body>
</html>
INDEX_HTML

echo "✅ index.html обновлён"

# 4. Git + сборка
echo ""
echo "🔄 Отправка на GitHub..."

git add .
git commit -m "feat: Интеграция новых иконок и улучшенный UI"
git push origin main

echo "✅ Готово! Теперь собери APK:"
echo "cd ~/GdeSvet"
echo "./fix_and_build.sh"

