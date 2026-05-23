import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/notification.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    required String type,
    required DateTime timestamp,
    @Default(false) bool isRead,
    Map<String, dynamic>? data,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  factory NotificationModel.fromEntity(AppNotification entity) {
    return NotificationModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      type: entity.type.name,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      data: entity.data,
    );
  }
}

extension NotificationModelX on NotificationModel {
  AppNotification toEntity() => AppNotification(
        id: id,
        title: title,
        body: body,
        type: NotificationType.values.byName(type),
        timestamp: timestamp,
        isRead: isRead,
        data: data,
      );
}
