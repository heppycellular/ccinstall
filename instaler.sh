#!/bin/bash
clear
# input dengan default
function input_with_default() {
    local prompt="$1"
    local default="$2"
    read -p "$prompt" input
    if [ -z "$input" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

echo -e "CCMINER INSTALLER\n"

# Meminta input untuk wallet dan worker
wallet=$(input_with_default "Masukkan Wallet (default: Walet anda): " "Walet anda")
worker=$(input_with_default "Masukkan Nama Worker (contoh: Samsung): " "worker")
threads=$(input_with_default "Masukkan Jumlah Threads (contoh: 8): " "8")
pool_url=$(input_with_default "Masukkan URL Pool (contoh: stratum+tcp://ap.vipor.net:5040): " "stratum+tcp://sg.vipor.net:5040")
pool_name=$(input_with_default "Masukkan Nama Pool (contoh: SG-VIPOR): " "AP-VIPOR")

clear
# instal 
echo -e "Installing...\n"
pkg update && pkg upgrade -y
pkg install wget libjansson nano -y
clear

# direktori 
echo "Membuat folder ccminer..."
mkdir -p "$HOME/ccminer" && cd "$HOME/ccminer"

# file ccminer
echo "Installing ccminer..."
wget -O ccminer https://raw.githubusercontent.com/heppycellular/ccinstall/master/ccminer

# Cek file
if [ ! -f "$HOME/ccminer/ccminer" ]; then
    echo "Periksa koneksi internet atau URL."
    exit 1
fi

# izin eksekusi ccminer
chmod +x "$HOME/ccminer/ccminer"

# file config.json 
echo "configuration..."
cat <<EOF > "$HOME/ccminer/config.json"
{
    "pools": [{
        "name": "$pool_name",
        "url": "$pool_url",
        "timeout": 180,
        "disabled": 0
    }],
    "user": "$wallet.$worker",
    "pass": "",
    "algo": "verus",
    "threads": $threads,
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOF

# otomatis run ccminer saat membuka Termux
echo "auto run ccminer..."
if ! grep -q "$HOME/ccminer/ccminer -c $HOME/ccminer/config.json" ~/.bashrc; then
    echo "# Auto run ccminer" >> ~/.bashrc
    echo "$HOME/ccminer/ccminer -c $HOME/ccminer/config.json" >> ~/.bashrc
fi

# Memberikan informasi selesai
clear
echo -e "Done\n"
sleep 1
echo "Start mining...."
sleep 1
clear
"$HOME/ccminer/ccminer" -c "$HOME/ccminer/config.json"
