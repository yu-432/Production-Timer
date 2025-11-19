/// 集中作業時間の統計情報を保持するモデルクラス
///
/// 過去のタイマー記録から計算された統計データを格納します。
/// このクラスは計算結果を保持するだけで、計算ロジックはproviderにあります。
class FocusStats {
  const FocusStats({
    required this.todayTotal, // 今日の合計作業時間
    required this.weeklyHours, // 過去7日間の合計時間(時間単位)
    required this.monthlyHours, // 過去30日間の合計時間(時間単位)
  });

  final Duration todayTotal; // 今日の合計時間(Duration型で保持)
  final double weeklyHours; // 週間合計時間(時間単位の小数)
  final double monthlyHours; // 月間合計時間(時間単位の小数)
}
