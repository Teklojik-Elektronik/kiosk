# labwc için otomatik başlatma betiği oluştur?
echo
if ask_user "Labwc için otomatik başlatma (chromium) betiği oluşturmak ister misiniz?"; then
    # Kullanıcıdan varsayılan URL iste
    read -p "Chromium'da açmak için URL'yi girin [varsayılan: https://webglsamples.org...]: " USER_URL
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
        CHROMIUM_CMD="$CHROMIUM_CMD --unsafely-treat-insecure-origin-as-secure=\"$INSECURE_ORIGIN\""
    fi
    
    # URL ekle
    CHROMIUM_CMD="$CHROMIUM_CMD $USER_URL &"
    
    # config.toml oluştur veya üzerine yaz
    echo -e "\e[90mOtomatik başlatma dosyası oluşturuluyor veya üzerine yazılıyor...\e[0m"
    LABWC_AUTOSTART_DIR="/home/$CURRENT_USER/.config/labwc"
    mkdir -p "$LABWC_AUTOSTART_DIR"
    LABWC_AUTOSTART_FILE="$LABWC_AUTOSTART_DIR/autostart"
    
    # Chromium başlatma komutunu otomatik başlatma dosyasına ekle veya oluştur
    if grep -q "chromium" "$LABWC_AUTOSTART_FILE"; then
        # Mevcut Chromium satırını yeni komutla değiştir
        sed -i '/chromium-browser/c\'"$CHROMIUM_CMD" "$LABWC_AUTOSTART_FILE"
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
