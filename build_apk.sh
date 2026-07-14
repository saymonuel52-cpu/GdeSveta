#!/bin/bash
echo " Сборка APK..."

# Проверяем что Android проект существует
if [ ! -d "android" ]; then
  echo "❌ Android папка не найдена"
  echo "Запусти сначала: ./setup_capacitor.sh"
  exit 1
fi

cd android

# Метод 1: Через Gradle (если установлен)
if command -v gradle &> /dev/null; then
  echo "Сборка через Gradle..."
  gradle assembleDebug
  
  if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "✅ APK собран!"
    cp app/build/outputs/apk/debug/app-debug.apk ../gdesveta.apk
    echo "📱 APK: ~/GdeSvet/gdesveta.apk"
  else
    echo "❌ Ошибка сборки"
  fi
else
  echo "⚠️  Gradle не установлен"
  echo ""
  echo "Варианты:"
  echo "1. Установить Gradle: pkg install gradle"
  echo "2. Использовать встроенный Gradle wrapper:"
  echo ""
  
  if [ -f "gradlew" ]; then
    echo "Запуск через gradlew..."
    chmod +x gradlew
    ./gradlew assembleDebug
    
    if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
      echo "✅ APK собран!"
      cp app/build/outputs/apk/debug/app-debug.apk ../gdesveta.apk
      echo "📱 APK: ~/GdeSvet/gdesveta.apk"
    fi
  else
    echo "❌ gradlew не найден"
    echo ""
    echo "Рекомендую использовать онлайн-сервис:"
    echo "https://www.webintoapp.com/"
  fi
fi

cd ..
