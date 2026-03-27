#!/bin/bash
cd "$(dirname "$0")"

# --- 1. LOAD ENV ---
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ Error: File .env tidak ditemukan!"
    exit 1
fi

# --- 2. SET PROJECT NAME ---
# Harus sama dengan logika di up.sh
PROJECT_NAME_FINAL=${1:-${PROJECT_NAME:-"frappe-ta-default"}}

# --- 3. VALIDASI VARIABEL ---
# Fallback ke input manual jika di .env kosong
DB_ROOT_PWD=${DB_PASSWORD:-$(read -sp "Masukkan DB Root Password: " p; echo $p)}
echo ""
ADM_PWD=${ADMIN_PASSWORD:-$(read -sp "Masukkan Admin Password: " p; echo $p)}
echo ""
S_NAME=${SITE_NAME:-"frontend"}

echo "🏗️ Memulai Setup Site untuk Project: $PROJECT_NAME_FINAL"

# --- 4. EKSEKUSI SETUP ---
# Tunggu beberapa detik memastikan DB siap
echo "⏳ Menunggu DB siap (10 detik)..."
sleep 10

echo "🌟 Membuat site baru: $S_NAME..."
docker compose -p "$PROJECT_NAME_FINAL" exec backend bench new-site "$S_NAME" \
    --mariadb-user-host-login-scope='%' \
    --db-root-password "$DB_ROOT_PWD" \
    --admin-password "$ADM_PWD" \
    --install-app erpnext \
    --set-default

echo "📦 Menginstall aplikasi kustom: kantin_stemba..."
docker compose -p "$PROJECT_NAME_FINAL" exec backend bench --site "$S_NAME" install-app kantin_stemba
docker compose -p "$PROJECT_NAME_FINAL" exec backend bench use "$S_NAME"

echo "✅ Setup Selesai! Site $S_NAME siap digunakan di project $PROJECT_NAME_FINAL."