# zapret-tinyproxy

**zapret / nfqws** ile **transparent DPI bypass** yapan minimal Docker imajı.  
Bypass, host seviyesinde (iptables/nftables) devreye girer ve **sadece seçtiğin domainlere** uygulanır.

Multi-arch: **linux/arm64** ve **linux/amd64**.

---

## Ne işe yarar?

- DPI/ISP engeli olan sitelere **VPN’siz** erişim denemesi için kullanılır.
- Trafik host firewall üzerinden yakalandığı için **client cihazlarda proxy ayarı zorunlu değildir**.
- Tinyproxy imaj içinde bulunur; istersen explicit proxy gibi de kullanabilirsin.  
  Ama DPI bypass işini **tinyproxy değil nfqws** yapar.

> Not: Bu repo tpws’yi proxy zinciri olarak kullanmaz.  
> Zapret’in **nfqws (transparent/netfilter)** yöntemi kullanılır.

---

## Nasıl çalışır?

1. Container **host network** modunda çalışır.
2. `ZAPRET_DOMAINS` ile verdiğin domainler hostlist’e yazılır.
3. `ZAPRET_PARAMS` ile belirlediğin nfqws stratejisi host firewall’a uygulanır.
4. Bu domainlere giden trafik DPI bypass tamper’ından geçer.

---

## Gereksinimler

Docker Engine (Linux).

Container şu yetkilerle çalışmalı:

- `--network host`
- `--cap-add NET_ADMIN`
- (çoğu strateji için) `--cap-add NET_RAW`

Bu yetkiler olmadan host firewall’a kural basılamaz.

---

## Kurulum ve Kullanım (Docker)

### 1) İmajı çek

```sh
docker pull ghcr.io/mxhist/zapret-tinyproxy:latest
```

---

### 2) İlk çalıştırma (ZAPRET_PARAMS boş)

İlk sefer stratejiyi bilmediğimiz için `ZAPRET_PARAMS` boş bırakılır.  
Container blockcheck çalıştırıp strateji seçmeni ister.

```sh
docker run -d --name zapret-nfqws \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e ZAPRET_DOMAINS="x.com,instagram.com,youtube.com" \
  -e ZAPRET_PARAMS="" \
  ghcr.io/mxhist/zapret-tinyproxy:latest
```

Logları izle:

```sh
docker logs -f zapret-nfqws
```

---

### 3) Blockcheck ile çalışan stratejiyi bul

Blockcheck sadece **blok yaşadığın domainlerde** strateji üretir.  
Bloklu domainleri parametre olarak ver:

```sh
docker exec -it zapret-nfqws sh -c \
  "/opt/zapret/blockcheck.sh x.com instagram.com youtube.com"
```

Interaktif sorularda önerilen seçimler:

- IP protocol version: `4`
- HTTP test: `Y`
- TLS 1.2 test: `Y`
- TLS 1.3 test: gerekirse `Y`
- repeat: `1`
- mode: `standard`

Çıktıda “WORKING/OK” görünen satır şuna benzer:

```
nfqws --dpi-desync=... --dpi-desync-ttl=... ...
```

Buradan `nfqws` kelimesini çıkarıp kalan parametreleri aynen al:

```text
ZAPRET_PARAMS="--dpi-desync=... --dpi-desync-ttl=... ..."
```

---

### 4) Container’ı stratejiyle yeniden başlat

Önce eski container’ı sil:

```sh
docker rm -f zapret-nfqws
```

Sonra çalışan parametreyle başlat:

```sh
docker run -d --name zapret-nfqws \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e ZAPRET_DOMAINS="x.com,instagram.com,youtube.com" \
  -e ZAPRET_PARAMS="--dpi-desync=... --dpi-desync-ttl=... ..." \
  ghcr.io/mxhist/zapret-tinyproxy:latest
```

Artık bypass aktif.

---

## Docker Compose örneği

```yaml
version: "3.8"
services:
  zapret-nfqws:
    image: ghcr.io/mxhist/zapret-tinyproxy:latest
    container_name: zapret-nfqws
    restart: unless-stopped

    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW

    environment:
      - ZAPRET_DOMAINS=x.com,instagram.com,youtube.com
      - ZAPRET_PARAMS=--dpi-desync=... --dpi-desync-ttl=... ...
```

Çalıştırma:

```sh
docker compose up -d
docker logs -f zapret-nfqws
```

---

## Güncelleme

### Domain ekle/çıkar
`ZAPRET_DOMAINS` değiştir → container’ı yeniden başlat.

### Strateji değiştir
Blockcheck’ten yeni working satır al → `ZAPRET_PARAMS` değiştir → yeniden başlat.

---

## Loglar

Tinyproxy:

```sh
docker exec -it zapret-nfqws sh -c \
  "tail -f /var/log/tinyproxy/tinyproxy.log"
```

Zapret servis durumu:

```sh
docker exec -it zapret-nfqws sh -c \
  "/opt/zapret/init.d/sysv/zapret status"
```

---

## Sık sorunlar

### Blockcheck strateji üretmiyor
Test ettiğin domain bloklu değil.  
Blok yaşadığın domainlerle dene.

### IPv6 testleri fail oluyor (`code=6`)
IPv6 DNS/route yoksa normal. Blockcheck’te IPv4 (`4`) seç.

---

## Kaynak

Zapret resmi repo: https://github.com/bol-van/zapret  
Bu imaj zapret’i kaynaktan derleyip container içinde çalıştırır.

---

## Lisans

Zapret’in lisansı geçerlidir. Bu repo yalnızca Docker paketlemesi sağlar.
