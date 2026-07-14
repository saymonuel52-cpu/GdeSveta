/**
 * NOTE SERVICE
 * Бизнес-логика для работы с заметками
 */

const NoteService = {
  getAll() {
    return Store.getNotes();
  },
  
  getByCategory(category) {
    return Store.getNotes().filter(n => n.category === category);
  },
  
  getByDate(date) {
    return Store.getNotes().filter(n => n.date === date);
  },
  
  create(data) {
    const note = Note.create(data);
    const validation = Note.validate(note);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addNote(note);
    Events.emit('note:created', note);
    return note;
  },
  
  update(id, updates) {
    const note = Store.getNotes().find(n => n.id === id);
    if (!note) throw new Error('Заметка не найдена');
    
    const updated = { ...note, ...updates, updatedAt: new Date().toISOString() };
    Store.updateNote(id, updated);
    Events.emit('note:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deleteNote(id);
    Events.emit('note:deleted', id);
  },
  
  toggleComplete(id) {
    const note = Store.getNotes().find(n => n.id === id);
    if (!note) throw new Error('Заметка не найдена');
    
    return this.update(id, { completed: !note.completed });
  },
  
  getShoppingList() {
    return this.getByCategory('shopping').filter(n => !n.completed);
  },
  
  getImportant() {
    return this.getByCategory('important');
  }
};

window.NoteService = NoteService;
