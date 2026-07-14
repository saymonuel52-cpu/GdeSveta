/**
 * TEMPLATE SERVICE
 * Управление быстрыми шаблонами записей
 */

const TemplateService = {
  KEY: 'gdesveta_templates',
  
  getAll() {
    return Storage.get(this.KEY, []);
  },
  
  save(template) {
    const templates = this.getAll();
    const newTemplate = {
      id: Utils.generateId(),
      name: template.name,
      category: template.category,
      serviceName: template.serviceName,
      duration: template.duration,
      price: template.price,
      zone: template.zone,
      familyMemberId: template.familyMemberId || null,
      isDefault: template.isDefault || false
    };
    
    templates.push(newTemplate);
    Storage.set(this.KEY, templates);
    return newTemplate;
  },
  
  delete(id) {
    const templates = this.getAll().filter(t => t.id !== id);
    Storage.set(this.KEY, templates);
  },
  
  apply(id) {
    return this.getAll().find(t => t.id === id) || null;
  },
  
  // Демо-шаблоны при первом запуске
  initDefaults() {
    if (this.getAll().length === 0) {
      const defaults = [
        { name: 'Ноги + Бикини', category: 'work', serviceName: 'Шугаринг', duration: 90, price: 2300, zone: 'Ноги полностью + Бикини классическое' },
        { name: 'LPG Всего тела', category: 'work', serviceName: 'LPG-массаж', duration: 60, price: 2000, zone: 'Всё тело' },
        { name: 'Старший: Футбол', category: 'family', serviceName: 'Секция', duration: 90, price: 0, zone: 'Стадион', familyMemberId: 1 },
        { name: 'Малыш: Садик', category: 'family', serviceName: 'Садик', duration: 480, price: 0, zone: 'Садик "Солнышко"', familyMemberId: 3 }
      ];
      Storage.set(this.KEY, defaults);
    }
  }
};

window.TemplateService = TemplateService;
