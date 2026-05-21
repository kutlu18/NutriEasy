# Open Food Facts Seeding

Open Food Facts icin scraping yapmiyoruz. Resmi API ve ileride resmi JSONL/CSV dump kullanacagiz.

MVP seed endpoint:

```bash
curl -X POST "https://ifjghwsdpujzopppurdr.supabase.co/functions/v1/seed-openfoodfacts-foods" \
  -H "Content-Type: application/json" \
  -H "x-seed-key: <SEED_ADMIN_KEY>" \
  -d "{\"queries\":[\"egg\",\"chicken breast\",\"plain yogurt\"],\"pageSize\":20}"
```

Veri `source = openfoodfacts` ile `foods` tablosuna yazilir. `food_servings` varsayilan porsiyon degerini tutar; Open Food Facts'in ham 100 g besin detaylari ayrica `nutrients_100g` icinde korunur.

## Storage Strategy

Open Food Facts tam katalog importunda raw JSON payload'i iki tabloda saklamak cok hizli buyur. Bu nedenle:

- `foods` urun kimligi, marka, kategori, icerik, alerjen, NutriScore, NOVA, EcoScore, etiket ve kaynak metadata kolonlarini tutar.
- `food_servings` porsiyon bazli makro/mikro besin kolonlarini ve ham 100 g nutrient detaylarini `nutrients_100g` icinde tutar.
- Open Food Facts icin `foods.raw_source` ve `food_servings.raw_source` bos birakilir; tekrar gereken alanlar resmi dump'tan yeniden turetilebilir.
- Importer `skipExisting` ile hem food hem serving var olan barkodlari atlar; serving eksikse ayni barkodu yeniden isleyerek onarir.

Lisans notu: Open Food Facts verisi ODbL kapsamindadir. Public kullanimda attribution gerekir; turetilmis/veri tabani paylasimi senaryolarinda share-alike etkisi degerlendirilmelidir.
