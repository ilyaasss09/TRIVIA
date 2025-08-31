# Trivia Uygulaması

Flutter ile geliştirilmiş modern ve kullanıcı dostu bir trivia (bilgi yarışması) uygulaması.

## Özellikler

### 🎯 Ana Özellikler
- **Çoklu Kategori**: Tarih, Coğrafya, Spor, Bilim, Sanat, Edebiyat, Teknoloji, Genel Kültür
- **Zorluk Seviyeleri**: Kolay, Orta, Zor
- **Dinamik Puanlama**: Zorluk seviyesine göre puanlama sistemi
- **Kullanıcı Sistemi**: Kullanıcı adı ile giriş yapma
- **Lider Tablosu**: Tüm kullanıcıların skorlarını görme
- **Veritabanı**: SQLite ile yerel skor kaydetme

### 🎨 Görsel Özellikler
- Modern ve çekici UI tasarımı
- Gradient arka planlar
- Animasyonlu geçişler
- Responsive tasarım
- Material Design prensipleri

### 🏆 Oyun Özellikleri
- **Gerçek Zamanlı Sorular**: Open Trivia Database API'den soru çekme
- **Anlık Geri Bildirim**: Doğru/yanlış cevap gösterimi
- **İlerleme Takibi**: Soru sayısı ve skor gösterimi
- **Sonuç Ekranı**: Detaylı skor analizi ve başarı mesajları

## Kurulum

### Gereksinimler
- Flutter SDK (3.0.0 veya üzeri)
- Dart SDK
- Android Studio / VS Code

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone <repository-url>
cd trivia_app
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Uygulamayı çalıştırın**
```bash
flutter run
```

## Kullanım

### İlk Giriş
1. Uygulamayı açın
2. "Giriş Yap" butonuna tıklayın
3. Kullanıcı adınızı girin (en az 3 karakter)
4. "Giriş Yap" butonuna tıklayın

### Oyun Oynama
1. Ana ekranda kategori seçin
2. Zorluk seviyesi seçin
3. "Oyuna Başla" butonuna tıklayın
4. Soruları cevaplayın
5. Sonuç ekranında skorunuzu görün

### Lider Tablosu
- Ana ekranda "Lider Tablosu" butonuna tıklayın
- Kategori filtresi ile skorları filtreleyin
- En yüksek skorları görün

## Teknik Detaylar

### Mimari
- **Provider Pattern**: State management için
- **MVC Pattern**: Model-View-Controller yapısı
- **Repository Pattern**: Veri erişimi için

### Kullanılan Teknolojiler
- **Flutter**: UI framework
- **Provider**: State management
- **SQLite**: Yerel veritabanı
- **HTTP**: API istekleri
- **SharedPreferences**: Kullanıcı tercihleri

### API Entegrasyonu
- **Open Trivia Database**: Soru kaynağı
- **Fallback Sorular**: API hatası durumunda

## Puanlama Sistemi

| Zorluk | Puan |
|--------|------|
| Kolay  | 10   |
| Orta   | 20   |
| Zor    | 30   |

## Ekranlar

1. **Karşılama Ekranı**: Hoş geldin mesajı ve giriş
2. **Giriş Ekranı**: Kullanıcı adı girişi
3. **Ana Ekran**: Kategori ve zorluk seçimi
4. **Oyun Ekranı**: Soru-cevap arayüzü
5. **Sonuç Ekranı**: Skor analizi ve sonuçlar
6. **Lider Tablosu**: Tüm skorları görüntüleme

## Özellikler

### ✅ Tamamlanan Özellikler
- [x] Kullanıcı girişi
- [x] Kategori seçimi
- [x] Zorluk seviyesi seçimi
- [x] Soru-cevap sistemi
- [x] Puanlama sistemi
- [x] Sonuç ekranı
- [x] Skor kaydetme
- [x] Lider tablosu
- [x] Kategori filtreleme
- [x] Modern UI tasarımı
- [x] Animasyonlar
- [x] Back tuşu desteği