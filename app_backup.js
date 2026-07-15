/**
 * ГдеСвета - v10.0
 * Emergency Recovery Version
 */

console.log('🚀 ГдеСвета загружается...');

// === БАЗОВАЯ ИНИЦИАЛИЗАЦИЯ ===
window.appInitialized = false;

// Инициализация приложения
window.initApp = function() {
  if (window.appInitialized) {
    console.log('⚠️ Приложение уже инициализировано');
    return;
  }
  
  console.log('✅ Инициализация приложения...');
  
  // Проверяем наличие основных компонентов
  if (typeof Storage === 'undefined') {
    console.error('❌ Storage не найден!');
    return;
  }
  
  if (typeof Store === 'undefined') {
    console.error('❌ Store не найден!');
    return;
  }
  
  if (typeof CalendarView === 'undefined') {
    console.error('❌ CalendarView не найден!');
    return;
  }
  
  // Инициализируем первую вкладку
  setTimeout(() => {
    switchTab('calendar');
    window.appInitialized = true;
    console.log('✅ Приложение готово!');
  }, 500);
};

// === ПЕРЕКЛЮЧЕНИЕ ВКЛАДОК ===
window.switchTab = function(tabName) {
  console.log('🔄 Переключение на вкладку:', tabName);
  
  // Убираем активный класс со всех кнопок
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.classList.remove('active');
  });
  
  // Активируем нужную кнопку
  const activeBtn = document.querySelector(`.nav-item[data-tab="${tabName}"]`);
  if (activeBtn) {
    activeBtn.classList.add('active');
  }
  
  // Скрываем все вкладки
  document.querySelectorAll('.tab-content').forEach(tab => {
    tab.classList.remove('active');
    tab.style.display = 'none';
  });
  
  // Показываем нужную вкладку
  const activeTab = document.getElementById(`tab-${tabName}`);
  if (activeTab) {
    activeTab.classList.add('active');
    activeTab.style.display = 'block';
    
    // Инициализируем view
    setTimeout(() => {
      switch(tabName) {
        case 'calendar':
          if (typeof CalendarView !== 'undefined') {
            CalendarView.render();
          }
          break;
        case 'work':
          if (typeof WorkView !== 'undefined') {
            WorkView.render();
          }
          break;
        case 'family':
          if (typeof FamilyView !== 'undefined') {
            FamilyView.init('familyView');
          }
          break;
        case 'notes':
          if (typeof NotesView !== 'undefined') {
            NotesView.render();
          }
          break;
        case 'stats':
          if (typeof StatsView !== 'undefined') {
            StatsView.render();
          }
          break;
        case 'tasks':
          if (typeof TasksView !== 'undefined') {
            TasksView.render();
          }
          break;
        case 'dog':
          if (typeof DogView !== 'undefined') {
            DogView.init('dogView');
          }
          break;
      }
    }, 100);
  } else {
    console.error('❌ Вкладка не найдена:', tabName);
  }
};

// === ОБРАБОТЧИКИ НАВИГАЦИИ ===
function setupNavigation() {
  console.log('🔧 Настройка навигации...');
  
  document.querySelectorAll('.nav-item').forEach(btn => {
    btn.addEventListener('click', function() {
      const tabName = this.dataset.tab;
      console.log(' Нажата вкладка:', tabName);
      switchTab(tabName);
    });
  });
}

// === ОТКРЫТИЕ ФОРМЫ ДОБАВЛЕНИЯ ===
window.openQuickAdd = function() {
  console.log('➕ Открытие формы добавления');
  
  // Определяем текущую вкладку
  const activeTab = document.querySelector('.nav-item.active');
  const tabName = activeTab ? activeTab.dataset.tab : 'calendar';
  
  console.log('  Текущая вкладка:', tabName);
  
  // Открываем соответствующую форму
  if (tabName === 'calendar' || tabName === 'work') {
    if (typeof openWorkForm === 'function') {
      openWorkForm();
    } else {
      Modal.alert('Форма работы будет добавлена');
    }
  } else if (tabName === 'family') {
    if (typeof openFamilyForm === 'function') {
      openFamilyForm();
    } else {
      Modal.alert('Форма семьи будет добавлена');
    }
  } else if (tabName === 'notes') {
    if (typeof openNoteForm === 'function') {
      openNoteForm();
    } else {
      Modal.alert('Форма заметок будет добавлена');
    }
  } else if (tabName === 'tasks') {
    if (typeof openTaskForm === 'function') {
      openTaskForm();
    } else {
      Modal.alert('Форма задач будет добавлена');
    }
  } else if (tabName === 'dog') {
    if (typeof openDogForm === 'function') {
      openDogForm();
    } else {
      Modal.alert('Форма собаки будет добавлена');
    }
  }
};

// === ЗАПУСК ПРИ ЗАГРУЗКЕ ===
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() {
    console.log('📄 DOM загружен');
    setupNavigation();
    initApp();
  });
} else {
  console.log('📄 DOM уже загружен');
  setupNavigation();
  initApp();
}

console.log('✅ Базовый app.js загружен');
