#!/bin/sh
set -e

cd /opt/app

check_net_admin() {
    iptables -L >/dev/null 2>&1
    return $?
}

if check_net_admin; then
    echo "NET_ADMIN izni mevcut."
else
    echo "!!! ERROR: NET_ADMIN izni yok. Lütfen container'ı --cap-add=NET_ADMIN ile başlatın."
    exit 1
fi

mkdir -p ./ipset

if [ -n "$ZAPRET_DOMAINS" ]; then
    echo "$ZAPRET_DOMAINS" | tr ',' '\n' > ./ipset/zapret-hosts-user.txt
    echo "Host list yazıldı: $(wc -l ./ipset/zapret-hosts-user.txt | awk '{print $1}') domain"
else
    echo "!!! Uyarı: ZAPRET_DOMAINS boş. Lütfen domain ekleyin."
    exit 1
fi

# İlk çalıştırma
if [ -f /first_run ]; then
  echo "install_easy.sh çalıştırılıyor..."
  printf "Y\n\n\n3\n\n\nY\n\n\n\n\n\n" | /opt/zapret/install_easy.sh
  rm /first_run
fi

# nfqws param
if [ -n "$ZAPRET_PARAMS" ]; then
    sed -i '/^NFQWS_OPT="/,/^"/c NFQWS_OPT="'"$ZAPRET_PARAMS"'"' /opt/zapret/config
    echo "NFQWS_OPT güncellendi."
else
    echo "!!! Uyarı: ZAPRET_PARAMS boş."
    echo "Blockcheck çalıştırıp çalışan profil seçmeniz lazım."
    printf "%s\n\n\n\n\n\n\n\n" "$(echo $ZAPRET_DOMAINS | cut -d "," -f 1)" | /opt/zapret/blockcheck.sh
    exit 1
fi

echo "zapret başlatılıyor..."
/opt/zapret/init.d/sysv/zapret start

echo "[i] starting tinyproxy..."
exec /usr/bin/tinyproxy -d
