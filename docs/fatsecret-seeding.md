# FatSecret Seeding

DB'yi kullanici aramalariyla organik olarak dolduracagiz. MVP baslangicinda temel besinleri hizli eklemek icin `seed-fatsecret-foods` Edge Function'i var.

## Dashboard ile Secret Ekleme

1. Supabase dashboard'u ac:
   `https://supabase.com/dashboard/project/ifjghwsdpujzopppurdr/settings/functions`
2. `Secrets` bolumune gir.
3. Asagidaki 4 secret'i tek tek ekle.
4. Kaydet. Function'lari tekrar deploy etmeye gerek yok; Supabase secrets'i hemen okur.

Gerekli Supabase Function Secrets:

```text
FATSECRET_CLIENT_ID=...
FATSECRET_CLIENT_SECRET=...
SEED_ADMIN_KEY=<uzun-rastgele-deger>
```

Supabase CLI varsa:

```bash
supabase secrets set FATSECRET_CLIENT_ID=... FATSECRET_CLIENT_SECRET=... SEED_ADMIN_KEY=...
```

Seed calistirma:

```bash
curl -X POST "https://ifjghwsdpujzopppurdr.supabase.co/functions/v1/seed-fatsecret-foods" \
  -H "Content-Type: application/json" \
  -H "x-seed-key: <SEED_ADMIN_KEY>" \
  -d "{\"queries\":[\"egg\",\"chicken breast\",\"plain yogurt\",\"white rice\"]}"
```

Secret'lar set edilmeden function FatSecret'e baglanamaz.
