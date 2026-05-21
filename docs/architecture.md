# NutriEasy Backend Architecture

## Secilen Yapi

Mobil uygulama SwiftUI ile yazilir. Kimlik dogrulama, veritabani, dosya saklama ve proxy isleri Supabase uzerinden ilerler. FatSecret ve AI servis anahtarlari sadece Supabase Edge Functions tarafinda tutulur.

MVP kapsaminda ogun girisi fotograf ve metinle sinirlidir. Mobil uygulama ucuncu parti gizli anahtar tasimaz.

## Veri Akisi

1. Kullanici Supabase Auth ile oturum acar.
2. Swift istemci Supabase session JWT'sini alir.
3. Ogun analizi, besin arama ve FatSecret kaynakli tum islemler `/functions/v1/*` endpointlerine gider.
4. Edge Function kullaniciyi JWT ile dogrular.
5. Function once yerel Postgres cache'ini arar.
6. Yeterli sonuc yoksa FatSecret'e server-to-server OAuth 2 token ile gider.
7. FatSecret cevabindan kullanilabilir alanlar normalize edilip `foods`, `food_servings` ve `food_search_cache` tablolarina yazilir.
8. Mobil uygulama sadece normalize edilmis NutriEasy response modelini gorur.

## Ilk Edge Functions

- `food-search`: Yerel cache + FatSecret search.
- `analyze-text`: Serbest metinden ogun adaylari uretir; MVP'de yerel besin eslestirme ile ilerler.
- `submit-meal-log`: Analiz sonucunu kullanicinin gunluk ogunune kaydeder.
- `profile-refresh`: Ogun kaydindan sonra dashboard ve hedef ozetlerini gunceller.

## FatSecret Cache Stratejisi

- Arama sorgusu normalize edilir: kucuk harf, fazla bosluk temizligi, Turkce karakterler korunur.
- Once `food_search_cache` icinde ayni sorgu ve bolge icin taze sonuc aranir.
- Cache yoksa FatSecret `foods.search.v2` cagrilir.
- FatSecret'in storable data sinirlarina dikkat edilir; kaynak id, serving id ve kendi hesapladigimiz/kullandigimiz normalize alanlar ayrilir.
- Kullanici ogunlerinde daima kendi `food_id` degerimiz tutulur; FatSecret ids sadece kaynak referansi olarak saklanir.

## Supabase Secrets

Edge Functions icin gerekli secret'lar:

```text
FATSECRET_CLIENT_ID
FATSECRET_CLIENT_SECRET
FATSECRET_SCOPE=premier
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
```

Mobil uygulamada yalnizca Supabase URL ve publishable/anon key bulunur.

## Native iOS MVP Shell

### Uygulama Akisi

1. `SplashView` kisa bir bootstrap calistirir.
2. `AuthFlowView` kullanicinin oturum durumunu toplar.
3. `OnboardingFlowView` hedef ve temel profil bilgilerini alir.
4. `MainShellView` tab bazli ana uygulamayi acar.

### MVVM Klasor Yapisi

```text
NutriEasyApp/
  App/
  Core/
  Features/
    Splash/
    Auth/
    Onboarding/
    Home/
    Food/
    Meal/
    Plan/
    Progress/
    Chat/
    Profile/
  Shared/
    State/
    DesignSystem/
```

### Navigation Mantigi

- `Splash -> Auth -> Onboarding -> MainShell`
- `Home` icinden `Nuri Chat` ve detay ogun ekranlari acilir.
- `Food` tab'i metin girisi, food search ve quick add akisini toplar.
- `Plan`, `Progress` ve `Profile` kendi modullerini tasir.

### MVP Mock Kalacak Alanlar

- Fotoğrafla ogun analizi
- Sesli giris
- Gercek odeme
- Push notification
- Gelismis fasting analitiği
- Gelismis grafikler
- Premium ekraninin backend baglantisi
