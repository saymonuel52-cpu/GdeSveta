#!/bin/bash
echo "🔧 ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ attachEvents"

# 1. ИСПРАВЛЯЕМ NoteCard.js
echo "1. 🔧 Исправляю NoteCard.js..."

cat > src/ui/components/NoteCard.js << 'NOTECARD'
/**
 * NOTE CARD COMPONENT v2.0
 * Без attachEvents — используем inline onclick
 */

const NoteCard = {
  render(note) {
    const icon = Note.getCategoryIcon(note.category);
    
    return `
      <div class="note-card ${note.category} ${note.completed ? 'completed' : ''}" data-id="${note.id}">
        <div class="note-title">${icon} ${note.title}</div>
        ${note.text ? `<div class="note-text">${note.text}</div>` : ''}
        <div class="note-meta">
          <span>${note.date ? Utils.formatDate(note.date, 'short') : 'Без даты'}</span>
          <span>${icon}</span>
        </div>
        <div class="note-actions">
          <button class="btn-edit" onclick="window.editNote(${note.id})">✏️</button>
          <button class="btn-del" onclick="window.deleteNote(${note.id})">🗑️</button>
        </div>
      </div>
    `;
  }
};

window.NoteCard = NoteCard;

// Глобальные функции для заметок
window.editNote = function(id) {
  console.log(' editNote:', id);
  if (typeof openNoteForm !== 'undefined') {
    openNoteForm(id);
  }
};

window.deleteNote = function(id) {
  console.log(' deleteNote:', id);
  try {
    if (typeof Modal === 'undefined') {
      if (confirm('Удалить заметку?')) {
        NoteService.delete(id);
        if (typeof currentTab !== 'undefined' && currentTab === 'notes') {
          NotesView.render();
        }
        alert('✅ Заметка удалена!');
      }
      return;
    }
    
    Modal.confirm('Удалить заметку?', () => {
      NoteService.delete(id);
      Modal.close();
      setTimeout(() => {
        Modal.alert('✅ Заметка удалена!');
        if (typeof currentTab !== 'undefined' && currentTab === 'notes') {
          NotesView.render();
        }
      }, 100);
    });
  } catch (e) {
    console.error('❌ Ошибка deleteNote:', e);
    alert('Ошибка: ' + e.message);
  }
};
NOTECARD

echo "✅ NoteCard.js исправлен"

# 2. ИСПРАВЛЯЕМ NotesView.js
echo "2. 🔧 Исправляю NotesView.js..."

cat > src/views/NotesView.js << 'NOTESVIEW'
/**
 * NOTES VIEW v2.0
 * Без attachEvents — используем inline onclick
 */

const NotesView = {
  container: null,
  filter: 'all',
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    let notes = NoteService.getAll();
    
    if (this.filter !== 'all') {
      notes = notes.filter(n => n.category === this.filter);
    }
    
    notes.sort((a, b) => (b.date || '').localeCompare(a.date || ''));
    
    let html = `
      <div class="note-filters">
        <button class="note-filter ${this.filter === 'all' ? 'active' : ''}" data-filter="all">Все</button>
        <button class="note-filter ${this.filter === 'important' ? 'active' : ''}" data-filter="important">⭐ Важное</button>
        <button class="note-filter ${this.filter === 'shopping' ? 'active' : ''}" data-filter="shopping">🛒 Покупки</button>
        <button class="note-filter ${this.filter === 'ideas' ? 'active' : ''}" data-filter="ideas">💡 Идеи</button>
      </div>
    `;
    
    if (notes.length === 0) {
      html += '<div class="empty-state">Нет заметок</div>';
    } else {
      notes.forEach(note => {
        html += NoteCard.render(note);
      });
    }
    
    this.container.innerHTML = html;
    
    // Фильтры
    this.container.querySelectorAll('.note-filter').forEach(btn => {
      btn.addEventListener('click', () => {
        this.filter = btn.dataset.filter;
        this.render();
      });
    });
  },
  
  setupListeners() {
    Events.on('note:created', () => this.render());
    Events.on('note:updated', () => this.render());
    Events.on('note:deleted', () => this.render());
  }
};

window.NotesView = NotesView;
NOTESVIEW

echo "✅ NotesView.js исправлен"

# 3. ОЧИЩАЕМ кэш и старые файлы
echo "3. 🗑️ Очищаю кэш..."
rm -rf www/
rm -rf android/app/src/main/assets/public/

echo "✅ Кэш очищен"

# 4. Перезапуск
echo "4. 🚀 Перезапуск..."

pkill -f "python.*http.server" 2>/dev/null
sleep 1
python -m http.server 8000 > /dev/null 2>&1 &
sleep 2

if command -v termux-open-url &> /dev/null; then
  termux-open-url "http://localhost:8000?v=$(date +%s)"
  echo "✅ Браузер открыт!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "✅ attachEvents УДАЛЁН ВЕЗДЕ!"
echo "═══════════════════════════════════════"
echo ""
echo " ЧТО СДЕЛАНО:"
echo "  1. ✅ NoteCard.js — без attachEvents"
echo "  2. ✅ NotesView.js — без attachEvents"
echo "  3. ✅ Очищены папки www/ и android/"
echo ""
echo " ТЕСТИРОВАНИЕ:"
echo ""
echo "1. Открой приложение"
echo "2. Попробуй переключить дни в календаре"
echo "3. Попробуй открыть вкладку 'Заметки'"
echo "4. Попробуй удалить/изменить запись"
echo ""
echo "Ошибка 'attachEvents is not a function' НЕ должна появляться!"
echo ""
echo "Напиши 'работает' или опиши что происходит!"
