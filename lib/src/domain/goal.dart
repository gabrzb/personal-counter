String dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class Goal {
  Goal({required this.id, required this.name, required this.target,
    required this.icon, this.notes = '', Iterable<String> dates = const []})
      : dates = Set.unmodifiable(dates);
  final int id;
  final String name;
  final int target;
  final String icon;
  final String notes;
  final Set<String> dates;
  int get days => dates.length;
  double get progress => (days / target).clamp(0, 1);
  bool get complete => days >= target;
  bool registered(DateTime date) => dates.contains(dayKey(date));
  Goal copyWith({String? name, int? target, String? icon, String? notes,
    Iterable<String>? dates}) => Goal(id: id, name: name ?? this.name,
      target: target ?? this.target, icon: icon ?? this.icon,
      notes: notes ?? this.notes, dates: dates ?? this.dates);
}
