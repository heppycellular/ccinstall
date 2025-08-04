```bash
pkg update && pkg upgrade -y
yes | pkg install libjansson wget nano -y
wget https://raw.githubusercontent.com/heppycellular/ccinstall/master/instaler.sh
chmod +x instaler.sh
./instaler.sh
