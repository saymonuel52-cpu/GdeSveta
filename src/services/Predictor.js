const Predictor = {
  getClientsToRemind: function() {
    const entries = Store.getEntries().filter(e => e.category === 'work' && e.status === 'done');
    const reminders = [];
    const clientHistory = {};
    entries.forEach(entry => {
      if (!clientHistory[entry.name]) clientHistory[entry.name] = [];
      clientHistory[entry.name].push(new Date(entry.date));
    });
    const today = new Date();
    for (const [name, dates] of Object.entries(clientHistory)) {
      if (dates.length < 2) continue;
      dates.sort((a, b) => b - a);
      const lastVisit = dates[0];
      let totalDays = 0;
      for (let i = 0; i < dates.length - 1; i++) {
        totalDays += Math.ceil(Math.abs(dates[i] - dates[i+1]) / (1000 * 60 * 60 * 24)); 
      }
      const avgInterval = Math.round(totalDays / (dates.length - 1));
      const daysSinceLastVisit = Math.ceil(Math.abs(today - lastVisit) / (1000 * 60 * 60 * 24));
      if (daysSinceLastVisit >= (avgInterval - 3)) {
        reminders.push({ name: name, daysAgo: daysSinceLastVisit, avgInterval: avgInterval });
      }
    }
    return reminders;
  },
  getMorningBriefing: function() {
    const todayStr = new Date().toISOString().split('T')[0];
    const allEntries = Store.getEntries();
    const todayWork = allEntries.filter(e => e.category === 'work' && e.date === todayStr);
    const todayFamily = allEntries.filter(e => (e.category === 'family' || e.category === 'dog') && e.date === todayStr);
    return {
      date: new Date().toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' }),
      workCount: todayWork.length,
      familyCount: todayFamily.length,
      income: todayWork.reduce((sum, e) => sum + (parseInt(e.price) || 0), 0),
      reminders: this.getClientsToRemind()
    };
  }
};
window.Predictor = Predictor;
