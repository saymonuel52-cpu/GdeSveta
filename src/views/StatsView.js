/**
 * STATS VIEW
 * Страница статистики
 */

const StatsView = {
  container: null,
  
  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;
    
    this.render();
    this.setupListeners();
  },
  
  render() {
    if (!this.container) return;
    
    const today = Utils.getToday();
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    const weekAgoStr = weekAgo.toISOString().split('T')[0];
    
    const stats = EntryService.getStats(weekAgoStr, today);
    const priceStats = PriceService.getPopularServices(5);
    
    let html = `
      <div class="stats-box">
        <h3 style="margin-bottom:10px;">📊 За неделю</h3>
        <div class="stat-row"><span>Всего записей</span><span><b>${stats.total}</b></span></div>
        <div class="stat-row"><span> Работа</span><span><b>${stats.work}</b></span></div>
        <div class="stat-row"><span>👨‍‍👧 Семья</span><span><b>${stats.family}</b></span></div>
        <div class="stat-row"><span>✅ Выполнено</span><span><b style="color:#4caf50">${stats.done}</b></span></div>
        <div class="stat-row"><span>❌ Отменено</span><span><b style="color:#f44336">${stats.cancelled}</b></span></div>
      </div>
      
      <div class="stats-box">
        <h3 style="margin-bottom:10px;">💰 Доходы</h3>
        <div class="stat-row"><span>За неделю</span><span><b style="color:#ff6b9d">${stats.income}₽</b></span></div>
        <div class="stat-row"><span>Средний чек</span><span><b>${stats.work > 0 ? Math.round(stats.income / stats.work) : 0}₽</b></span></div>
      </div>
    `;
    
    if (priceStats.length > 0) {
      html += `
        <div class="stats-box">
          <h3 style="margin-bottom:10px;"> Популярные услуги</h3>
          ${priceStats.map(ps => `
            <div class="stat-row">
              <span>${ps.service}</span>
              <span><b>${ps.count} раз</b></span>
            </div>
          `).join('')}
        </div>
      `;
    }
    
    this.container.innerHTML = html;
  },
  
  setupListeners() {
    Events.on('entry:created', () => this.render());
    Events.on('entry:updated', () => this.render());
    Events.on('entry:deleted', () => this.render());
  }
};

window.StatsView = StatsView;
