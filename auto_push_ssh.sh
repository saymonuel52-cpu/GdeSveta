#!/bin/bash
echo "🚀 Начинаю автоматическую отправку на GitHub через SSH..."

# 1. Создаем .gitignore, чтобы не грузить мусор
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
echo "✅ .gitignore создан"

# 2. Проверяем и создаем SSH ключ (без пароля для автоматизации)
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "🔑 Генерирую SSH-ключ..."
  ssh-keygen -t ed25519 -C "saymonuel52-cpu@users.noreply.github.com" -N "" -f ~/.ssh/id_ed25519 > /dev/null 2>&1
  echo "✅ SSH-ключ создан!"
  echo ""
  echo "⚠️ ВАЖНО: Скопируй вывод следующей команды и добавь его в GitHub:"
  echo "   Настройки GitHub -> SSH and GPG keys -> New SSH key"
  echo ""
  cat ~/.ssh/id_ed25519.pub
  echo ""
  echo "👉 После добавления ключа в GitHub, нажми Enter, чтобы продолжить..."
  read -p "Готово? (Enter)"
else
  echo "✅ SSH-ключ уже существует"
fi

# 3. Настраиваем Git
git config --global user.name "saymonuel52-cpu"
git config --global user.email "saymonuel52-cpu@users.noreply.github.com"

# 4. Инициализация и привязка репозитория
if [ ! -d ".git" ]; then
  git init
  echo "✅ Git инициализирован"
fi

git remote remove origin 2>/dev/null
git remote add origin git@github.com:saymonuel52-cpu/GdeSveta.git
echo "✅ Привязан SSH-репозиторий"

# 5. Коммит и отправка
echo "⏳ Добавление файлов..."
git add .
git commit -m "Auto-commit: ГдеСвета v3 (исправлены баги, темная тема, улучшенные формы)"

echo "⏳ Отправка на GitHub..."
git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
  echo ""
  echo "🎉 УСПЕХ! Код залит на GitHub!"
  echo "🔗 Ссылка: https://github.com/saymonuel52-cpu/GdeSveta"
else
  echo ""
  echo "❌ ОШИБКА. Скорее всего, ключ не добавлен в GitHub или нет доступа."
  echo "Выполни: cat ~/.ssh/id_ed25519.pub"
  echo "И добавь этот ключ в: https://github.com/settings/keys"
fi
