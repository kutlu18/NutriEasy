# NutriEasy iOS

## Flutter Gecisi

Swift iskeleti referans olarak korunuyor. Ana mobil MVP gelistirmesi `flutter_app/` klasoru altinda devam ediyor.

SwiftUI ile baslayan NutriEasy uygulama iskeleti.

## Dokumanlardan Cikan MVP Kapsami

- Onboarding: hedef, temel bilgiler, aktivite seviyesi, ogun giris tercihi, hedef ozeti.
- Ana ekran: gunluk kalori/makro ozeti, hizli ogun girisi, bugunku ogunler.
- Ogun girisi: metin akisi Supabase Edge Function cagrisi icin hazir; oturum yoksa gecici ornek analizle devam eder. Fotograf akisi MVP icin ekranda tutulur.
- Analiz sonucu: tespit edilen yiyecekler, makro toplamlar, duzeltme ve kaydetme.
- Diger ana moduller: gunluk plan, progress, fasting, Nuri sohbet ve profil.
- API hazirligi: dokumandaki endpoint ve veri modellerine karsilik gelen Swift modelleri.

## Proje Olusturma

Bu klasorde `project.yml` var. Mac ortaminda XcodeGen kuruluysa:

```bash
xcodegen generate
open NutriEasy.xcodeproj
```

XcodeGen kullanmak istemezseniz Xcode'da yeni bir iOS SwiftUI App acip `NutriEasyApp` klasorundeki dosyalari projeye ekleyebilirsiniz.

## Kararlastirilan Mimari

- Backend: Supabase Auth, Postgres, Storage ve Edge Functions.
- Guvenlik: Mobil uygulama FatSecret veya AI anahtari tasimaz; tum ucuncu parti cagri ve token yenileme islemleri Edge Functions icinde calisir.
- Besin verisi: Baslangicta FatSecret uzerinden aranir, kullanilan/aranan sonuclar kendi Supabase veritabanimiza normalize edilerek cache'lenir.
- Mobil API: Swift istemci Supabase Edge Functions endpointlerine kullanici JWT'si ile istek atar.
- MVP kapsami: metin, fotograf, Supabase proxy ve FatSecret kaynakli besin cache'i.

## Netlestirilmesi Gereken Sorular

1. FatSecret plani Premier mi olacak? `foods.search.v2` detayli servis bilgileri icin Premier gerektiriyor; degilse basic endpoint + ek `food.get` akisi gerekir.
2. Logo ve renk paleti icin gelecek prompt'a gore tema guncellenecek.
