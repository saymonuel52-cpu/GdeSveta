/**
 * PREDICTION ENGINE
 * Анализирует историю и дает умные подсказки
 */

const Predictor = {
  // Получает клиентов, которым пора напомнить о себе (не были дольше среднего интервала)
  getClientsToRemind: function() {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status === 'done');
    const reminders = [];
    const clientHistory = {};

    // Группируем по имени клиента
    entries.forEach(entry => {
      if (!clientHistory[entry.name]) clientHistory[entry.name] = [];
      clientHistory[entry.name].push(new Date(entry.date));
    });

    const today = new Date();

    for (const [name, dates] of Object.entries(clientHistory)) {
      if (dates.length < 2) continue; // Нужно минимум 2 визита для прогноза

      dates.sort((a, b) => b - a); // Сортируем от новых к старым
      const lastVisit = dates[0];
      
      // Считаем средний интервал в днях
      let totalDays = 0;
      for (let i = 0; i < dates.length - 1; i++) {
        const diffTime = Math.abs(dates[i] - dates[i+1]);
        totalDays += Math.ceil(diffTime / (1000 * 60 * 60 * 24)); 
      }
      const avgInterval = Math.round(totalDays / (dates.length - 1));
      
      const daysSinceLastVisit = Math.ceil(Math.abs(today - lastVisit) / (1000 * 60 * 60 * 24));
      
      // Если прошло больше времени, чем средний интервал минус 3 дня (запас)
      if (daysSinceLastVisit >= (avgInterval - 3)) {
        reminders.push({
          name: name,
          lastVisit: lastVisit.toLocaleDateString('ru-RU'),
          daysAgo: daysSinceLastVisit,
          avgInterval: avgInterval
        });
      }
    }
    return reminders;
  },

  // Генерирует данные для утреннего брифинга
  getMorningBriefing: function() {
    const todayStr = new Date().toISOString().split('T')[0];
    const allEntries = Store.getEntries();
    
    const todayWork = allEntries.filter(e => e.category === 'work' && e.date === todayStr);
    const todayFamily = allEntries.filter(e => (e.category === 'family' || e.category === 'dog') && e.date === todayStr);
    const reminders = this.getClientsToRemind();
    
    const todayIncome = todayWork.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0);

    return {
      date: new Date().toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }),
      workCount: todayWork.length,
      familyCount: todayFamily.length,
      income: todayIncome,
      reminders: reminders
    };
  }
};

window.Predictor = Predictor;
