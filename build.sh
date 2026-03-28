#!/bin/bash
# Pastikan di folder project
cd "$(dirname "$0")"

# --- 1. VALIDASI .ENV & AMBIL VARIABEL ---
if [ ! -f .env ]; then
    echo "❌ File '.env' tidak ditemukan! Salin dari env.example dulu."
    exit 1
fi

# Ambil nama image dan tag dari .env
# Kita pakai 'sed' untuk hapus whitespace atau quote jika ada
IMAGE_NAME=$(grep '^CUSTOM_IMAGE=' .env | cut -d '=' -f2 | sed 's/["'\'']//g')
IMAGE_TAG=$(grep '^CUSTOM_TAG=' .env | cut -d '=' -f2 | sed 's/["'\'']//g')

# Fallback jika di .env belum diisi
IMAGE_NAME=${IMAGE_NAME:-"erpnext"}
IMAGE_TAG=${IMAGE_TAG:-"version-15"}

# --- 2. VALIDASI APPS.JSON ---
if [ ! -f apps.json ]; then
    echo "❌ File 'apps.json' tidak ditemukan!"
    echo "💡 Silakan buat file 'apps.json' di folder ini."
    echo "💡 Bisa copy dari development/apps-example.json"
    exit 1
fi

# 3. Generate BASE64
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

# 4. Build Custom Image dengan tag dari .env
echo "🐳 Building custom image: ${IMAGE_NAME}:${IMAGE_TAG}..."

docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-15 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag="${IMAGE_NAME}:${IMAGE_TAG}" \
  --file=images/layered/Containerfile .

echo "✅ Build selesai! Image ${IMAGE_NAME}:${IMAGE_TAG} siap digunakan."
echo "🚀 Sekarang kamu bisa jalankan: ./up.sh [nama_project]"