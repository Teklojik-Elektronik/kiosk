# Raspberry Pi Home Assistant İçin Kiosk Ekran Sistemi

**Raspberry Pi Home Assistant Kiosk Ekran Sistemi** projesine hoş geldiniz! Bu proje, Raspberry Pi'nizi **labwc** (bir Wayland kompozitörü) ile tam ekran tarayıcı çalıştıran bir kiosk'a dönüştürmek için kolay yapılandırılabilir bir sistem sunar ve Raspberry Pi 4 ve 5 gibi daha yeni donanımları destekler. Özellikle Home Assistant arayüzünü sürekli görüntülemek için idealdir.

Geri bildirim ve pull request'leri teşvik ediyoruz!

## 🚀 Özellikler

- **Neredeyse tüm Raspberry Pi kartlarını destekler**: Raspberry Pi 5 ve Raspberry Pi Zero 2 W ile test edilmiştir.
- **3B hızlandırılmış grafikler**: Kiosk uygulamalarında gelişmiş performans için donanım hızlandırmalı grafikler kullanır.
- **Wayland ve labwc**: Wayland ekran sunucu protokolü ve labwc kompozitörü ile sorunsuz bir deneyim sunar.
- **Kiosk modunda Chromium**: Web tabanlı dijital tabela için mükemmel olan tam ekran kiosk modunda Chromium çalıştırır. NOT: Chromium en az 1GB RAM gerektirir ancak daha düşük özelliklerde de çalışabilir.
- **Özelleştirilebilir çözünürlük**: Ekran çözünürlüklerini kolayca yapılandırabilirsiniz.
- **Otomatik başlatma**: Önyüklemede labwc'yi otomatik başlatmak için `greetd` kullanır.
- **Plymouth açılış ekranı**: Cilalı bir önyükleme deneyimi için isteğe bağlı olarak özel bir açılış ekranı yapılandırabilirsiniz.
- **Ses**: Test ortamı için fake mikrofon ve kamera eklenebilir.
- **Home Assistant Uyumluluğu**: Home Assistant web arayüzünü sorunsuz görüntülemek için optimize edilmiştir.

## 📋 Gereksinimler

- Bu kurulum, neredeyse tüm Raspberry Pi kartlarıyla uyumludur (RPi Zero 2 W ve RPi 5 üzerinde test edilmiştir).
- Raspberry Pi OS Bookworm'un yeni bir kurulumu (Raspberry Pi 5 üzerinde **2024-10-22-raspios-bookworm-armhf-lite** ile test edilmiştir)
- İlk HDMI portuna bağlı ekran (Raspberry Pi 5 USB Type C portunun yanındaki)
- Home Assistant sunucusuna ağ erişimi

## 🛠️ Kurulum Talimatları

1. **SD Kartınızı Hazırlayın:**
   - SD kartınıza Raspberry Pi OS kurmak için [Raspberry Pi Imager](https://www.raspberrypi.com/software/) kullanın.
   - Gerektiğinde SSH'ı etkinleştirin, Wi-Fi ayarlayın ve ana bilgisayar adını yapılandırın.

2. **Kurulum Betiğini Çalıştırın:**
   - `kiosk_setup.sh` betiğini çalışan Raspberry Pi'nize kopyalayın.
   - Betiği çalıştırın (root kullanıcısı olmadığınızdan emin olun):
     ```bash
     bash kiosk_setup.sh
     ```
