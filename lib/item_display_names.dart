// -------------------------------------------------------------
// ITEM DISPLAY NAME OVERLAY (oyun ici gorunen adlar)
// -------------------------------------------------------------
// items_catalog.json 'name' alanlari script isimleridir (WaterBottle gibi).
// Bu overlay, PZ'nin resmi EN ceviri tablosundan (B42) uretilen
// display name sozlugunu yukler: 'base.waterbottle' -> 'Water Bottle'.
// Once catalog 'name' gosterilir; ceviri varsa o bas tutar.
part of 'main.dart';

class ItemDisplayNames {
  ItemDisplayNames._();
  static Map<String, String>? _map; // 'base.waterbottle' -> 'Water Bottle'
  static Map<String, String>? _reverse; // 'water bottle' -> 'base.waterbottle'

  static Future<void> load() async {
    if (_map != null) return;
    try {
      final raw = await rootBundle.loadString(
        'assets/item_display_names.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final m = <String, String>{};
      final r = <String, String>{};
      decoded.forEach((k, v) {
        m[k.toLowerCase()] = v.toString();
        // reverse: ilk vanilaya (base.) oncelik
        final rk = v.toString().toLowerCase();
        if (!r.containsKey(rk) || k.toLowerCase().startsWith('base.')) {
          r[rk] = k.toLowerCase();
        }
      });
      _map = m;
      _reverse = r;
    } catch (_) {
      _map = {};
      _reverse = {};
    }
  }

  /// Catalog name alanini oyun ici isimle degistirir (fallback: mevcut ad).
  static String displayName(String itemId, String fallbackName) {
    final m = _map;
    if (m == null || m.isEmpty) return fallbackName;
    final hit = m[itemId.toLowerCase()];
    return hit ?? _prettyFallback(itemId, fallbackName);
  }

  /// Display name -> olasi item id (cocuk esyalari cozmek icin).
  static String? idFromDisplay(String displayName) =>
      _reverse?[displayName.toLowerCase()];

  /// Script ismini okunur sekilde bo'l: Bag_ALICEpack -> Bag ALICEpack
  static String _prettyFallback(String itemId, String fallback) {
    final raw = itemId.contains('.') ? itemId.split('.').last : itemId;
    if (fallback != raw) return fallback;
    return raw.replaceAll('_', ' ');
  }
}