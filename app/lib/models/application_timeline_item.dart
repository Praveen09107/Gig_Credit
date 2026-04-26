class ApplicationTimelineItem {
  final String title;
  final String description;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isCurrent;

  const ApplicationTimelineItem({
    required this.title,
    required this.description,
    this.completedAt,
    required this.isCompleted,
    required this.isCurrent,
  });

  factory ApplicationTimelineItem.fromJson(Map<String, dynamic> json) => ApplicationTimelineItem(
    title: json['title'] as String,
    description: json['description'] as String,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    isCompleted: json['isCompleted'] as bool,
    isCurrent: json['isCurrent'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'completedAt': completedAt?.toIso8601String(),
    'isCompleted': isCompleted,
    'isCurrent': isCurrent,
  };
}
