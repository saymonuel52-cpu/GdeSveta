#!/bin/bash
echo "🚀 Начинаю автоматическую отправку на GitHub..."

# Создаем правильный .gitignore
cat > .gitignore << 'GITIGNORE'
node_modules/
android/
www/
package-lock.json
logs/
*.log
*.apk
*.zip
.DS_Store
Thumbs.db
GITIGNORE
echo "✅ .gitignore создан (мусор не попадет на GitHub)"

# Настраиваем Git (если еще не настроен)
git config --global user.name "saymonuel52-cpu"
git config --global user.email "saymonuel52-cpu@users.noreply.github.com"
echo "✅ Настройки Git проверены"

# Инициализация и привязка к твоему репозиторию
if [ ! -d ".git" ]; then
  git init
  echo "✅ Git инициализирован"
fi

# Удаляем старый remote если был, и добавляем твой новый
git remote remove origin 2>/dev/null
git remote add origin https://github.com/saymonuel52-cpu/GdeSveta.git
echo "✅ Репозиторий привязан"

# Добавляем файлы, коммитим и отправляем
echo "⏳ Добавление файлов и коммит..."
git add .
git commit -m "Auto-commit: ГдеСвета v3 (исправлены баги, темная тема, улучшенные формы)"

echo "⏳ Отправка на GitHub (это может занять минуту)..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
  echo ""
  echo "🎉 УСПЕХ! Код залит на GitHub!"
  echo "🔗 Ссылка: https://github.com/saymonuel52-cpu/GdeSveta"
else
  echo ""
  echo "❌ ОШИБКА при отправке. Возможно, нужно ввести логин/пароль GitHub или настроить SSH."
fi
