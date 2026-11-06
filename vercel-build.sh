#!/bin/bash
set -e

echo "=== Instalando Flutter SDK para Build na Vercel ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:$(pwd)/flutter/bin"
flutter config --enable-web
flutter doctor
flutter build web --release

echo "=== Build Flutter Web concluído com sucesso! ==="
