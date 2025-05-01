#!/bin/bash
# Raspberry Pi Kiosk Kurulum ve Kaldırma Betiği
# Kullanım:
#   Kurulum için: bash kiosk_setup.sh install
#   Kaldırma için: bash kiosk_setup.sh uninstall

# Spinner fonksiyonu - işlem devam ederken görsel geri bildirim sağlar
spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    tput civis
    local i=0
    while [ -d /proc/$pid ]; do
        local frame=${frames[$i]}
        printf "\r\e[35m%s\e[0m %s" "$frame" "$message"
        i=$(((i + 1) % ${#frames[@]}))
        sleep $delay
    done
    printf "\r\e[32m✔\e[0m %s\n" "$message"
    tput cnorm
}

# Root kontrolü
if [ "$(id -u)" -eq 0 ]; then
    echo "Bu betik root olarak çalıştırılmamalıdır. Lütfen sudo yetkilerine sahip normal bir kullanıcı olarak çalıştırın."
    exit 1
fi
    
# Geçerli kullanıcıyı belirle
CURRENT_USER=$(whoami)

# Kullanıcıya evet/hayır sorusu soran fonksiyon
ask_user() {
    local prompt="$1"
    while true; do
        read -p "$prompt [e/h]: " yn
        case $yn in
            [Ee]* ) return 0;;
            [Hh]* ) return 1;;
            * ) echo "Lütfen e veya h yazın.";;
        esac
    done
}

# Kurulum fonksiyonu
install_kiosk() {
    echo -e "\e[1;32m=== Raspberry Pi Kiosk Kurulum Başlatılıyor ===\e[0m"
    
    # Grafik ortamı değişkenini tanımla
    USING_WAYLAND=false
    USING_X11=false
    
    # Paket listesini güncelleme
    echo
    if ask_user "Paket listesini güncellemek ister misiniz?"; then
        echo -e "\e[90mPaket listesi güncelleniyor, lütfen bekleyin...\e[0m"
        sudo apt update > /dev/null 2>&1 &
        spinner $! "Paket listesi güncelleniyor..."
    fi
        
    # Kurulu paketleri yükseltme
    echo
    if ask_user "Kurulu paketleri yükseltmek ister misiniz?"; then
        echo -e "\e[90mKurulu paketler yükseltiliyor. BU BİRAZ ZAMAN ALABİLİR, lütfen bekleyin...\e[0m"
        sudo apt upgrade -y > /dev/null 2>&1 &
        spinner $! "Kurulu paketler yükseltiliyor..."
    fi
        
    # Wayland/labwc kurulumu
    echo
    if ask_user "Wayland ve labwc paketlerini kurmak ister misiniz?"; then
        echo -e "\e[90mWayland paketleri kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install --no-install-recommends -y labwc wlr-randr seatd > /dev/null 2>&1 &
        spinner $! "Wayland paketleri kuruluyor..."
        USING_WAYLAND=true
    else
        echo
        if ask_user "X11 (Xorg) ve Openbox paketlerini kurmak ister misiniz?"; then
            echo -e "\e[90mX11 paketleri kuruluyor, lütfen bekleyin...\e[0m"
            sudo apt install --no-install-recommends -y xserver-xorg-core xserver-xorg xinit x11-xserver-utils openbox > /dev/null 2>&1 &
            spinner $! "X11 paketleri kuruluyor..."
            USING_X11=true
        else
            echo -e "\e[33mUyarı: Herhangi bir grafik ortamı kurulmadı. Chromium düzgün çalışmayabilir.\e[0m"
        fi
    fi
        
    # Chromium kurulumu
    echo
    if ask_user "Chromium tarayıcısını kurmak ister misiniz?"; then
        echo -e "\e[90mChromium tarayıcısı kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install --no-install-recommends -y chromium-browser > /dev/null 2>&1 &
        spinner $! "Chromium tarayıcısı kuruluyor..."
    fi
    
    # Unclutter kurulumu (fare imlecini gizlemek için)
    echo
    if ask_user "Fare imlecini gizlemek için unclutter kurmak ister misiniz?"; then
        echo -e "\e[90mUnclutter kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install -y unclutter > /dev/null 2>&1 &
        spinner $! "Unclutter kuruluyor..."
        
        # Kullanıcıdan imlecin gizlenmesi için bekleme süresini iste
        read -p "İmlecin gizlenmesi için kaç saniye hareketsiz kalması gerektiğini girin [varsayılan: 3]: " IDLE_TIME
        IDLE_TIME="${IDLE_TIME:-3}"
        
        # Unclutter komutunu oluştur
        UNCLUTTER_CMD="unclutter --timeout $IDLE_TIME &"
        
        if [ "$USING_WAYLAND" = true ]; then
            # Komutu .config/labwc/autostart dosyasına ekle
            AUTOSTART_FILE="/home/$CURRENT_USER/.config/labwc/autostart"
            mkdir -p "/home/$CURRENT_USER/.config/labwc"
            
            if ! grep -q "unclutter" "$AUTOSTART_FILE"; then
                echo "$UNCLUTTER_CMD" >> "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Unclutter komutu labwc autostart dosyasına başarıyla eklendi!"
            else
                # Mevcut unclutter satırını yeni komutla değiştir
                sed -i "/unclutter/c\\$UNCLUTTER_CMD" "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Mevcut unclutter komutu güncellendi."
            fi
        elif [ "$USING_X11" = true ]; then
            # Komutu .config/openbox/autostart dosyasına ekle
            AUTOSTART_FILE="/home/$CURRENT_USER/.config/openbox/autostart"
            mkdir -p "/home/$CURRENT_USER/.config/openbox"
            
            if ! grep -q "unclutter" "$AUTOSTART_FILE"; then
                echo "$UNCLUTTER_CMD" >> "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Unclutter komutu openbox autostart dosyasına başarıyla eklendi!"
            else
                # Mevcut unclutter satırını yeni komutla değiştir
                sed -i "/unclutter/c\\$UNCLUTTER_CMD" "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Mevcut unclutter komutu güncellendi."
            fi
        fi
    fi
        
    # Otomatik başlatma için display manager kurulumu
    echo
    if [ "$USING_WAYLAND" = true ] && ask_user "Labwc otomatik başlatması için greetd kurmak ve yapılandırmak ister misiniz?"; then
        # greetd kur
        echo -e "\e[90mLabwc otomatik başlatması için greetd kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install -y greetd > /dev/null 2>&1 &
        spinner $! "greetd kuruluyor..."
        
        # /etc/greetd/config.toml oluştur
        echo -e "\e[90mconfig.toml oluşturuluyor...\e[0m"
        sudo mkdir -p /etc/greetd
        sudo bash -c "cat <<EOL > /etc/greetd/config.toml
[terminal]
vt = 7
[default_session]
command = \"/usr/bin/labwc\"
user = \"$CURRENT_USER\"
EOL"
        
        # greetd servisini etkinleştir
        sudo systemctl enable greetd > /dev/null 2>&1 &
        spinner $! "greetd servisi etkinleştiriliyor..."
        
        sudo systemctl set-default graphical.target > /dev/null 2>&1 &
        spinner $! "Grafik hedefi ayarlanıyor..."
    elif [ "$USING_X11" = true ] && ask_user "X11 otomatik başlatması için lightdm kurmak ve yapılandırmak ister misiniz?"; then
        # lightdm kur (X11 için)
        echo -e "\e[90mX11 otomatik başlatması için lightdm kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install -y lightdm > /dev/null 2>&1 &
        spinner $! "lightdm kuruluyor..."
        
        # lightdm.conf oluştur
        echo -e "\e[90mlightdm.conf oluşturuluyor...\e[0m"
        sudo mkdir -p /etc/lightdm
        sudo bash -c "cat <<EOL > /etc/lightdm/lightdm.conf
[SeatDefaults]
autologin-user=$CURRENT_USER
autologin-user-timeout=0
user-session=openbox
EOL"
        
        # .xsession dosyası oluştur
        echo -e "\e[90m.xsession dosyası oluşturuluyor...\e[0m"
        cat <<EOL > /home/$CURRENT_USER/.xsession
#!/bin/bash
exec openbox-session
EOL
        chmod +x /home/$CURRENT_USER/.xsession
        
        # lightdm servisini etkinleştir
        sudo systemctl enable lightdm > /dev/null 2>&1 &
        spinner $! "lightdm servisi etkinleştiriliyor..."
        
        sudo systemctl set-default graphical.target > /dev/null 2>&1 &
        spinner $! "Grafik hedefi ayarlanıyor..."
    fi
        
    # Chromium otomatik başlatma betiği oluşturma
    echo
    if ask_user "Chromium için otomatik başlatma betiği oluşturmak ister misiniz?"; then
        # Kullanıcıdan varsayılan URL iste
        read -p "Chromium'da açmak için URL'yi girin [varsayılan: https://webglsamples.org/aquarium/aquarium.html]: " USER_URL
        USER_URL="${USER_URL:-https://webglsamples.org/aquarium/aquarium.html}"
        
        # Ek Chromium parametreleri için sorular
        echo
        USE_FAKE_UI=false
        if ask_user "Medya akışı için sahte UI kullanmak ister misiniz? (kamera/mikrofon izinleri için)"; then
            USE_FAKE_UI=true
        fi
        
        USE_FAKE_DEVICE=false
        if ask_user "Medya akışı için sahte cihaz kullanmak ister misiniz? (test amaçlı sahte kamera/mikrofon)"; then
            USE_FAKE_DEVICE=true
        fi
        
        IGNORE_CERT_ERRORS=false
        if ask_user "SSL sertifika hatalarını yoksaymak ister misiniz? (öz-imzalı sertifikalar için)"; then
            IGNORE_CERT_ERRORS=true
        fi
        
        ALLOW_INSECURE=false
        if ask_user "Güvensiz içeriğin çalışmasına izin vermek ister misiniz? (HTTPS üzerinden HTTP içeriği)"; then
            ALLOW_INSECURE=true
        fi
        
        TREAT_INSECURE=false
        INSECURE_ORIGIN=""
        if ask_user "Güvensiz kaynakları güvenli olarak işaretlemek ister misiniz?"; then
            TREAT_INSECURE=true
            read -p "Güvenli olarak işaretlenecek kaynak URL'sini girin (örn: https://192.168.1.20:8089): " INSECURE_ORIGIN
        fi
        
        # Gizli mod kullanımı
        USE_INCOGNITO=true
        if ask_user "Chromium'u gizli modda çalıştırmak ister misiniz? (Hayır derseniz, oturum bilgileri saklanır)"; then
            USE_INCOGNITO=true
        else
            USE_INCOGNITO=false
        fi
    
        # Chromium komutunu oluştur
        CHROMIUM_CMD="/usr/bin/chromium-browser"
    
        # Gizli mod parametresi
        if [ "$USE_INCOGNITO" = true ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --incognito"
        else
            CHROMIUM_CMD="$CHROMIUM_CMD --user-data-dir=/home/$CURRENT_USER/.config/chromium-kiosk --password-store=basic"
        fi
        
        # Temel kiosk parametreleri
        CHROMIUM_CMD="$CHROMIUM_CMD --autoplay-policy=no-user-gesture-required --kiosk"
        
        # Ek parametreleri ekle
        if [ "$USE_FAKE_UI" = true ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --use-fake-ui-for-media-stream"
        fi
        
        if [ "$USE_FAKE_DEVICE" = true ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --use-fake-device-for-media-stream"
        fi
        
        if [ "$IGNORE_CERT_ERRORS" = true ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --ignore-certificate-errors"
        fi
        
        if [ "$ALLOW_INSECURE" = true ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --allow-running-insecure-content"
        fi
        
        if [ "$TREAT_INSECURE" = true ] && [ -n "$INSECURE_ORIGIN" ]; then
            CHROMIUM_CMD="$CHROMIUM_CMD --unsafely-treat-insecure-origin-as-secure=$INSECURE_ORIGIN"
        fi
        
        # URL ekle
        CHROMIUM_CMD="$CHROMIUM_CMD $USER_URL &"
        
        # Uygun autostart dosyasını seç ve oluştur
        if [ "$USING_WAYLAND" = true ]; then
            AUTOSTART_DIR="/home/$CURRENT_USER/.config/labwc"
            AUTOSTART_FILE="$AUTOSTART_DIR/autostart"
        elif [ "$USING_X11" = true ]; then
            AUTOSTART_DIR="/home/$CURRENT_USER/.config/openbox"
            AUTOSTART_FILE="$AUTOSTART_DIR/autostart"
        else
            echo -e "\e[33mUyarı: Herhangi bir grafik ortamı seçilmedi. Autostart dosyası oluşturulamıyor.\e[0m"
            AUTOSTART_FILE=""
        fi
        
        if [ -n "$AUTOSTART_FILE" ]; then
            echo -e "\e[90mOtomatik başlatma dosyası oluşturuluyor veya üzerine yazılıyor...\e[0m"
            mkdir -p "$AUTOSTART_DIR"
            
            # Chromium başlatma komutunu otomatik başlatma dosyasına ekle veya oluştur
            if grep -q "chromium" "$AUTOSTART_FILE"; then
                # Mevcut Chromium satırını yeni komutla değiştir
                sed -i "/chromium-browser/c\\$CHROMIUM_CMD" "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Mevcut Chromium komutu güncellendi."
            else
                echo -e "\e[90mChromium'u otomatik başlatma betiğine ekleme...\e[0m"
                echo "$CHROMIUM_CMD" >> "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Chromium komutu eklendi."
            fi
            
            # X11 için dosyayı çalıştırılabilir yap
            if [ "$USING_X11" = true ]; then
                chmod +x "$AUTOSTART_FILE"
            fi
        fi
    fi
    
    # Ekran çözünürlüğünü yapılandırma
    echo
    if ask_user "Ekran çözünürlüğünü ayarlamak ister misiniz?"; then
        # Kullanılabilir çözünürlükleri tanımla
        available_resolutions=("1920x1080@60" "1280x720@60" "1024x768@60" "1600x900@60" "1366x768@60")
        
        # Kullanıcıdan bir çözünürlük seçmesini iste
        echo -e "\e[94mLütfen bir çözünürlük seçin (numarayı girin):\e[0m"
        select RESOLUTION in "${available_resolutions[@]}"; do
            if [[ -n "$RESOLUTION" ]]; then
                echo -e "\e[32m$RESOLUTION seçtiniz\e[0m"
                break
            else
                echo -e "\e[33mGeçersiz seçim, lütfen tekrar deneyin.\e[0m"
            fi
        done
        
        # Grafik ortamına göre çözünürlük ayarı yap
        if [ "$USING_WAYLAND" = true ]; then
            # Komutu .config/labwc/autostart dosyasına ekle
            AUTOSTART_FILE="/home/$CURRENT_USER/.config/labwc/autostart"
            if ! grep -q "wlr-randr --output HDMI-A-1 --mode $RESOLUTION" "$AUTOSTART_FILE"; then
                echo "wlr-randr --output HDMI-A-1 --mode $RESOLUTION" >> "$AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m Çözünürlük komutu labwc autostart dosyasına başarıyla eklendi!"
            else
                echo -e "\e[33mAutostart dosyası zaten bu çözünürlük komutunu içeriyor. Değişiklik yapılmadı.\e[0m"
            fi
        elif [ "$USING_X11" = true ]; then
            # X11 için xrandr komutu oluştur
            RESOLUTION_ONLY=$(echo "$RESOLUTION" | cut -d '@' -f 1)
            XRANDR_CMD="xrandr --output HDMI-1 --mode $RESOLUTION_ONLY &"
            OPENBOX_AUTOSTART="/home/$CURRENT_USER/.config/openbox/autostart"
            
            if ! grep -q "xrandr" "$OPENBOX_AUTOSTART"; then
                echo "$XRANDR_CMD" >> "$OPENBOX_AUTOSTART"
                echo -e "\e[32m✔\e[0m Çözünürlük komutu Openbox autostart dosyasına başarıyla eklendi!"
            else
                sed -i "/xrandr/c\\$XRANDR_CMD" "$OPENBOX_AUTOSTART"
                echo -e "\e[32m✔\e[0m Openbox autostart dosyasındaki xrandr komutu güncellendi!"
            fi
        fi
    fi
    
    # Uyku modunu ve ekran koruyucuyu devre dışı bırakma
    echo
    if ask_user "Uyku modunu ve ekran koruyucuyu devre dışı bırakmak ister misiniz?"; then
        echo -e "\e[90mUyku modu ve ekran koruyucu ayarları yapılandırılıyor...\e[0m"
        
        # Grafik ortamına göre uyku modu ayarlarını yap
        if [ "$USING_X11" = true ]; then
            # X11 için ekran koruyucu ve güç yönetimi ayarlarını devre dışı bırak
            OPENBOX_AUTOSTART="/home/$CURRENT_USER/.config/openbox/autostart"
            
            # Ekran koruyucu komutlarını ekle
            if ! grep -q "xset s off" "$OPENBOX_AUTOSTART"; then
                echo "# Ekran koruyucuyu devre dışı bırak" >> "$OPENBOX_AUTOSTART"
                echo "xset s off" >> "$OPENBOX_AUTOSTART"
                echo "xset -dpms" >> "$OPENBOX_AUTOSTART"
                echo "xset s noblank" >> "$OPENBOX_AUTOSTART"
                echo -e "\e[32m✔\e[0m Ekran koruyucu devre dışı bırakma komutları Openbox autostart dosyasına eklendi!"
            else
                echo -e "\e[33mEkran koruyucu komutları zaten Openbox autostart dosyasında mevcut.\e[0m"
            fi
            
            # lightdm.conf dosyasını düzenle
            if [ -f "/etc/lightdm/lightdm.conf" ]; then
                if ! grep -q "xserver-command=X -s 0 -dpms" "/etc/lightdm/lightdm.conf"; then
                    sudo sed -i '/^\[SeatDefaults\]/a xserver-command=X -s 0 -dpms' "/etc/lightdm/lightdm.conf"
                    echo -e "\e[32m✔\e[0m LightDM yapılandırması güncellendi!"
                else
                    echo -e "\e[33mLightDM yapılandırması zaten güncel.\e[0m"
                fi
            fi
        elif [ "$USING_WAYLAND" = true ]; then
            # Wayland için uyku modu ayarlarını devre dışı bırak
            echo -e "\e[33mNot: Wayland için ekran koruyucu devre dışı bırakma işlemi farklıdır.\e[0m"
            
            # labwc için idle inhibit ayarı
            LABWC_CONFIG_DIR="/home/$CURRENT_USER/.config/labwc"
            mkdir -p "$LABWC_CONFIG_DIR"
            
            # rc.xml dosyasını oluştur veya güncelle
            if [ ! -f "$LABWC_CONFIG_DIR/rc.xml" ]; then
                cat <<EOL > "$LABWC_CONFIG_DIR/rc.xml"
<?xml version="1.0"?>
<labwc_config>
  <core>
    <idleInhibit>always</idleInhibit>
  </core>
</labwc_config>
EOL
                echo -e "\e[32m✔\e[0m labwc yapılandırması oluşturuldu ve idle inhibit ayarlandı!"
            else
                if ! grep -q "<idleInhibit>always</idleInhibit>" "$LABWC_CONFIG_DIR/rc.xml"; then
                    # Dosya var ama idleInhibit ayarı yok, ekle
                    sed -i '/<core>/a \ \ <idleInhibit>always</idleInhibit>' "$LABWC_CONFIG_DIR/rc.xml"
                    echo -e "\e[32m✔\e[0m labwc yapılandırmasına idle inhibit ayarı eklendi!"
                else
                    echo -e "\e[33mlabwc yapılandırması zaten idle inhibit ayarını içeriyor.\e[0m"
                fi
            fi
        fi
        
        # Sistem genelinde uyku modunu devre dışı bırak
        echo -e "\e[90mSistem genelinde uyku modu ayarları yapılandırılıyor...\e[0m"
        
        # logind.conf dosyasını düzenle
        if [ -f "/etc/systemd/logind.conf" ]; then
            sudo cp "/etc/systemd/logind.conf" "/etc/systemd/logind.conf.bak"
            echo -e "\e[32m✔\e[0m logind.conf yedeklendi."
            
            # HandleLidSwitch ayarını ekle veya güncelle
            if grep -q "^#HandleLidSwitch=" "/etc/systemd/logind.conf" || ! grep -q "HandleLidSwitch=" "/etc/systemd/logind.conf"; then
                sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=ignore/' "/etc/systemd/logind.conf"
                if ! grep -q "HandleLidSwitch=" "/etc/systemd/logind.conf"; then
                    echo "HandleLidSwitch=ignore" | sudo tee -a "/etc/systemd/logind.conf" > /dev/null
                fi
            fi
            
            # HandleLidSwitchDocked ayarını ekle veya güncelle
            if grep -q "^#HandleLidSwitchDocked=" "/etc/systemd/logind.conf" || ! grep -q "HandleLidSwitchDocked=" "/etc/systemd/logind.conf"; then
                sudo sed -i 's/^#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' "/etc/systemd/logind.conf"
                if ! grep -q "HandleLidSwitchDocked=" "/etc/systemd/logind.conf"; then
                    echo "HandleLidSwitchDocked=ignore" | sudo tee -a "/etc/systemd/logind.conf" > /dev/null
                fi
            fi
            
            # IdleAction ayarını ekle veya güncelle
            if grep -q "^#IdleAction=" "/etc/systemd/logind.conf" || ! grep -q "IdleAction=" "/etc/systemd/logind.conf"; then
                sudo sed -i 's/^#IdleAction=.*/IdleAction=ignore/' "/etc/systemd/logind.conf"
                if ! grep -q "IdleAction=" "/etc/systemd/logind.conf"; then
                    echo "IdleAction=ignore" | sudo tee -a "/etc/systemd/logind.conf" > /dev/null
                fi
            fi
            
            echo -e "\e[32m✔\e[0m logind.conf güncellendi, uyku modu devre dışı bırakıldı."
            
            # systemd-logind servisini yeniden başlat
            sudo systemctl restart systemd-logind
            echo -e "\e[32m✔\e[0m systemd-logind servisi yeniden başlatıldı."
        else
            echo -e "\e[33mUyarı: /etc/systemd/logind.conf dosyası bulunamadı. Sistem genelinde uyku modu ayarları yapılandırılamadı.\e[0m"
        fi
    fi
    
    # Plymouth açılış ve kapanış ekranını yapılandırma
    echo
    if ask_user "Açılış ve kapanış ekranını özelleştirmek için Plymouth kurmak ister misiniz?"; then
        echo -e "\e[90mPlymouth kuruluyor ve yapılandırılıyor...\e[0m"
        
        # Plymouth paketlerini kur
        sudo apt install -y plymouth plymouth-themes > /dev/null 2>&1 &
        spinner $! "Plymouth paketleri kuruluyor..."
        
        # Mevcut temaları listele
        echo -e "\e[94mMevcut Plymouth temaları:\e[0m"
        plymouth-set-default-theme --list | nl
        
        # En popüler Plymouth temaları hakkında bilgi ver
        echo -e "\e[94mEn popüler Plymouth temaları:\e[0m"
        echo -e "1. \e[1mspinner\e[0m: Basit ve şık bir yükleme animasyonu (Raspberry Pi için en uygun)"
        echo -e "2. \e[1mbgrt\e[0m: UEFI logo teması, sistem logosunu gösterir"
        echo -e "3. \e[1mfade-in\e[0m: Yumuşak geçişli bir tema"
        echo -e "4. \e[1mtribar\e[0m: Üç çubuklu yükleme animasyonu"
        echo -e "5. \e[1mtext\e[0m: Sadece metin gösteren basit tema"
        
        # Kullanıcıdan tema seçmesini iste
        read -p "Kullanmak istediğiniz temanın adını girin [varsayılan: spinner]: " THEME_NAME
        THEME_NAME="${THEME_NAME:-spinner}"
        
        # Seçilen temayı ayarla
        sudo plymouth-set-default-theme "$THEME_NAME" > /dev/null 2>&1 &
        spinner $! "Plymouth teması '$THEME_NAME' olarak ayarlanıyor..."
        
        # initramfs'i güncelle
        echo -e "\e[90minitramfs güncelleniyor...\e[0m"
        sudo update-initramfs -u > /dev/null 2>&1 &
        spinner $! "initramfs güncelleniyor..."
        
        # cmdline.txt dosyasını düzenle (Raspberry Pi için)
        if [ -f "/boot/cmdline.txt" ]; then
            # Yedek al
            sudo cp "/boot/cmdline.txt" "/boot/cmdline.txt.bak"
            echo -e "\e[32m✔\e[0m cmdline.txt yedeklendi."
            
            # quiet splash parametrelerini ekle (eğer yoksa)
            if ! grep -q "quiet splash" "/boot/cmdline.txt"; then
                # Mevcut içeriği al ve sonuna quiet splash ekle
                CMDLINE=$(cat /boot/cmdline.txt)
                echo "$CMDLINE quiet splash plymouth.ignore-serial-consoles" | sudo tee "/boot/cmdline.txt" > /dev/null
                echo -e "\e[32m✔\e[0m cmdline.txt güncellendi, Plymouth parametreleri eklendi."
            else
                echo -e "\e[33mcmdline.txt zaten Plymouth parametrelerini içeriyor.\e[0m"
            fi
        else
            echo -e "\e[33mUyarı: /boot/cmdline.txt dosyası bulunamadı. Plymouth boot parametreleri eklenemedi.\e[0m"
        fi
        
        # Özel logo eklemek ister misiniz?
        echo
        if ask_user "Özel bir logo eklemek ister misiniz?"; then
            # Logo dosyasının yolunu sor
            read -p "Logo dosyasının tam yolunu girin (örn: /home/pi/logo.png): " LOGO_PATH
            
            if [ -f "$LOGO_PATH" ]; then
                # Logo dosyasını Plymouth tema klasörüne kopyala
                sudo cp "$LOGO_PATH" "/usr/share/plymouth/themes/$THEME_NAME/"
                echo -e "\e[32m✔\e[0m Logo dosyası Plymouth tema klasörüne kopyalandı."
                
                # Tema yapılandırma dosyasını güncelle (tema yapısına bağlı olarak değişebilir)
                if [ -f "/usr/share/plymouth/themes/$THEME_NAME/$THEME_NAME.plymouth" ]; then
                    LOGO_FILENAME=$(basename "$LOGO_PATH")
                    sudo sed -i "s|ImageDir=.*|ImageDir=/usr/share/plymouth/themes/$THEME_NAME|" "/usr/share/plymouth/themes/$THEME_NAME/$THEME_NAME.plymouth"
                    sudo sed -i "s|ScaleHintImage=.*|ScaleHintImage=$LOGO_FILENAME|" "/usr/share/plymouth/themes/$THEME_NAME/$THEME_NAME.plymouth" 2>/dev/null || true
                    echo -e "\e[32m✔\e[0m Plymouth tema yapılandırması güncellendi."
                    
                    # initramfs'i tekrar güncelle
                    sudo update-initramfs -u > /dev/null 2>&1 &
                    spinner $! "initramfs güncelleniyor..."
                else
                    echo -e "\e[33mUyarı: Plymouth tema yapılandırma dosyası bulunamadı. Logo ayarları yapılamadı.\e[0m"
                fi
            else
                echo -e "\e[33mUyarı: Belirtilen logo dosyası bulunamadı: $LOGO_PATH\e[0m"
            fi
        fi
        
        echo -e "\e[32m✔\e[0m Plymouth kurulumu ve yapılandırması tamamlandı."
    fi
    
    echo -e "\e[1;32m=== Raspberry Pi Kiosk Kurulumu Tamamlandı ===\e[0m"
    echo -e "Sistemi yeniden başlatmanız önerilir. Şimdi yeniden başlatmak ister misiniz?"
    if ask_user "Sistemi şimdi yeniden başlatmak ister misiniz?"; then
        sudo reboot
    fi
}

# Kaldırma fonksiyonu
uninstall_kiosk() {
    echo -e "\e[1;31m=== Raspberry Pi Kiosk Kaldırma İşlemi Başlatılıyor ===\e[0m"
    
    # Kullanıcıya kaldırma işlemini onaylatma
    echo -e "\e[1;33mUYARI: Bu işlem kiosk modunu ve ilgili yapılandırmaları kaldıracaktır.\e[0m"
    if ! ask_user "Devam etmek istediğinizden emin misiniz?"; then
        echo -e "\e[32mKaldırma işlemi iptal edildi.\e[0m"
        exit 0
    fi
    
    # Display manager'ları kaldır
    echo
    if ask_user "Display manager'ları kaldırmak ister misiniz? (greetd ve lightdm)"; then
        echo -e "\e[90mDisplay manager'lar kaldırılıyor...\e[0m"
        sudo apt purge -y greetd lightdm > /dev/null 2>&1 &
        spinner $! "Display manager'lar kaldırılıyor..."
    fi
    
    # Wayland/labwc paketlerini kaldır
    echo
    if ask_user "Wayland ve labwc paketlerini kaldırmak ister misiniz?"; then
        echo -e "\e[90mWayland paketleri kaldırılıyor...\e[0m"
        sudo apt purge -y labwc wlr-randr seatd > /dev/null 2>&1 &
        spinner $! "Wayland paketleri kaldırılıyor..."
    fi
    
    # X11/Openbox paketlerini kaldır
    echo
    if ask_user "X11 ve Openbox paketlerini kaldırmak ister misiniz?"; then
        echo -e "\e[90mX11 paketleri kaldırılıyor...\e[0m"
        sudo apt purge -y openbox > /dev/null 2>&1 &
        spinner $! "X11 paketleri kaldırılıyor..."
    fi
    
    # Chromium tarayıcısını kaldır
    echo
    if ask_user "Chromium tarayıcısını kaldırmak ister misiniz?"; then
        echo -e "\e[90mChromium tarayıcısı kaldırılıyor...\e[0m"
        sudo apt purge -y chromium-browser > /dev/null 2>&1 &
        spinner $! "Chromium tarayıcısı kaldırılıyor..."
    fi
    
    # Unclutter kaldır
    echo
    if ask_user "Unclutter'ı kaldırmak ister misiniz?"; then
        echo -e "\e[90mUnclutter kaldırılıyor...\e[0m"
        sudo apt purge -y unclutter > /dev/null 2>&1 &
        spinner $! "Unclutter kaldırılıyor..."
    fi
    
    # Yapılandırma dosyalarını temizle
    echo
    if ask_user "Kiosk yapılandırma dosyalarını temizlemek ister misiniz?"; then
        echo -e "\e[90mYapılandırma dosyaları temizleniyor...\e[0m"
        
        # labwc yapılandırmasını temizle
        if [ -d "/home/$CURRENT_USER/.config/labwc" ]; then
            rm -rf "/home/$CURRENT_USER/.config/labwc"
            echo -e "\e[32m✔\e[0m labwc yapılandırması temizlendi."
        fi
        
        # openbox yapılandırmasını temizle
        if [ -d "/home/$CURRENT_USER/.config/openbox" ]; then
            rm -rf "/home/$CURRENT_USER/.config/openbox"
            echo -e "\e[32m✔\e[0m openbox yapılandırması temizlendi."
        fi
        
        # .xsession dosyasını temizle
        if [ -f "/home/$CURRENT_USER/.xsession" ]; then
            rm -f "/home/$CURRENT_USER/.xsession"
            echo -e "\e[32m✔\e[0m .xsession dosyası temizlendi."
        fi
        
        # Chromium kiosk verilerini temizle
        if [ -d "/home/$CURRENT_USER/.config/chromium-kiosk" ]; then
            rm -rf "/home/$CURRENT_USER/.config/chromium-kiosk"
            echo -e "\e[32m✔\e[0m Chromium kiosk verileri temizlendi."
        fi
    fi
    
    # Gereksiz paketleri temizle
    echo
    if ask_user "Gereksiz paketleri temizlemek ister misiniz?"; then
        echo -e "\e[90mGereksiz paketler temizleniyor...\e[0m"
        sudo apt autoremove -y > /dev/null 2>&1 &
        spinner $! "Gereksiz paketler temizleniyor..."
    fi
    
    echo -e "\e[1;32m=== Raspberry Pi Kiosk Kaldırma İşlemi Tamamlandı ===\e[0m"
    echo -e "Sistemi yeniden başlatmanız önerilir. Şimdi yeniden başlatmak ister misiniz?"
    if ask_user "Sistemi şimdi yeniden başlatmak ister misiniz?"; then
        sudo reboot
    fi
}

# Ana işlem
case "$1" in
    install)
        install_kiosk
        ;;
    uninstall)
        uninstall_kiosk
        ;;
    *)
        echo "Kullanım: $0 {install|uninstall}"
        echo "  install   - Kiosk modunu kur ve yapılandır"
        echo "  uninstall - Kiosk modunu ve ilgili yapılandırmaları kaldır"
        exit 1
        ;;
esac

exit 0
