#!/bin/bash

# 1. Load variabel dari .env
if [ -f .env ]; then
    # Mengambil variabel tanpa karakter '#' (comment)
    export $(cat .env | grep -v '#' | xargs)
else
    echo "❌ ERROR: File .env tidak ditemukan di folder ini!"
    exit 1
fi

# 2. Validasi Variabel Wajib (Critical Check)
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ ERROR: Variabel 'PROJECT_NAME' tidak ditemukan di .env atau kosong!"
    exit 1
fi

if [ -z "$SITE_NAME" ]; then
    echo "❌ ERROR: Variabel 'SITE_NAME' tidak ditemukan di .env atau kosong!"
    exit 1
fi

echo "🚀 Memulai Update..."
echo "📂 Project: $PROJECT_NAME"
echo "🌐 Site:    $SITE_NAME"

# 3. Eksekusi Remote Command di Container
# -u frappe agar perintah dijalankan sebagai user frappe di dalam container
docker compose -p "$PROJECT_NAME" exec -u frappe backend /bin/bash -c "
    set -e # Berhenti jika ada satu command yang gagal
    
    echo '📥 Step 1: Syncing Code (kantin_stemba)...'
    cd apps/kantin_stemba
    git fetch origin
    git pull origin dev
    bench --site $SITE_NAME migrate
    bench --site $SITE_NAME clear-cache
"

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: Deployment selesai tanpa hambatan."
else
    echo "❌ FAILED: Terjadi kesalahan saat eksekusi di dalam container."
    exit 1
fi