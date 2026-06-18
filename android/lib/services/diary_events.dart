import 'package:flutter/foundation.dart';

/// 全局日记更新通知器，当日记被保存/更新时递增
final ValueNotifier<int> diaryUpdateNotifier = ValueNotifier<int>(0);

void notifyDiaryUpdated() {
  diaryUpdateNotifier.value++;
}
