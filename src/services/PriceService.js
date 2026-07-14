/**
 * PRICE SERVICE
 * Бизнес-логика для управления прайсом
 */

const PriceService = {
  getAll() {
    return Store.getPriceList();
  },
  
  getActive() {
    return Store.getPriceList().filter(item => item.active);
  },
  
  getById(id) {
    return Store.getPriceList().find(item => item.id === id);
  },
  
  getByService(serviceType) {
    return Store.getPriceList().filter(item => item.service === serviceType && item.active);
  },
  
  create(data) {
    const item = PriceItem.create(data);
    const validation = PriceItem.validate(item);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    Store.addPriceItem(item);
    Events.emit('price:created', item);
    return item;
  },
  
  update(id, updates) {
    const item = this.getById(id);
    if (!item) throw new Error('Услуга не найдена');
    
    const updated = { ...item, ...updates, updatedAt: new Date().toISOString() };
    const validation = PriceItem.validate(updated);
    
    if (!validation.valid) {
      throw new Error(validation.errors.join(', '));
    }
    
    const items = Store.getPriceList();
    const index = items.findIndex(i => i.id === id);
    items[index] = updated;
    Storage.set('gdesveta_store', { ...Storage.get('gdesveta_store'), priceList: items });
    
    Events.emit('price:updated', updated);
    return updated;
  },
  
  delete(id) {
    Store.deletePriceItem(id);
    Events.emit('price:deleted', id);
  },
  
  toggleActive(id) {
    const item = this.getById(id);
    if (!item) throw new Error('Услуга не найдена');
    
    return this.update(id, { active: !item.active });
  },
  
  getTotalIncome(entries) {
    return entries.reduce((sum, entry) => sum + (entry.price || 0), 0);
  },
  
  getPopularServices(limit = 5) {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status !== 'cancelled');
    const serviceCount = {};
    
    entries.forEach(entry => {
      serviceCount[entry.service] = (serviceCount[entry.service] || 0) + 1;
    });
    
    return Object.entries(serviceCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([service, count]) => ({ service, count }));
  }
};

window.PriceService = PriceService;
