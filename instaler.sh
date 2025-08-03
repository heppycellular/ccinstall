#!/bin/bash

# --- URL File Pre-compiled ---
CCMINER_BIN_URL="https://raw.githubusercontent.com/heppycellular/ccinstall/master/ccminer"
CONFIG_JSON_URL="https://raw.githubusercontent.com/heppycellular/ccinstall/master/config.json" 
START_SH_URL="https://raw.githubusercontent.com/heppycellular/ccinstall/master/start.sh" 
# Jalankan download untuk semua file
download_file "$START_SH_URL" "start.sh"
download_file "$CONFIG_JSON_URL" "config.json"
download_file "$CCMINER_BIN_URL" "ccminer"

echo "--- Download & Setup CCminer Verus Coin  ---"
echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

# --- Minta Input dari Pengguna ---
read -p "WALLET  (contoh: R*****.Q*****.A*****): " WALLET_ADDRESS
read -p "WORKER (Enter'miner'): " WORKER_NAME
WORKER_NAME=${WORKER_NAME:-default_miner}

# Nilai threads akan tetap 8, tidak dideteksi secara otomatis
DEFAULT_THREADS=8

echo ""
echo "Miner Anda:"
echo "Wallet : $WALLET_ADDRESS"
echo "Worker : $WORKER_NAME"
echo "Thread : $DEFAULT_THREADS "
echo ""

read -p "Enter, Ctrl+C membatalkan..."

---

### Persiapan Direktori

echo "Membuat'ccminer'..."
---

### Mengunduh File

download_file() {
    local url="$1"
    local output="$2"

    wget -q --show-progress "$output" "$url"
    if [ $? -ne 0 ]; then
        echo "$output Gagal" 
        exit 1
    else
        echo "$output Done"
    fi
}

# Fungsi chmod
set_permission "ccminer"
set_permission "start.sh"
set_permission() {
    local file="$1"
    chmod +x "$file"
    if [ $? -ne 0 ]; then
        echo "$file Gagal izin"  # hanya file gagal
        exit 1
    else
        echo "$file Izin Done"
    fi
    echo "Done."
}
---

###  Konfigurasi (config.json)

echo "konfigurasi Miner..."
# Menggunakan 'EOF' tanpa kutip tunggal agar variabel shell bisa diekspansi
cat << EOF > config.json
{
    "pools":
        [{
            "name": "AP-VIPOR",
            "url": "stratum+tcp://ap.vipor.net:5040",
            "timeout": 180,
            "disabled": 0
        },
        {
            "name": "USSE-VIPOR",
            "url": "stratum+tcp://usse.vipor.net:5040",
            "timeout": 180,
            "disabled": 0
        },
        {
            "name": "NA-LUCKPOOL",
            "url": "stratum+tcp://na.luckpool.net:3960",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "AIH-LOW",
            "url": "stratum+tcp://verus.aninterestinghole.xyz:9998",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "WW-ZERGPOOL",
            "url": "stratum+tcp://verushash.mine.zergpool.com:3300",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "VPOOL-LOW",
            "url": "stratum+tcp://pool.verus.io:9998",
            "timeout": 180,
            "disabled": 1
        },
        {
            "name": "US-CLOUDIKO",
            "url": "stratum+tcp://us.cloudiko.io:9999",
            "timeout": 180,
            "disabled": 1
        }],

    "user": "${WALLET_ADDRESS}.${WORKER_NAME}",
    "pass": "",
    "algo": "verus",
    "threads": ${DEFAULT_THREADS},
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOF
echo "Info konfigurasi Miner Anda."

---

### 5. Menulis Ulang (start.sh) untuk Pemantauan Otomatis

echo "Cek Miner"
cat << 'EOF_START' > start.sh
#!/bin/bash

MINER_LOG="miner_output.log" # File log untuk output miner

echo "Memulai Mining. Memantau koneksi..."
# Hapus log lama jika ada
rm -f "${MINER_LOG}"

# Jalankan ccminer dan simpan outputnya ke file log sementara
# Gunakan 'stdbuf -oL' untuk memastikan output ditulis ke log secara real-time
./ccminer 2>&1 | stdbuf -oL tee "${MINER_LOG}" &

MINER_PID=$! # Dapatkan PID dari ccminer yang baru saja dimulai

# "accepted" muncul di log,  30 detik
TIMEOUT=30
ELAPSED=0
SUCCESS=false

echo "'accepted' atau 'Mining on'"

while [ $ELAPSED -lt $TIMEOUT ]; do
    if grep -qE "accepted|Mining on" "${MINER_LOG}"; then
        echo "--------------------------------------------------------"
        echo "Miner Done! Log terakhir:"
        tail -n 5 "${MINER_LOG}" # Tampilkan beberapa baris terakhir
        echo "--------------------------------------------------------"
        SUCCESS=true
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ "$SUCCESS" = true ]; then
    echo "Miner  ${MINER_LOG}"
    echo "real-time: tail -f ${MINER_LOG}"
    # Cukup informasikan pengguna
else
    echo "--------------------------------------------------------"
    echo "Timeout! error ${TIMEOUT} detik."
    echo "Error log (${MINER_LOG}) untuk detail error."
    echo "--------------------------------------------------------"
fi
EOF_START
chmod +x start.sh
echo "Izin Miner"

---

### 6. Menjalankan Miner Otomatis & Informasi Penting

echo "---"
echo "--- Setup Selesai! ---"
echo ""
echo ""


# --- Otomatis Menjalankan Miner (dengan pemantauan awal) ---
echo ""
echo "========================================"
echo "Miner otomatis jalankan"
sleep 2 # Beri sedikit jeda sebelum menjalankan
cd ~/ccminer
./start.sh # Menjalankan start.sh yang baru dimodifikasi
echo "========================================"
echo ""

