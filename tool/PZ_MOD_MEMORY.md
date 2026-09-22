# Zomboclat Proje Kuralları ve Hafıza

## PZ Mod Translate (Çeviri) Kuralları
- **Mod translate dosyalarında SADECE İngilizce (EN) kullanılır; Türkçe eklenmez.**
- Translate konumu: `mods/<ModAdi>/42.20/media/lua/shared/Translate/EN/Recipes_EN.json` (B42 JSON formatı: `{ "RecipeID": "Display Name" }`)
- Sunucudaki workshop kopyasına yapılan geçici düzeltmeler kalıcı değildir; her değişiklik önce yerel publish kaynağında (`C:\Users\ardat\Zomboid\Workshop\...`) yapılır, sonra Steam Workshop'a publish edilir.

## Workshop Publish Akışı (Zomboclat Server Fixes, WS ID 3788844491)
1. Yerel kaynak: `C:\Users\ardat\Zomboid\Workshop\Zomboclat Server Fixes\` (workshop.txt + preview.png + Contents\)
2. Build VDF: `C:\steamcmd\update_zomboclat.vdf` (publishedfileid 3788844491, changenote güncellenir)
3. Publish: `C:\steamcmd\steamcmd.exe +login <user> +workshop_build_item C:\steamcmd\update_zomboclat.vdf +quit`
4. Sunucu modu workshop'tan çeker — sunucudaki workshop kopyasına elle asla kalıcı fix yazılmaz (acil test için geçici olabilir ama ardından publish şart).

## Bilinen PZ B42 Teknik Notları
- `craftRecipe` adlarında boşluk olamaz (parser sessizce yutar, tarif oyunda görünmez). Alt çizgi kullan: `Craft_Clay`.
- Tarif görünen adları Translate/EN/Recipes_EN.json'dan gelir.
- Sandbox değerleri sunucu açılışında okunur; canlı değişiklik restart ister.
- CSP (Crafting Skills Practice) XP'leri `OnGameStart`'ta recipe'ye baked edilir (`CSPOverride.lua`), sandbox değişikliği ancak restart sonrası etkili; taban XP integer'a yuvarlanır (`floor(x+0.5)`).
- Woodwork XP eşikleri (per level): 75,150,300,750,1500,3000,4500,6000,7500,9000. Kitap çarpanları: Vol1 3x(L0-1), Vol2 5x(L2-3), Vol3 8x(L4-5), Vol4 12x(L6-7), Vol5 16x(L8-9).
- XP çarpan zinciri: XPBoost yoksa 0.25 (varsa 1/1.33/1.66) x FastLearner/Crafty 1.3 x kitap x sandbox MultiplierConfig.
- Sunucu mod listesinde ID doğrulama regex'i `[A-Za-z0-9_.-]{1,128}`; allowlist `_MOD_ID_ALLOWLIST` içinde 12 istisna mod var (api_server.py).

## Sunucu Yönetimi Notları
- INI değişiklikleri öncesi yedek: `pzserver.ini.<context>.bak`
- Mod ekleme script kalıbı: Mods=/WorkshopItems= satırlarını python ile parse edip tekrarsız ekle.
- SSH: `ssh pz-vps` (root), API: `zomboclat-api.service`, oyun: `pzserver.service`.