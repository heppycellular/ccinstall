#!/bin/bash

# --- URL File Pre-compiled ---
CCMINER_BIN_URL="https://raw.githubusercontent.com/heppycellular/ccinstall/master/ccminer"
CONFIG_JSON_URL="https://raw.githubusercontent.com/heppycellular/ccinstall/master/config.json"

# --- Fungsi download ---
download_file() {
    local url="$1"
    local output="$2"
    echo "Mengunduh $output ..."
    wget -q --show-progress -O "$output" "$url"
    if [ $? -ne 0 ]; then
        echo "$output Gagal"
        exit 1
    else
        echo "$output Done"
    fi
}

# --- Fungsi chmod ---
set_permission() {
    local file="$1"
    chmod +x "$file"
    if [ $? -ne 0 ]; then
        echo "$file Gagal izin"
        exit 1
    else
        echo "$file Izin Done"
    fi
}

echo "--- Setup CCminer Verus Coin ---"
echo "++++++++++++++++++++++++++++++++++++++++++++++"

# --- Download ccminer jika belum ada ---
if [ ! -f "ccminer" ]; then
    download_file "$CCMINER_BIN_URL" "ccminer"
    set_permission "ccminer"
else
    echo "File ccminer sudah ada, lewati download."
fi

# --- Buat config.json jika belum ada ---
if [ ! -f "config.json" ]; then
    echo ""
    read -p "WALLET  (contoh: R*****.Q*****.A*****): " WALLET_ADDRESS
    read -p "WORKER (Enter'miner'): " WORKER_NAME
    WORKER_NAME=${WORKER_NAME:-default_miner}
    DEFAULT_THREADS=8

    echo "Membuat config.json..."
    cat << EOF > config.json
{
    "pools": [
        {
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
        }
    ],
    "user": "${WALLET_ADDRESS}.${WORKER_NAME}",
    "pass": "",
    "algo": "verus",
    "threads": ${DEFAULT_THREADS},
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10
}
EOF
else
    echo "config.json sudah ada, lewati."
fi

# --- Buat start.sh jika belum ada ---
if [ ! -f "start.sh" ]; then
    echo "Membuat start.sh..."
    cat << 'EOF_START' > start.sh
#!/bin/bash

MINER_LOG="miner_output.log"

echo "Memulai Mining..."
stdbuf -oL ./ccminer | tee "${MINER_LOG}" &
MINER_PID=$!

# Tunggu 2 detik agar log awal muncul
sleep 2

# Ambil versi miner dari log
VERSION=$(grep -m 1 "ccminer" "${MINER_LOG}")
if [ -n "$VERSION" ]; then
    echo "Versi Miner: $VERSION"
else
    echo "Tidak bisa membaca versi miner dari log."
fi

# Delay 10 detik sebelum hapus log
sleep 10
rm -f "${MINER_LOG}"

# Monitor accepted selama 30 detik
TIMEOUT=30
ELAPSED=0
SUCCESS=false

while [ $ELAPSED -lt $TIMEOUT ]; do
    if grep -qE "accepted|Mining on" "${MINER_LOG}"; then
        echo "--------------------------------------------------------"
        echo "Miner OK! Log terakhir:"
        tail -n 5 "${MINER_LOG}"
        echo "--------------------------------------------------------"
        SUCCESS=true
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ "$SUCCESS" = false ]; then
    echo "Timeout! Tidak ada 'accepted' dalam ${TIMEOUT} detik."
fi
EOF_START
    chmod +x start.sh
else
    echo "start.sh sudah ada, lewati."
fi

echo ""
echo "Setup selesai. Menjalankan miner..."
./start.sh
