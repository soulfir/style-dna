import 'package:flutter/material.dart';

Color colorFromName(String name) {
  final key = name.toLowerCase().trim();
  if (_colorMap.containsKey(key)) return _colorMap[key]!;

  // Try partial matches
  for (final entry in _colorMap.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) {
      return entry.value;
    }
  }

  // Hash fallback: generate a deterministic color from the string
  int hash = key.hashCode;
  return HSLColor.fromAHSL(
    1.0,
    (hash % 360).toDouble(),
    0.5 + (hash % 30) / 100.0,
    0.4 + (hash % 20) / 100.0,
  ).toColor();
}

const Map<String, Color> _colorMap = {
  // Reds
  'red': Color(0xFFDC2626),
  'crimson': Color(0xFFDC143C),
  'scarlet': Color(0xFFFF2400),
  'ruby': Color(0xFFE0115F),
  'rose': Color(0xFFFF007F),
  'cherry': Color(0xFFDE3163),
  'burgundy': Color(0xFF800020),
  'maroon': Color(0xFF800000),
  'wine': Color(0xFF722F37),
  'blood red': Color(0xFF660000),

  // Oranges
  'orange': Color(0xFFF97316),
  'tangerine': Color(0xFFF28500),
  'amber': Color(0xFFFFBF00),
  'rust': Color(0xFFB7410E),
  'burnt orange': Color(0xFFCC5500),
  'burnt sienna': Color(0xFFE97451),
  'sienna': Color(0xFFA0522D),
  'copper': Color(0xFFB87333),
  'peach': Color(0xFFFFDAB9),
  'coral': Color(0xFFFF7F50),
  'salmon': Color(0xFFFA8072),
  'terracotta': Color(0xFFE2725B),

  // Yellows
  'yellow': Color(0xFFEAB308),
  'gold': Color(0xFFFFD700),
  'golden': Color(0xFFFFD700),
  'warm gold': Color(0xFFD4A017),
  'honey': Color(0xFFEB9605),
  'mustard': Color(0xFFFFDB58),
  'saffron': Color(0xFFF4C430),
  'lemon': Color(0xFFFFF44F),
  'cream': Color(0xFFFFFDD0),
  'ivory': Color(0xFFFFFFF0),
  'wheat': Color(0xFFF5DEB3),
  'champagne': Color(0xFFF7E7CE),
  'blonde': Color(0xFFFAF0BE),

  // Greens
  'green': Color(0xFF22C55E),
  'emerald': Color(0xFF50C878),
  'sage': Color(0xFFBCB88A),
  'olive': Color(0xFF808000),
  'forest': Color(0xFF228B22),
  'forest green': Color(0xFF228B22),
  'moss': Color(0xFF8A9A5B),
  'mint': Color(0xFF98FF98),
  'jade': Color(0xFF00A86B),
  'lime': Color(0xFF32CD32),
  'teal': Color(0xFF008080),
  'sea green': Color(0xFF2E8B57),
  'hunter green': Color(0xFF355E3B),
  'pine': Color(0xFF01796F),
  'pistachio': Color(0xFF93C572),

  // Blues
  'blue': Color(0xFF3B82F6),
  'navy': Color(0xFF000080),
  'cobalt': Color(0xFF0047AB),
  'azure': Color(0xFF007FFF),
  'cerulean': Color(0xFF007BA7),
  'sky blue': Color(0xFF87CEEB),
  'powder blue': Color(0xFFB0E0E6),
  'steel blue': Color(0xFF4682B4),
  'midnight': Color(0xFF191970),
  'midnight blue': Color(0xFF191970),
  'royal blue': Color(0xFF4169E1),
  'indigo': Color(0xFF4B0082),
  'periwinkle': Color(0xFFCCCCFF),
  'cornflower': Color(0xFF6495ED),
  'denim': Color(0xFF1560BD),
  'ice blue': Color(0xFF99C5C4),
  'slate': Color(0xFF708090),
  'slate blue': Color(0xFF6A5ACD),
  'cyan': Color(0xFF00FFFF),
  'turquoise': Color(0xFF40E0D0),
  'aqua': Color(0xFF00FFFF),
  'aquamarine': Color(0xFF7FFFD4),
  'electric blue': Color(0xFF7DF9FF),

  // Purples
  'purple': Color(0xFF9333EA),
  'violet': Color(0xFF7F00FF),
  'lavender': Color(0xFFE6E6FA),
  'lilac': Color(0xFFC8A2C8),
  'plum': Color(0xFF8E4585),
  'magenta': Color(0xFFFF00FF),
  'mauve': Color(0xFFE0B0FF),
  'orchid': Color(0xFFDA70D6),
  'amethyst': Color(0xFF9966CC),
  'eggplant': Color(0xFF614051),
  'grape': Color(0xFF6F2DA8),
  'fuchsia': Color(0xFFFF00FF),

  // Pinks
  'pink': Color(0xFFEC4899),
  'hot pink': Color(0xFFFF69B4),
  'blush': Color(0xFFDE5D83),
  'dusty rose': Color(0xFFDCAE96),
  'bubblegum': Color(0xFFFFC1CC),

  // Browns
  'brown': Color(0xFF92400E),
  'chocolate': Color(0xFF7B3F00),
  'coffee': Color(0xFF6F4E37),
  'espresso': Color(0xFF3C1414),
  'mocha': Color(0xFF967969),
  'tan': Color(0xFFD2B48C),
  'beige': Color(0xFFF5F5DC),
  'khaki': Color(0xFFC3B091),
  'caramel': Color(0xFFFFD59A),
  'umber': Color(0xFF635147),
  'chestnut': Color(0xFF954535),
  'mahogany': Color(0xFFC04000),
  'walnut': Color(0xFF773F1A),
  'cinnamon': Color(0xFFD2691E),
  'sepia': Color(0xFF704214),

  // Neutrals
  'black': Color(0xFF1A1A1A),
  'charcoal': Color(0xFF36454F),
  'graphite': Color(0xFF383838),
  'dark gray': Color(0xFF555555),
  'dark grey': Color(0xFF555555),
  'gray': Color(0xFF808080),
  'grey': Color(0xFF808080),
  'silver': Color(0xFFC0C0C0),
  'light gray': Color(0xFFD3D3D3),
  'light grey': Color(0xFFD3D3D3),
  'ash': Color(0xFFB2BEB5),
  'white': Color(0xFFF5F5F5),
  'snow': Color(0xFFFFFAFA),
  'pearl': Color(0xFFEAE0C8),
  'off-white': Color(0xFFFAF9F6),

  // Metallics
  'bronze': Color(0xFFCD7F32),
  'brass': Color(0xFFB5A642),
  'pewter': Color(0xFF8E8E8E),
  'platinum': Color(0xFFE5E4E2),
  'titanium': Color(0xFF878681),

  // Nature-inspired
  'sand': Color(0xFFC2B280),
  'clay': Color(0xFFB66A50),
  'stone': Color(0xFF928E85),
  'dusk': Color(0xFF4E5481),
  'dawn': Color(0xFFF3C4A0),
  'sunset': Color(0xFFFAD6A5),
  'ocean': Color(0xFF006994),
  'seafoam': Color(0xFF93E9BE),
};
