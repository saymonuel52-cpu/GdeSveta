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
