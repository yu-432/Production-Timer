class FocusStats {
  const FocusStats({
    required this.todayTotal,
    required this.weeklyHours,
    required this.monthlyHours,
  });

  final Duration todayTotal;
  final double weeklyHours;
  final double monthlyHours;
}
