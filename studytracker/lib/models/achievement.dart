class Achievement {
  final String id;
  final String title;
  final String description;
  final int progress; 
  final int target; 
  final bool unlocked;
  final String type; 
  final String icon; 

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
