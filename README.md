# Raspberry Pi Home Assistant İçin Kiosk Ekran Sistemi

<div align="center">
  <img src="https://raw.githubusercontent.com/Teklojik-Elektronik/kiosk/main/_assets/SampleTerminalOutput.png" alt="Kiosk Ekran Sistemi" width="600">
</div>

**Raspberry Pi Home Assistant Kiosk Ekran Sistemi** projesine hoş geldiniz! Bu proje, Raspberry Pi'nizi tam ekran Chromium tarayıcı çalıştıran bir kiosk'a dönüştürmek için kolay yapılandırılabilir bir sistem sunar. Özellikle Home Assistant arayüzünü sürekli görüntülemek için idealdir.

Geri bildirim ve pull request'leri teşvik ediyoruz!

## 🚀 Özellikler

- **Neredeyse tüm Raspberry Pi kartlarını destekler**: Raspberry Pi 4, 5 ve Raspberry Pi Zero 2 W ile test edilmiştir.
- **Tam Ekran Kiosk Modu**: Adres çubuğu ve diğer tarayıcı kontrolleri olmadan tam ekran deneyimi.
- **Home Assistant Entegrasyonu**: URL'ye `?kiosk=true` parametresi ekleyerek Home Assistant kiosk modunu destekler.
- **Esnek URL Yapılandırması**: HTTP veya HTTPS protokollerini destekler, özel dashboard yolları belirtilebilir.
- **Otomatik Başlatma**: Sistem açıldığında otomatik olarak oturum açar ve kiosk modunu başlatır.
- **Ekran Koruyucu Devre Dışı**: Ekranın her zaman açık kalmasını sağlar.
- **İmleç Gizleme Seçeneği**: İsteğe bağlı olarak fare imlecini gizleyebilirsiniz.
- **SIP Card Desteği**: Home Assistant SIP card kullanımı için özel yapılandırma seçenekleri.
- **SSL Sertifika Yönetimi**: Öz-imzalı sertifikaları yoksayma seçeneği.
- **Medya Akışı Desteği**: Test ortamı için sahte UI ve sahte cihaz (kamera/mikrofon) seçenekleri.
- **Güvenli İçerik Yönetimi**: HTTPS üzerinden HTTP içeriğine izin verme ve güvensiz kaynakları güvenli olarak işaretleme seçenekleri.
- **Gizli Mod Seçeneği**: Chromium'u gizli modda çalıştırma seçeneği.
- **Kolay Kurulum ve Kaldırma**: Tek komutla kurulum ve kaldırma işlemleri.

## 📋 Gereksinimler

- Bu kurulum, neredeyse tüm Raspberry Pi kartlarıyla uyumludur (RPi 4, RPi 5 ve RPi Zero 2 W üzerinde test edilmiştir).
- Raspberry Pi OS Bookworm'un yeni bir kurulumu (Raspberry Pi 5 üzerinde **2024-10-22-raspios-bookworm-armhf-lite** ile test edilmiştir)
- İlk HDMI portuna bağlı ekran (Raspberry Pi 5 USB Type C portunun yanındaki)
- Home Assistant sunucusuna ağ erişimi

## 🛠️ Kurulum Talimatları

### Kolay Kurulum (Önerilen)

1. **SD Kartınızı Hazırlayın:**
   - SD kartınıza Raspberry Pi OS kurmak için [Raspberry Pi Imager](https://www.raspberrypi.com/software/) kullanın.
   - Gerektiğinde SSH'ı etkinleştirin, Wi-Fi ayarlayın ve ana bilgisayar adını yapılandırın.

2. **Kurulum Betiğini İndirin ve Çalıştırın:**
   ```bash
   wget -O kiosk_setup.sh https://raw.githubusercontent.com/Teklojik-Elektronik/kiosk/main/kiosk_setup.sh
   chmod +x kiosk_setup.sh
   sudo ./kiosk_setup.sh install
   ```

3. **Yapılandırma Adımlarını Takip Edin:**
   - Home Assistant URL adresini girin (örn: https://homeassistant.local:8123)
   - Home Assistant dashboard yolunu girin (varsayılan: lovelace/default_view)
   - Home Assistant kiosk modunu etkinleştirmek isteyip istemediğinizi seçin
   - Diğer seçenekleri tercihlerinize göre yapılandırın

4. **Kurulum Tamamlandığında:**
   - Sistem otomatik olarak yeniden başlatılacak ve kiosk modu etkinleştirilecektir
   - Raspberry Pi her açıldığında, otomatik olarak Home Assistant dashboard'unuzu gösterecektir

### Kurulumu Kaldırma

Kiosk kurulumunu kaldırmak için aşağıdaki komutu çalıştırın:

```bash
sudo ./kiosk_setup.sh uninstall
```

Bu komut, tüm kiosk yapılandırmalarını kaldıracak ve sistemi orijinal durumuna geri döndürecektir.

## ⚙️ Yapılandırma Seçenekleri

Kurulum sırasında aşağıdaki seçenekleri yapılandırabilirsiniz:

- **Home Assistant URL**: Home Assistant sunucunuzun tam URL'si (http veya https)
- **Dashboard Yolu**: Görüntülemek istediğiniz dashboard'un yolu (varsayılan: lovelace/default_view)
- **Kiosk Modu**: Home Assistant kiosk modunu etkinleştirme (URL'ye ?kiosk=true ekler)
- **Fare İmleci**: Fare imlecini gizleme seçeneği
- **Medya Akışı**: Sahte UI ve sahte cihaz seçenekleri (kamera/mikrofon izinleri için)
- **SSL Sertifikaları**: SSL sertifika hatalarını yoksayma seçeneği
- **Güvensiz İçerik**: HTTPS üzerinden HTTP içeriğine izin verme seçeneği
- **Güvensiz Kaynaklar**: Belirli güvensiz kaynakları güvenli olarak işaretleme seçeneği
- **Gizli Mod**: Chromium'u gizli modda çalıştırma seçeneği

## 📝 Notlar

- Kurulum, otomatik giriş yapılandırması oluşturur ve sistem her açıldığında kiosk kullanıcısı otomatik olarak oturum açar.
- Chromium tarayıcısı kiosk modunda başlatılır ve Home Assistant dashboard'unuzu tam ekran gösterir.
- Ekran koruyucu devre dışı bırakılır, böylece ekran her zaman açık kalır.
- Sistem, Home Assistant'a erişilebilir olup olmadığını kontrol eder ve erişilebilir olana kadar bekler.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen bir pull request gönderin veya bir issue açın.

## 📜 Lisans

Bu proje Apache Lisansı, Sürüm 2.0 altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.