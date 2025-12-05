class Achievement {
  final String id;
  final String title;
  final String description;
  final int progress; // trenutna vrednost (minuta, dana…)
  final int target; // cilj
  final bool unlocked;
  final String type; // npr. "time", "streak", "session"
  final String icon; // samo ime ikonice za UI, npr. "star", "fire"

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.unlocked,
    required this.type,
    required this.icon,
  });
}
