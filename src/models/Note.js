/**
 * NOTE MODEL
 */
const Note = {
  create(data) {
    return {
      id: Utils.generateId(),
      title: data.title || '',
      text: data.text || '',
      category: data.category || 'general',
      date: data.date || null,
      priority: data.priority || 'normal',
      completed: data.completed || false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  },
  
  validate(note) {
    const errors = [];
    if (!note.title || note.title.trim() === '') errors.push('Заголовок обязателен');
    return { valid: errors.length === 0, errors };
  },
  
  getCategoryIcon(category) {
    const icons = {
      general: '',
      important: '⭐',
      shopping: '',
      ideas: '',
      reminder: '⏰'
    };
    return icons[category] || '';
  }
};
window.Note = Note;
