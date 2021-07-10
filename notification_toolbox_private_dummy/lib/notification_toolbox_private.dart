import 'dart:async';

Future<bool> initializeNotificationChannelManager() => throw UnimplementedError(
    'This is a dummy package! You need to implement it yourself.');

Future<List<NotificationChannelData>> getNotificationChannelDataForPackage(
  String packageName,
  int uid,
) =>
    throw UnimplementedError(
        'This is a dummy package! You need to implement it yourself.');

Future<bool> updateNotificationChannelImportanceForPackage(String packageName,
        int uid, NotificationChannelData channelData, int importance) =>
    throw UnimplementedError(
        'This is a dummy package! You need to implement it yourself.');

class NotificationChannelData {
  static const importanceUnspecified = 0;
  static const importanceNone = 0;
  static const importanceMin = 0;
  static const importanceLow = 0;
  static const importanceDefault = 0;
  static const importanceHigh = 0;
  static const importanceMax = 0;

  String get id => throw UnimplementedError(
      'This is a dummy package! You need to implement it yourself.');

  String? get conversationId => throw UnimplementedError(
      'This is a dummy package! You need to implement it yourself.');

  String get name => throw UnimplementedError(
      'This is a dummy package! You need to implement it yourself.');

  String? get description => throw UnimplementedError(
      'This is a dummy package! You need to implement it yourself.');

  int get importance => throw UnimplementedError(
      'This is a dummy package! You need to implement it yourself.');

  const NotificationChannelData({
    required String id,
    String? conversationId,
    required String name,
    String? description,
    required int importance,
  }) : assert(
          importance == importanceUnspecified ||
              importance == importanceNone ||
              importance == importanceMin ||
              importance == importanceLow ||
              importance == importanceDefault ||
              importance == importanceHigh ||
              importance == importanceMax,
          'Invalid notification importance!',
        );

  factory NotificationChannelData.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError(
          'This is a dummy package! You need to implement it yourself.');
}
