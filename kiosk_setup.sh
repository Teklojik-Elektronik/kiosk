#!/bin/bash
# Raspberry Pi Kiosk Display System Kurulum Betiği
# Kurulum için güncel bir Raspberry Pi OS Bookworm gereklidir.
# Raspberry Pi 5 ve Raspberry Pi 4 üzerinde test edilmiştir.
# Kolay kullanım için Raspberry Pi Imager kullanın. Wi-Fi, SSH ve hostname ayarlarını yapın.
# SD kartınızı hazırlayın.
# Bu betiği çalışan Raspberry Pi sisteminize kopyalayın ve root olmayan bir kullanıcı olarak çalıştırın:
# bash kiosk_setup.sh
# Sürüm Geçmişi
# 2024-10-22 v1.0: İlk sürüm
# 2024-11-04 v1.1: Wayfire'dan labwc'ye geçiş
# 2024-11-13 v1.2: wlr-randr kurulumu eklendi
# 2024-11-20 v1.3: Chromium için detaylı yapılandırma seçenekleri eklendi
# 2024-11-30 v1.4  Wayland için gelişmiş fare imleci gizleme desteği eklendi

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

# Betiğin root olarak çalıştırılıp çalıştırılmadığını kontrol et, doğruysa çık
if [ "$(id -u)" -eq 0 ]; then
    echo "Bu betik root olarak çalıştırılmamalıdır. Lütfen sudo yetkilerine sahip normal bir kullanıcı olarak çalıştırın."
    exit 1
fi
    
# Geçerli kullanıcıyı belirle
CURRENT_USER=$(whoami)

# Wayland kullanılıyor mu kontrolü için değişken
USE_WAYLAND=false

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

# Paket listesini güncellemek ister misiniz?
echo
if ask_user "Paket listesini güncellemek ister misiniz?"; then
    echo -e "\e[90mPaket listesi güncelleniyor, lütfen bekleyin...\e[0m"
    sudo apt update > /dev/null 2>&1 &
    spinner $! "Paket listesi güncelleniyor..."
fi
    
# Kurulu paketleri yükseltmek ister misiniz?
echo
if ask_user "Kurulu paketleri yükseltmek ister misiniz?"; then
    echo -e "\e[90mKurulu paketler yükseltiliyor. BU BİRAZ ZAMAN ALABİLİR, lütfen bekleyin...\e[0m"
    sudo apt upgrade -y > /dev/null 2>&1 &
    spinner $! "Kurulu paketler yükseltiliyor..."
fi
    
# Wayland/labwc paketlerini kurmak ister misiniz?
echo
if ask_user "Wayland ve labwc paketlerini kurmak ister misiniz?"; then
    echo -e "\e[90mWayland paketleri kuruluyor, lütfen bekleyin...\e[0m"
    sudo apt install --no-install-recommends -y labwc wlr-randr seatd > /dev/null 2>&1 &
    spinner $! "Wayland paketleri kuruluyor..."
    
    # Wayland kullanılacağını belirt
    USE_WAYLAND=true
    
    # labwc yapılandırma dosyasını oluştur
    LABWC_CONFIG_DIR="/home/$CURRENT_USER/.config/labwc"
    mkdir -p "$LABWC_CONFIG_DIR"
    
    # rc.xml dosyası oluştur veya güncelle
    LABWC_RC_FILE="$LABWC_CONFIG_DIR/rc.xml"
    
    # rc.xml dosyası yoksa oluştur
    if [ ! -f "$LABWC_RC_FILE" ]; then
        # Temel bir rc.xml dosyası oluştur
        cat > "$LABWC_RC_FILE" << EOL
<?xml version="1.0"?>

<labwc_config>
  <core>
    <gap>0</gap>
  </core>
</labwc_config>
EOL
        echo -e "\e[32m✔\e[0m Labwc yapılandırma dosyası oluşturuldu."
    fi
    
    # Labwc için cursor_theme.xml dosyası oluştur
    LABWC_CURSOR_FILE="$LABWC_CONFIG_DIR/cursor_theme.xml"
    if [ ! -f "$LABWC_CURSOR_FILE" ]; then
        # Boş imleç teması dosyası oluştur
        cat > "$LABWC_CURSOR_FILE" << EOL
<?xml version="1.0"?>

<labwc_cursor_theme>
  <name>default</name>
  <size>0</size>
</labwc_cursor_theme>
EOL
        echo -e "\e[32m✔\e[0m Labwc imleç teması dosyası oluşturuldu."
    fi
fi
    
# İmleci gizlemek ister misiniz?
echo
HIDE_CURSOR=false
if ask_user "İmleci (cursor) gizlemek ister misiniz?"; then
    HIDE_CURSOR=true
    
    if [ "$USE_WAYLAND" = true ]; then
        echo -e "\e[90mWayfire plugins extra kuruluyor, lütfen bekleyin...\e[0m"
        
        # Gerekli paketleri kur
        echo -e "\e[90mGerekli paketler kuruluyor...\e[0m"
        sudo apt install -y git meson ninja-build build-essential libwayland-dev libwf-config-dev libwlroots-dev > /dev/null 2>&1 &
        spinner $! "Gerekli paketler kuruluyor..."
        
        # Geçici dizine geç
        cd /tmp
        
        # Önceki klonlama işleminden kalan dizini temizle
        if [ -d "wayfire-plugins-extra-raspbian" ]; then
            rm -rf wayfire-plugins-extra-raspbian
        fi
        
        # GitHub'dan wayfire-plugins-extra-raspbian klonla
        echo -e "\e[90mwayfire-plugins-extra-raspbian klonlanıyor...\e[0m"
        git clone https://github.com/seffs/wayfire-plugins-extra-raspbian.git
        
        # Klonlama başarılı mı kontrol et
        if [ -d "wayfire-plugins-extra-raspbian" ]; then
            cd wayfire-plugins-extra-raspbian
            
            # Meson ile derleme için hazırla
            echo -e "\e[90mMeson ile derleme için hazırlanıyor...\e[0m"
            meson build --prefix=/usr --buildtype=release > /dev/null 2>&1 &
            spinner $! "Meson ile derleme için hazırlanıyor..."
            
            # Ninja ile derle ve kur
            echo -e "\e[90mNinja ile derleniyor ve kuruluyor...\e[0m"
            ninja -C build > /dev/null 2>&1 && sudo ninja -C build install > /dev/null 2>&1 &
            spinner $! "Ninja ile derleniyor ve kuruluyor..."
            
            # Wayfire yapılandırma dosyasını oluştur
            echo -e "\e[90mWayfire yapılandırma dosyası oluşturuluyor...\e[0m"
            WAYFIRE_CONFIG_DIR="/home/$CURRENT_USER/.config/wayfire"
            mkdir -p "$WAYFIRE_CONFIG_DIR"
            
            # wayfire.ini dosyasını oluştur veya güncelle
            WAYFIRE_CONFIG_FILE="$WAYFIRE_CONFIG_DIR/wayfire.ini"
            
            # wayfire.ini dosyası yoksa oluştur
            if [ ! -f "$WAYFIRE_CONFIG_FILE" ]; then
                # Temel bir wayfire.ini dosyası oluştur
                cat > "$WAYFIRE_CONFIG_FILE" << EOL
[hide-cursor]
timeout = 0.1

[core]
plugins = hide-cursor
EOL
                echo -e "\e[32m✔\e[0m Wayfire yapılandırma dosyası oluşturuldu."
            else
                # Dosya varsa, hide-cursor eklentisini etkinleştir
                if ! grep -q "\[hide-cursor\]" "$WAYFIRE_CONFIG_FILE"; then
                    echo -e "\n[hide-cursor]\ntimeout = 0.1" >> "$WAYFIRE_CONFIG_FILE"
                    echo -e "\e[32m✔\e[0m hide-cursor bölümü Wayfire yapılandırma dosyasına eklendi."
                fi
                
                # core plugins listesine hide-cursor ekle
                if grep -q "\[core\]" "$WAYFIRE_CONFIG_FILE"; then
                    if ! grep -q "plugins.*hide-cursor" "$WAYFIRE_CONFIG_FILE"; then
                        # plugins satırını bul ve hide-cursor ekle
                        sed -i '/\[core\]/,/\[.*\]/ s/plugins = \(.*\)/plugins = \1 hide-cursor/' "$WAYFIRE_CONFIG_FILE"
                        echo -e "\e[32m✔\e[0m hide-cursor eklentisi core plugins listesine eklendi."
                    fi
                else
                    # core bölümü yoksa ekle
                    echo -e "\n[core]\nplugins = hide-cursor" >> "$WAYFIRE_CONFIG_FILE"
                    echo -e "\e[32m✔\e[0m core bölümü ve hide-cursor eklentisi Wayfire yapılandırma dosyasına eklendi."
                fi
            fi
            
            echo -e "\e[32m✔\e[0m wayfire-plugins-extra-raspbian başarıyla kuruldu ve yapılandırıldı."
        else
            echo -e "\e[31m✘\e[0m wayfire-plugins-extra-raspbian klonlanamadı. wf-hide-cursor kurulumu atlanıyor."
        fi
        
        # Ana dizine geri dön
        cd /home/$CURRENT_USER
    else
        echo -e "\e[90munclutter kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install -y unclutter > /dev/null 2>&1 &
        spinner $! "unclutter kuruluyor..."
        echo -e "\e[32m✔\e[0m unclutter başarıyla kuruldu."
    fi
fi

# Chromium tarayıcısını kurmak ister misiniz?
echo
if ask_user "Chromium tarayıcısını kurmak ister misiniz?"; then
    echo -e "\e[90mChromium tarayıcısı kuruluyor, lütfen bekleyin...\e[0m"
    sudo apt install --no-install-recommends -y chromium-browser > /dev/null 2>&1 &
    spinner $! "Chromium tarayıcısı kuruluyor..."
fi

# greetd kurmak ve yapılandırmak ister misiniz?
echo
if ask_user "Labwc otomatik başlatması için greetd kurmak ve yapılandırmak ister misiniz?"; then
    # greetd kur
    echo -e "\e[90mLabwc otomatik başlatması için greetd kuruluyor, lütfen bekleyin...\e[0m"
    sudo apt install -y greetd > /dev/null 2>&1 &
    spinner $! "greetd kuruluyor..."
    
    # /etc/greetd/config.toml oluştur veya üzerine yaz
    echo -e "\e[90mconfig.toml oluşturuluyor veya üzerine yazılıyor...\e[0m"
    sudo mkdir -p /etc/greetd
    sudo bash -c "cat <<EOL > /etc/greetd/config.toml
[terminal]
vt = 7
[default_session]
command = \"/usr/bin/labwc\"
user = \"$CURRENT_USER\"
EOL"
    echo -e "\e[32m✔\e[0m config.toml başarıyla oluşturuldu veya üzerine yazıldı!"
    
    # greetd servisini etkinleştir ve grafik hedefini ayarla
    echo -e "\e[90mgreetd servisi etkinleştiriliyor...\e[0m"
    sudo systemctl enable greetd > /dev/null 2>&1 &
    spinner $! "greetd servisi etkinleştiriliyor..."
    
    echo -e "\e[90mVarsayılan olarak grafik hedefi ayarlanıyor...\e[0m"
    sudo systemctl set-default graphical.target > /dev/null 2>&1 &
    spinner $! "Grafik hedefi ayarlanıyor..."
fi
    
# labwc için otomatik başlatma betiği oluşturmak ister misiniz?
echo
if ask_user "Labwc için otomatik başlatma (chromium) betiği oluşturmak ister misiniz?"; then
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
    
    # config.toml oluştur veya üzerine yaz
    echo -e "\e[90mOtomatik başlatma dosyası oluşturuluyor veya üzerine yazılıyor...\e[0m"
    LABWC_AUTOSTART_DIR="/home/$CURRENT_USER/.config/labwc"
    mkdir -p "$LABWC_AUTOSTART_DIR"
    LABWC_AUTOSTART_FILE="$LABWC_AUTOSTART_DIR/autostart"
    
    # İmleç gizleme ve Chromium başlatma komutunu otomatik başlatma dosyasına ekle veya oluştur
    if [ "$HIDE_CURSOR" = true ]; then
        if [ "$USE_WAYLAND" = true ]; then
            # İmleç gizleme için birden fazla yöntem ekle (en az biri çalışacaktır)
            
            # 1. wf-hide-cursor komutunu ekle
            if ! grep -q "wf-hide-cursor" "$LABWC_AUTOSTART_FILE"; then
                echo "wf-hide-cursor &" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m wf-hide-cursor komutu eklendi."
            fi
            
            # 2. Wayland için seat0 imleç gizleme komutunu ekle
            if ! grep -q "seat0 hide_cursor" "$LABWC_AUTOSTART_FILE"; then
                echo "# Wayland için imleç gizleme" >> "$LABWC_AUTOSTART_FILE"
                echo "export WLR_HIDE_CURSOR=1" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m WLR_HIDE_CURSOR ortam değişkeni eklendi."
            fi
            
            # 3. Alternatif olarak, boş imleç teması kullan
            if ! grep -q "XCURSOR_SIZE=0" "$LABWC_AUTOSTART_FILE"; then
                echo "# Boş imleç teması kullan" >> "$LABWC_AUTOSTART_FILE"
                echo "export XCURSOR_SIZE=0" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m XCURSOR_SIZE=0 ortam değişkeni eklendi."
            fi
            
            # 4. Alternatif olarak, wlr-randr ile imleç gizleme
            if ! grep -q "wlr-randr --hide-cursor" "$LABWC_AUTOSTART_FILE"; then
                echo "wlr-randr --hide-cursor &" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m wlr-randr --hide-cursor komutu eklendi."
            fi
        else
            # İmleç gizleme için unclutter komutunu ekle
            if ! grep -q "unclutter" "$LABWC_AUTOSTART_FILE"; then
                echo "unclutter -idle 0.01 -root &" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m unclutter komutu eklendi."
            fi
            
            # X11 için alternatif imleç gizleme yöntemi
            if ! grep -q "xsetroot -cursor" "$LABWC_AUTOSTART_FILE"; then
                echo "xsetroot -cursor_name blank &" >> "$LABWC_AUTOSTART_FILE"
                echo -e "\e[32m✔\e[0m xsetroot imleç gizleme komutu eklendi."
            fi
        fi
    fi
    
    # Chromium başlatma komutunu otomatik başlatma dosyasına ekle veya oluştur
    if grep -q "chromium" "$LABWC_AUTOSTART_FILE"; then
        # Mevcut Chromium satırını yeni komutla değiştir
        sed -i "/chromium-browser/c\\$CHROMIUM_CMD" "$LABWC_AUTOSTART_FILE"
        echo -e "\e[32m✔\e[0m Mevcut Chromium komutu güncellendi."
    else
        echo -e "\e[90mChromium'u labwc otomatik başlatma betiğine ekleme...\e[0m"
        echo "$CHROMIUM_CMD" >> "$LABWC_AUTOSTART_FILE"
        echo -e "\e[32m✔\e[0m Chromium komutu eklendi."
    fi
    
    # Otomatik başlatma dosyasının konumu hakkında geri bildirim sağla
    echo -e "\e[32m✔\e[0m labwc otomatik başlatma betiği $LABWC_AUTOSTART_FILE konumunda oluşturuldu veya güncellendi."
    echo -e "\e[94mEklenen Chromium komutu:\e[0m"
    echo -e "\e[93m$CHROMIUM_CMD\e[0m"
fi

# Plymouth splash screen kurmak ister misiniz?
echo
if ask_user "Plymouth splash screen kurmak ister misiniz?"; then
    # /boot/firmware/config.txt güncelle
    CONFIG_TXT="/boot/firmware/config.txt"
    if ! grep -q "disable_splash" "$CONFIG_TXT"; then
        echo -e "\e[90m$CONFIG_TXT dosyasına disable_splash=1 ekleniyor...\e[0m"
        sudo bash -c "echo 'disable_splash=1' >> $CONFIG_TXT"
    else
        echo -e "\e[33m$CONFIG_TXT zaten bir disable_splash seçeneği içeriyor. Değişiklik yapılmadı. Lütfen manuel olarak kontrol edin!\e[0m"
    fi
    
    # /boot/firmware/cmdline.txt güncelle
    CMDLINE_TXT="/boot/firmware/cmdline.txt"
    if ! grep -q "splash" "$CMDLINE_TXT"; then
        echo -e "\e[90m$CMDLINE_TXT dosyasına quiet splash plymouth.ignore-serial-consoles ekleniyor...\e[0m"
        sudo sed -i 's/$/ quiet splash plymouth.ignore-serial-consoles/' "$CMDLINE_TXT"
    else
        echo -e "\e[33m$CMDLINE_TXT zaten splash seçenekleri içeriyor. Değişiklik yapılmadı. Lütfen manuel olarak kontrol edin!\e[0m"
    fi
    
    # Plymouth ve temaları kur
    echo -e "\e[90mPlymouth ve temaları kuruluyor...\e[0m"
    sudo apt install -y plymouth plymouth-themes > /dev/null 2>&1 &
    spinner $! "Plymouth kuruluyor..."
    
    # Kullanılabilir temaları listele ve bir diziye kaydet
    echo -e "\e[90mKullanılabilir Plymouth temaları listeleniyor...\e[0m"
    readarray -t THEMES < <(plymouth-set-default-theme -l)  # Temaları bir diziye kaydet
    
    # Kullanıcıdan bir tema seçmesini iste
    echo -e "\e[94mLütfen bir tema seçin (numarayı girin):\e[0m"
    select SELECTED_THEME in "${THEMES[@]}"; do
        if [[ -n "$SELECTED_THEME" ]]; then
            echo -e "\e[90mPlymouth teması $SELECTED_THEME olarak ayarlanıyor...\e[0m"
            sudo plymouth-set-default-theme $SELECTED_THEME
            sudo update-initramfs -u > /dev/null 2>&1 &
            spinner $! "Initramfs güncelleniyor..."
            echo -e "\e[32m✔\e[0m Plymouth splash screen $SELECTED_THEME teması ile kuruldu ve yapılandırıldı."
            break
        else
            echo -e "\e[31mGeçersiz seçim, lütfen tekrar deneyin.\e[0m"
        fi
    done
fi

# Ekran çözünürlüğünü yapılandırmak ister misiniz?
echo
if ask_user "cmdline.txt ve labwc autostart dosyasında ekran çözünürlüğünü ayarlamak ister misiniz?"; then
    # edid-decode kurulu mu kontrol et; değilse kur
    if ! command -v edid-decode &> /dev/null; then
        echo -e "\e[90mGerekli araç kuruluyor, lütfen bekleyin...\e[0m"
        sudo apt install -y edid-decode > /dev/null 2>&1 &
        spinner $! "edid-decode kuruluyor..."
        echo -e "\e[32mGerekli araç başarıyla kuruldu!\e[0m"
    fi
    
    # edid-decode komutunun çıktısını yakala
    edid_output=$(sudo cat /sys/class/drm/card1-HDMI-A-1/edid | edid-decode)
    
    # Yenileme hızlarıyla biçimlendirilmiş çözünürlükleri saklamak için bir dizi başlat
    declare -a available_resolutions=()
    
    # Satırları döngüye al ve çözünürlük ve yenileme hızlarıyla zamanlama ara
    while IFS= read -r line; do
        # Established, Standard veya Detailed Timings formatına sahip satırları eşleştir
        if [[ "$line" =~ ([0-9]+)x([0-9]+)[[:space:]]+([0-9]+\.[0-9]+|[0-9]+)\ Hz ]]; then
            resolution="${BASH_REMATCH[1]}x${BASH_REMATCH[2]}"
            frequency="${BASH_REMATCH[3]}"
            # "genişlikxyükseklik@frekansHz" olarak biçimlendir
            formatted="${resolution}@${frequency}Hz"
            available_resolutions+=("$formatted")
        fi
    done <<< "$edid_output"
    
    # Hiç çözünürlük bulunamazsa varsayılan listeye geri dön
    if [ ${#available_resolutions[@]} -eq 0 ]; then
        echo -e "\e[33mHiç çözünürlük bulunamadı. Varsayılan liste kullanılıyor.\e[0m"
        available_resolutions=("1920x1080@60" "1280x720@60" "1024x768@60" "1600x900@60" "1366x768@60")
    fi
    
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
    
    # Seçilen çözünürlüğü /boot/firmware/cmdline.txt dosyasına ekle (zaten yoksa)
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
    if ! grep -q "video=" "$CMDLINE_FILE"; then
        echo -e "\e[90m$CMDLINE_FILE dosyasına video=HDMI-A-1:$RESOLUTION ekleniyor...\e[0m"
        sudo sed -i "1s/^/video=HDMI-A-1:$RESOLUTION /" "$CMDLINE_FILE"
        echo -e "\e[32m✔\e[0m Çözünürlük cmdline.txt dosyasına başarıyla eklendi!"
    else
        echo -e "\e[33mcmdline.txt zaten bir video girişi içeriyor. Değişiklik yapılmadı.\e[0m"
    fi
    
    # Komutu .config/labwc/autostart dosyasına ekle (zaten yoksa)
    AUTOSTART_FILE="/home/$CURRENT_USER/.config/labwc/autostart"
    if ! grep -q "wlr-randr --output HDMI-A-1 --mode $RESOLUTION" "$AUTOSTART_FILE"; then
        echo "wlr-randr --output HDMI-A-1 --mode $RESOLUTION" >> "$AUTOSTART_FILE"
        echo -e "\e[32m✔\e[0m Çözünürlük komutu labwc autostart dosyasına başarıyla eklendi!"
    else
        echo -e "\e[33mAutostart dosyası zaten bu çözünürlük komutunu içeriyor. Değişiklik yapılmadı.\e[0m"
    fi
fi

# apt önbelleğini temizle
echo -e "\e[90mapt önbellekleri temizleniyor, lütfen bekleyin...\e[0m"
sudo apt clean > /dev/null 2>&1 &
spinner $! "apt önbellekleri temizleniyor..."

# Tamamlanma mesajını yazdır
echo -e "\e[32m✔\e[0m \e[32mKurulum başarıyla tamamlandı! Lütfen sisteminizi yeniden başlatın.\e[0m"
