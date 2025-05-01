###################################################################################
# HA Chromium Kiosk Kurulum ve Kaldırma Betiği
# Yazar: muratnazikgul@teklojik.com (muratnazikgul@teklojik.com)
# URL: https://github.com/Teklojik-Elektronik/kiosk
#
# Bu komut dosyası, bir ekran yöneticisi kullanmadan özellikle Home Assistant panoları için
# Debian sunucusuna hafif bir Chromium tabanlı kiosk modu yükler ve kaldırır
#
# İlave olarak eğer homeassistanızda https://github.com/TECH7Fox/sip-hass-card sip card kullanmak
# isterseniz setifika sorunlarını alt etmek için sip sunucunuzun kendinen imzalı sertifiklarını
# otomatik kabul etme gibi bir kaç ek ozellik eklenmiştir
#
# Raspberry ile test ortamında kurulumunda sip card kullanımı için medya akışı için sahte UI,
# sahte cihaz(kamera/mikrofon) kullanma isteğe bağlı kurululabilir
#
# SSL sertigikalarını yoksayma
# Güvensiz içeriğin çalışmasına izin verme
# Güvensiz kaynakları güvenli olarak işaretleme
# Chromium gizli modda çalıştırma özellikleri eklenerek sip cartı sorunsuzu çalıştırabilirsiniz
#
# Apache Lisansı, Sürüm 2.0 (the "License") altında lisanslanmıştır;
# bu dosyayı lisansa uygun olmadan kullanamazsınız.
# Lisansın bir kopyasını şu adresten edinebilirsiniz:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Yasalarca gerekli kılınmadığı veya yazılı olarak kabul edilmediği sürece,
# bu lisans altında dağıtılan yazılım "OLDUĞU GİBİ",
# HİÇBİR TÜRDEN AÇIK VEYA ZIMNİ GARANTİ OLMADAN dağıtılmaktadır.
# Belirli izinler ve kısıtlamalar hakkında bilgi için lisansa bakın.
#
# Kullanım: sudo ./ha-chromium-kiosk-setup.sh {install|uninstall}
#               install - Kiosk kurulumunu yapar
#               uninstall - Kiosk kurulumunu kaldırır 
#                                                
# Not: Bu betik herhangi bir garanti olmadan olduğu gibi sunulmuştur. Kendi sorumluluğunuzda kullanın.
###################################################################################

## GLOBAL DEĞİŞKENLER VE ÖN TANIMLAR ##
KIOSK_USER="kiosk"
CONFIG_DIR="/home/$KIOSK_USER/.config"
KIOSK_CONFIG_DIR="$CONFIG_DIR/ha-chromium-kiosk"
OPENBOX_CONFIG_DIR="$CONFIG_DIR/openbox"
DEFAULT_HA_PORT="8123"
DEFAULT_HA_DASHBOARD_PATH="lovelace/default_view"
PKGS_NEEDED=(xorg openbox chromium xserver-xorg xinit unclutter curl)

## FONKSİYONLAR ##

# Ek mesaj ile spinner görüntüleme fonksiyonu
spinner() {
    local pid=$1  # Arka plan işleminin PID'sini al
    local message=$2  # Spinner ile gösterilecek mesajı al
    local delay=0.1
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")  # spinner kareleri
    tput civis  # İmleci gizle
    local i=0
    while [ -d /proc/$pid ]; do  # İşlemin hala çalışıp çalışmadığını kontrol et
        local frame=${frames[$i]}
        printf "\r\e[35m%s\e[0m %s" "$frame" "$message"  # Spinner karesini mesajla birlikte yazdır
        i=$(((i + 1) % ${#frames[@]}))
        sleep $delay
    done
    printf "\r\e[32m✔\e[0m %s\n" "$message"  # İşlem tamamlandığında yeşil onay işareti göster
    tput cnorm  # İmleci geri getir
}

# Kullanıcıya evet/hayır sorusu soran fonksiyon
ask_user() {
    local prompt="$1"
    while true; do
        read -p "$prompt [e/h]: " yn
        case $yn in
            [Ee]* ) return 0;;  # Evet için 0 (başarılı) dön
            [Hh]* ) return 1;;  # Hayır için 1 (başarısız) dön
            * ) echo "Lütfen e veya h yazın.";;
        esac
    done
}

# Yazdırma kullanımı
print_usage() {
    echo "Usage: sudo $0 {install|uninstall}"
    exit 1
}

# Banner'ı yazdır
print_banner() {
    echo "****************************************************************************************************"
    echo "               _______   _____   _   __   _        _____         _   _    _   __                    "
    echo "              |__   __| |  ___| | | / /  | |      |  _  |       | | | |  | | / /                    "
    echo "                 | |    | |__   | |/ /   | |      | | | |       | | | |  | |/ /                     "
    echo "                 | |    |  __|  |   |    | |      | | | |   _   | | | |  |   |                      "
    echo "                 | |    | |___  | |\ \   | |___   | |_| |  | |__| | | |  | |\ \                     "
    echo "                 |_|    |_____| |_| \_\  |_____|  |_____|  |______| |_|  |_| \_\                    "
    echo "                                                                                                    "
    echo "                                                                                                    "
    echo "                        TEKLOJİK kiosk Kurulum ve Kaldırma Betiği                                   "
    echo "                                                                                                    "
    echo "****************************************************************************************************"
    echo "***                               UYARI: KENDİ SORUMLULUĞUNUZDA KULLANIN                         ***"
    echo "****************************************************************************************************"
    echo "                                                                                                    "
    echo "* Bu betik TEKLOJİK kiosk kurulumunu yapacak veya kaldıracaktır.                                    "
    echo "* Lütfen ne yaptığını anlamak için betiği çalıştırmadan önce okuyun.                                "
    echo "* Kendi sorumluluğunuzda kullanın. Yazar herhangi bir hasar veya veri kaybından sorumlu değildir.   "
    echo "* Çıkmak için Ctrl+C tuşuna basın veya devam etmek için herhangi bir tuşa basın.                    "
    read -n 1 -s
}

# Bir paket yükleyin ve beklerken noktaları yazdırın
install_package() {
    local package=$1
    
    echo -e "\e[90m$package kuruluyor, lütfen bekleyin...\e[0m"
    sudo apt-get update > /dev/null 2>&1
    sudo apt-get install -y "$package" > /dev/null 2>&1 &
    spinner $! "$package kuruluyor..."
    
    return $?
}

# Yüklenen paketi kaldırın ve beklerken noktaları yazdırın
uninstall_package() {
    local package=$1
    
    echo -e "\e[90m$package kaldırılıyor, lütfen bekleyin...\e[0m"
    sudo apt-get remove --purge -y "$package" > /dev/null 2>&1 &
    spinner $! "$package kaldırılıyor..."
    
    return $?
}

# Gerekli paketleri yükleyin
# Daha sonra kaldırılmak üzere yüklenen paketlerin kaydını tutun
install_packages() {
    # Kiosk yapılandırma dizinini oluşturun
    sudo -u $KIOSK_USER mkdir -p "$KIOSK_CONFIG_DIR"
    
    # Gerekli paketleri kurun ve neyin kurulduğunu takip edin
    missing_pkgs=()
    echo "Gerekli paketler kontrol ediliyor..."
    
    # Kontrol edilmesi gereken paketlerin bir listesini oluşturun
    pkgs_list="${PKGS_NEEDED[*]}"
    
    # Tüm gerekli paketlerin kurulum durumunu aynı anda alın
    dpkg_query_output=$(dpkg-query -W -f='${Package} ${Status}\n' $pkgs_list 2>/dev/null)
    
    for pkg in "${PKGS_NEEDED[@]}"; do
        if ! echo "$dpkg_query_output" | grep -q "^$pkg install ok installed$"; then
            missing_pkgs+=("$pkg")
        fi
    done
    
    if [ ${#missing_pkgs[@]} -ne 0 ]; then
        echo "Eksik paketler kuruluyor..."
        total_pkgs=${#missing_pkgs[@]}
        current_pkg=0
        
        for pkg in "${missing_pkgs[@]}"; do
            current_pkg=$((current_pkg + 1))
            echo -ne "Paket kuruluyor $current_pkg / $total_pkgs: $pkg "
            if ! install_package "$pkg"; then
                echo "Paket kurulumu başarısız: $pkg"
                exit 1
            fi
            echo " Tamamlandı."
        done
        
        echo "Tüm eksik paketler kuruldu."
    else
        echo "Tüm gerekli paketler zaten kurulu."
    fi
    
    # Daha sonra kaldırılacak paketlerin listesini bir dosyaya kaydedin
    echo "${missing_pkgs[*]}" > "$KIOSK_CONFIG_DIR/installed-packages"
}

# Yüklü paketleri kaldırın
uninstall_packages() {
    # Kurulu paketler dosyasının var olup olmadığını kontrol edin
    if [ -f "$KIOSK_CONFIG_DIR/installed-packages" ]; then
        installed_packages=$(< "$KIOSK_CONFIG_DIR/installed-packages")
        if [ -n "$installed_packages" ]; then
            echo "Kurulmuş paketler kaldırılıyor..."
            
            # Uninstall the packages and handle errors
            if ! apt-get purge -y $installed_packages; then
                echo "Bazı paketler kaldırılamadı."
                exit 1
            fi
            
            if ! apt-get autoremove -y; then
                echo "Gereksiz paketler kaldırılamadı."
                exit 1
            fi
            
            echo "Paketler başarıyla kaldırıldı."
        else
            echo "Kaldırılacak paket yok."
        fi
    else
        echo "Kurulmuş paket listesi bulunamadı."
    fi
}

# Kullanıcıyı kontrol edin ve oluşturun
check_create_user() {
    # KIOSK_USER'ın ayarlandığından emin olun
    if [ -z "$KIOSK_USER" ]; then
        echo "Kullanıcı adı belirtilmedi. Lütfen KIOSK_USER değişkenini ayarlayın."
        exit 1
    fi
    
    while id "$KIOSK_USER" &>/dev/null; do
        # Mevcut kullanıcıyı kullanma veya yeni bir kullanıcı oluşturma istemi, varsayılan olarak mevcut kullanıcıyı kullan
        read -p "Kiosk kullanıcısı zaten mevcut. Mevcut kullanıcıyı kullanmak ister misiniz? (E/h): " use_existing
        use_existing=${use_existing:-E}
        
        if [[ $use_existing =~ ^[Ee]$ ]]; then
            echo "Mevcut kullanıcı kullanılıyor."
            return
        elif [[ $use_existing =~ ^[Hh]$ ]]; then
            read -p "Kiosk kullanıcısı için farklı bir kullanıcı adı girin: " KIOSK_USER
            if [ -z "$KIOSK_USER" ]; then
                echo "Kullanıcı adı boş olamaz. Lütfen geçerli bir kullanıcı adı girin."
            fi
        else
            echo "Geçersiz giriş. Lütfen E veya H girin."
        fi
    done
    
    echo "Kiosk kullanıcısı oluşturuluyor..."
    if ! adduser --disabled-password --gecos "" "$KIOSK_USER" 2>&1 >/dev/null; then
        echo "Kiosk kullanıcısı oluşturulamadı. Çıkılıyor..."
        exit 1
    fi
    
    echo " Tamamlandı."
}

# Gerekirse kullanıcıyı kontrol edin ve kaldırın
check_remove_user() {
    if id "$KIOSK_USER" &>/dev/null; then
        read -p "Kiosk kullanıcısı mevcut. Kullanıcıyı kaldırmak ister misiniz? (E/h): " remove_user
        if [[ $remove_user =~ ^[Ee]?$ ]]; then
            echo "Kiosk kullanıcısı kaldırılıyor..."
            userdel -rf "$KIOSK_USER"
        else
            echo "Kiosk kullanıcısı kaldırılmadı."
        fi
    else
        echo "Kiosk kullanıcısı mevcut değil."
    fi
}

# Kullanıcıya bilgi verme işlevi
prompt_user() {
    local var_name=$1
    local prompt_message=$2
    local default_value=$3
    
    read -p "$prompt_message [$default_value]: " value
    value=${value:-$default_value}
    
    if [[ -z "$value" && -z "$default_value" ]]; then
        echo "Hata: $var_name gerekli. Lütfen betiği tekrar çalıştırın."
        exit 1
    fi
    
    eval $var_name=\$value
}

# Kiosk kurulumunu kurun
install_kiosk() {
    # Gerekli girdiler için kullanıcıdan istemde bulunun
    prompt_user HA_IP "Home Assistant IP adresini girin" ""
    prompt_user HA_PORT "Home Assistant port numarasını girin" "8123"
    prompt_user HA_DASHBOARD_PATH "Home Assistant dashboard yolunu girin" "lovelace/default_view"
    
    # Kiosk modu ve imleç ayarları
    prompt_user enable_kiosk "Kiosk modunu etkinleştirmek istiyor musunuz? (E/h)" "E"
    prompt_user hide_cursor "Fare imlecini gizlemek istiyor musunuz? (E/h)" "E"
    
    # Ek Chromium parametreleri için sorular
    prompt_user USE_FAKE_UI "Medya akışı için sahte UI kullanmak ister misiniz? (kamera/mikrofon izinleri için) (E/h)" "H"
    prompt_user USE_FAKE_DEVICE "Medya akışı için sahte cihaz kullanmak ister misiniz? (test amaçlı sahte kamera/mikrofon) (E/h)" "H"
    prompt_user IGNORE_CERT_ERRORS "SSL sertifika hatalarını yoksaymak ister misiniz? (öz-imzalı sertifikalar için) (E/h)" "H"
    prompt_user ALLOW_INSECURE "Güvensiz içeriğin çalışmasına izin vermek ister misiniz? (HTTPS üzerinden HTTP içeriği) (E/h)" "H"
    
    prompt_user TREAT_INSECURE "Güvensiz kaynakları güvenli olarak işaretlemek ister misiniz? (E/h)" "H"
    if [[ $TREAT_INSECURE =~ ^[Ee]$ ]]; then
        prompt_user INSECURE_ORIGIN "Güvenli olarak işaretlenecek kaynak URL'sini girin (örn: https://192.168.1.20:8089)" ""
    fi
    
    # Gizli mod kullanımı
    prompt_user USE_INCOGNITO "Chromium'u gizli modda çalıştırmak ister misiniz? (Hayır derseniz, oturum bilgileri saklanır) (E/h)" "E"
    
    KIOSK_MODE=""
    [[ $enable_kiosk =~ ^[Ee]$ ]] && KIOSK_MODE="?kiosk=true"
    KIOSK_URL="http://$HA_IP:$HA_PORT/$HA_DASHBOARD_PATH$KIOSK_MODE"
    
    echo "Home Assistant dashboard'unuz şu adreste görüntülenecek: $KIOSK_URL"
    echo "Home Assistant URL için Chromium Kiosk Modu ayarlanıyor: $KIOSK_URL"
    
    # Otomatik oturum açmayı yapılandır
    echo "Kiosk kullanıcısı için otomatik giriş yapılandırılıyor..."
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat <<EOF >/etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $KIOSK_USER --noclear %I \$TERM
Type=idle
EOF
    
    systemctl daemon-reload
    systemctl restart getty@tty1.service
    
    # Openbox'ı yapılandırın
    echo "Kiosk kullanıcısı için Openbox yapılandırılıyor..."
    sudo -u $KIOSK_USER mkdir -p $OPENBOX_CONFIG_DIR
    
    # Kiosk başlatma betiğini oluşturun
    echo "Kiosk başlatma betiği oluşturuluyor..."
    cat <<EOF >/usr/local/bin/ha-chromium-kiosk.sh
#!/bin/bash
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# İsteğe bağlı olarak fare imlecini gizleyin
EOF
    
    [[ $hide_cursor =~ ^[Ee]$ ]] && echo "unclutter -idle 0 &" >>/usr/local/bin/ha-chromium-kiosk.sh
    
    cat <<EOF >>/usr/local/bin/ha-chromium-kiosk.sh
check_network() {
    while ! nc -z -w 5 $HA_IP $HA_PORT; do
        echo "Home Assistant'ın erişilebilir olup olmadığı kontrol ediliyor..."
        sleep 2
    done
}

check_network
echo "Home Assistant erişilebilir. Chromium başlatılıyor..."

# Chromium komutunu oluştur
CHROMIUM_CMD="chromium"

# Gizli mod parametresi
EOF
    
    if [[ $USE_INCOGNITO =~ ^[Ee]$ ]]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --incognito"' >>/usr/local/bin/ha-chromium-kiosk.sh
    else
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --user-data-dir=/home/'$KIOSK_USER'/.config/chromium-kiosk --password-store=basic"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    cat <<EOF >>/usr/local/bin/ha-chromium-kiosk.sh
# Temel kiosk parametreleri
CHROMIUM_CMD="\$CHROMIUM_CMD --noerrdialogs --disable-infobars --kiosk --disable-session-crashed-bubble --disable-features=TranslateUI --overscroll-history-navigation=0 --pull-to-refresh=2 --autoplay-policy=no-user-gesture-required"

# Ek parametreleri ekle
EOF
    
    if [[ $USE_FAKE_UI =~ ^[Ee]$ ]]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --use-fake-ui-for-media-stream"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    if [[ $USE_FAKE_DEVICE =~ ^[Ee]$ ]]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --use-fake-device-for-media-stream"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    if [[ $IGNORE_CERT_ERRORS =~ ^[Ee]$ ]]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --ignore-certificate-errors"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    if [[ $ALLOW_INSECURE =~ ^[Ee]$ ]]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --allow-running-insecure-content"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    if [[ $TREAT_INSECURE =~ ^[Ee]$ ]] && [ -n "$INSECURE_ORIGIN" ]; then
        echo 'CHROMIUM_CMD="$CHROMIUM_CMD --unsafely-treat-insecure-origin-as-secure='$INSECURE_ORIGIN'"' >>/usr/local/bin/ha-chromium-kiosk.sh
    fi
    
    cat <<EOF >>/usr/local/bin/ha-chromium-kiosk.sh
# URL ekle ve çalıştır
\$CHROMIUM_CMD "$KIOSK_URL"
EOF
    
    chmod +x /usr/local/bin/ha-chromium-kiosk.sh
    
    echo "Kiosk betiğini başlatmak için Openbox yapılandırılıyor..."
    echo "/usr/local/bin/ha-chromium-kiosk.sh &" > $OPENBOX_CONFIG_DIR/autostart
    
    # systemd hizmetini oluşturun
    echo "Systemd servisi oluşturuluyor..."
    cat <<EOF >/etc/systemd/system/ha-chromium-kiosk.service
[Unit]
Description=Chromium Kiosk Mode for Home Assistant
After=systemd-user-sessions.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$KIOSK_USER
Group=$KIOSK_USER
PAMName=login
Environment=XDG_RUNTIME_DIR=/run/user/%U
ExecStart=/usr/bin/xinit /usr/bin/openbox-session -- :0 vt7 -nolisten tcp -nocursor -auth /var/run/kiosk.auth
Restart=always
RestartSec=5
StandardInput=tty
TTYPath=/dev/tty7
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ha-chromium-kiosk.service
    
    echo "Kiosk kullanıcısı tty grubuna ekleniyor..."
    usermod -aG tty $KIOSK_USER
    
    # Hemen yeniden başlatma istemi
    prompt_user reboot_now "Kurulum tamamlandı. Şimdi yeniden başlatmak istiyor musunuz?" "E"
    [[ $reboot_now =~ ^[Ee]$ ]] && { echo "Sistem yeniden başlatılıyor..."; reboot; } || echo "Kurulum tamamlandı. Lütfen sistemi hazır olduğunuzda manuel olarak yeniden başlatın."
}

# Kiosk kurulumunu kaldırın
uninstall_kiosk() {
    echo "Bu betik HA Chromium Kiosk'u kaldıracak ve ilgili tüm yapılandırmaları silecek."
    prompt_user confirm "Devam etmek istediğinizden emin misiniz? (E/h)" "E"
    
    if [[ $confirm =~ ^[Hh]$ ]]; then
        echo "Kaldırma işlemi iptal edildi."
        exit 0
    fi
    
    # Systemd hizmetini durdurun ve devre dışı bırakın
    echo "ha-chromium-kiosk servisi durduruluyor ve devre dışı bırakılıyor..."
    systemctl stop ha-chromium-kiosk.service && systemctl disable ha-chromium-kiosk.service
    
    # Hizmetin durdurulup başarıyla devre dışı bırakılıp bırakılmadığını kontrol edin
    if [[ $? -ne 0 ]]; then
        echo "ha-chromium-kiosk servisini durdurmak veya devre dışı bırakmak başarısız oldu. Lütfen manuel olarak kontrol edin."
        exit 1
    fi
    
    # systemd servis dosyasını kaldırın
    echo "Systemd servis dosyası kaldırılıyor..."
    rm -f /etc/systemd/system/ha-chromium-kiosk.service
    
    # Başlangıç ​​komut dosyasını kaldırın
    echo "Kiosk başlatma betiği kaldırılıyor..."
    rm -f /usr/local/bin/ha-chromium-kiosk.sh
    
    # Openbox için otomatik başlatma girişini kaldırın
    echo "Openbox otomatik başlatma yapılandırması kaldırılıyor..."
    if [[ -f $OPENBOX_CONFIG_DIR/autostart ]]; then
        rm -f $OPENBOX_CONFIG_DIR/autostart
    else
        echo "Openbox otomatik başlatma yapılandırması bulunamadı."
    fi
    
    # Otomatik oturum açma yapılandırmasını kaldırın
    echo "Otomatik giriş yapılandırması kaldırılıyor..."
    if [[ -f /etc/systemd/system/getty@tty1.service.d/override.conf ]]; then
        rm -f /etc/systemd/system/getty@tty1.service.d/override.conf
    else
        echo "Otomatik giriş yapılandırması bulunamadı."
    fi
    
    # Systemd yapılandırmasını yeniden yükle
    echo "Systemd yapılandırması yeniden yükleniyor..."
    systemctl daemon-reload
    
    # İsteğe bağlı olarak yüklü paketleri kaldırın
    if [[ -f "$KIOSK_CONFIG_DIR/installed-packages" ]]; then
        installed_packages=$(< "$KIOSK_CONFIG_DIR/installed-packages")
        echo "Aşağıdaki paketler kurulmuştu:"
        echo "$installed_packages"
        
        prompt_user remove_packages "Kurulmuş paketleri kaldırmak istiyor musunuz? (E/h)" "E"
        if [[ $remove_packages =~ ^[Ee]?$ ]]; then
            echo "Kurulmuş paketler kaldırılıyor..."
            for pkg in $installed_packages; do
                uninstall_package "$pkg"
                # Check if package was removed successfully
                if [[ $? -ne 0 ]]; then
                    echo "Paket kaldırılamadı: $pkg. Lütfen manuel olarak kontrol edin."
                else
                    echo "Paket başarıyla kaldırıldı: $pkg."
                fi
            done
        else
            echo "Kurulmuş paketler kaldırılmadı."
        fi
    else
        echo "Kurulmuş paket listesi bulunamadı."
    fi
    
    echo "Kaldırma işlemi tamamlandı. HA Chromium Kiosk kurulumu kaldırıldı."
}

## SENARYO BURADA BAŞLIYOR

# Komut dosyasının sudo ile çalıştırılıp çalıştırılmadığını kontrol edin
if [ "$EUID" -ne 0 ]; then
    echo "HATA: Bu betiğin root olarak çalıştırılması gerekiyor"
    echo "sudo $0 ile yeniden çalıştırın"
    exit 1
fi

print_banner

# Argüman sağlanıp sağlanmadığını kontrol edin
if [ -z "$1" ]; then
    print_usage
fi

# Yükleme veya kaldırmayı işleyen ana betik mantığı
case "$1" in
    install)
        check_create_user
        install_packages
        install_kiosk
        ;;
    uninstall)
        uninstall_kiosk
        uninstall_packages
        check_remove_user
        ;;
    *)
        print_usage
        ;;
esac