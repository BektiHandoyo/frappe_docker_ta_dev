#!/bin/bash
cd "$(dirname "$0")"

# --- 1. LOAD ENV ---
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️  Peringatan: File .env tidak ditemukan, menggunakan nilai default."
fi

# --- 2. SET PROJECT NAME ---
# Prioritas: Argument $1, lalu Variabel PROJECT_NAME di .env, lalu default string
PROJECT_NAME_FINAL=${PROJECT_NAME:-"frappe-ta-default"}

echo "🚀 Memulai Project: $PROJECT_NAME_FINAL"

# Buat folder gitops per project
mkdir -p ./gitops/"$PROJECT_NAME_FINAL"

# --- 3. GENERATE CONFIG ---
echo "🛠️ Menghasilkan file konfigurasi YAML..."

docker compose --env-file .env \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.noproxy.yaml \
  -f overrides/compose.change-volume-name.yaml \
  config > ./gitops/"$PROJECT_NAME_FINAL"/docker-compose.yml

if [ ! -s ./gitops/"$PROJECT_NAME_FINAL"/docker-compose.yml ]; then
    echo "❌ Error: Gagal generate YAML!"
    exit 1
fi

# --- 4. JALANKAN ---
echo "🧹 Membersihkan container lama (jika ada)..."
docker compose --project-name "$PROJECT_NAME_FINAL" -f ./gitops/"$PROJECT_NAME_FINAL"/docker-compose.yml down

echo "🚚 Menyalakan container..."
docker compose --project-name "$PROJECT_NAME_FINAL" -f ./gitops/"$PROJECT_NAME_FINAL"/docker-compose.yml up -d --pull never --remove-orphans

echo "✅ Berhasil dijalankan!"
echo "📍 Nama Project: $PROJECT_NAME_FINAL"
echo "🔍 Cek log dengan: docker compose -p $PROJECT_NAME_FINAL logs -f"