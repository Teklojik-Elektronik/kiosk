# Raspberry Pi Home Assistant İçin Kiosk Ekran Sistemi

<div align="center">
  <img src="https://raw.githubusercontent.com/Teklojik-Elektronik/kiosk/main/_assets/Ekran görüntüsü.png" alt="Kiosk Ekran Sistemi" width="600">
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
- **Özelleştirilebilir Açılış/Kapanış Ekranı**: Plymouth ile özel açılış ve kapanış ekranları.
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
   - Paket listesini güncellemek ve kurulu paketleri yükseltmek isteyip istemediğinizi seçin
   - Grafik ortamı için Wayland/labwc veya X11/Openbox kurulumunu seçin
   - Chromium tarayıcısını kurun
   - Fare imlecini gizlemek için unclutter kurulumunu yapılandırın
   - Otomatik başlatma için display manager (greetd veya lightdm) kurulumunu yapın
   - Chromium için otomatik başlatma betiği oluşturun:
     - Home Assistant URL adresini girin (örn: https://homeassistant.local:8123)
     - Medya akışı, SSL sertifikaları, güvensiz içerik ve gizli mod gibi seçenekleri yapılandırın
   - Ekran çözünürlüğünü ayarlayın

4. **Kurulum Tamamlandığında:**
   - Sistem otomatik olarak yeniden başlatılacak ve kiosk modu etkinleştirilecektir
   - Raspberry Pi her açıldığında, otomatik olarak Home Assistant dashboard'unuzu gösterecektir

### Kurulumu Kaldırma

Kiosk kurulumunu kaldırmak için aşağıdaki komutu çalıştırın:

```bash
sudo ./kiosk_setup.sh uninstall
```

Kaldırma işlemi sırasında aşağıdaki seçenekleri yapılandırabilirsiniz:

- Display manager'ları kaldırma (greetd ve lightdm)
- Wayland/labwc paketlerini kaldırma
- X11/Openbox paketlerini kaldırma
- Chromium tarayıcısını kaldırma
- Unclutter'ı kaldırma
- Kiosk yapılandırma dosyalarını temizleme
- Gereksiz paketleri temizleme

Kaldırma işlemi tamamlandığında, sistemi yeniden başlatmanız önerilir.

## ⚙️ Yapılandırma Seçenekleri

Kurulum sırasında aşağıdaki seçenekleri yapılandırabilirsiniz:

- **Paket Yönetimi**:
  - Paket listesini güncelleme
  - Kurulu paketleri yükseltme

- **Grafik Ortamı**:
  - Wayland/labwc veya X11/Openbox seçimi
  - Chromium tarayıcısı kurulumu

- **Fare İmleci**:
  - Unclutter ile fare imlecini gizleme
  - İmlecin gizlenmesi için bekleme süresini ayarlama

- **Otomatik Başlatma**:
  - Wayland için greetd veya X11 için lightdm kurulumu
  - Otomatik giriş yapılandırması

- **Chromium Yapılandırması**:
  - Home Assistant URL'si (http veya https)
  - Dashboard yolu (varsayılan: lovelace/default_view)
  - Kiosk modu (URL'ye ?kiosk=true ekler)
  - Medya akışı için sahte UI ve sahte cihaz seçenekleri
  - SSL sertifika hatalarını yoksayma
  - HTTPS üzerinden HTTP içeriğine izin verme
  - Belirli güvensiz kaynakları güvenli olarak işaretleme
  - Gizli mod kullanımı

- **Ekran Ayarları**:
  - Ekran çözünürlüğünü ayarlama (1920x1080, 1280x720, vb.)

- **Uyku Modu Kontrolü**:
  - Ekran koruyucuyu devre dışı bırakma
  - Güç yönetimi ayarlarını devre dışı bırakma
  - Sistem genelinde uyku modunu devre dışı bırakma

- **Plymouth Açılış/Kapanış Ekranı**:
  - Farklı temalar arasından seçim yapma (spinner, bgrt, fade-in, tribar, text vb.)
  - Özel logo ekleme (yerel dosyadan veya URL'den)
  - Boot parametrelerini yapılandırma

## 📝 Notlar

- Kurulum, otomatik giriş yapılandırması oluşturur ve sistem her açıldığında kiosk kullanıcısı otomatik olarak oturum açar.
- Chromium tarayıcısı kiosk modunda başlatılır ve Home Assistant dashboard'unuzu tam ekran gösterir.
- Ekran koruyucu devre dışı bırakılır, böylece ekran her zaman açık kalır.
- Sistem, Home Assistant'a erişilebilir olup olmadığını kontrol eder ve erişilebilir olana kadar bekler.
- **Not**: Wayland/labwc seçildiğinde fare imleci gizleme özelliği şu anda tam olarak çalışmamaktadır. Bu özellik üzerinde çalışmalar devam etmektedir.
- **Yeni**: Kurulum betiği artık hem X11 hem de Wayland için uyku modunu devre dışı bırakma seçeneği sunmaktadır. Bu, ekranın her zaman açık kalmasını ve sistemin uyku moduna geçmemesini sağlar.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen bir pull request gönderin veya bir issue açın.

## 📜 Lisans

Bu proje Apache Lisansı, Sürüm 2.0 altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.
