

/// Status of an event registration
enum RegistrationStatus {
  registered,
  checkedIn,
  cancelled,
  noShow;

  String get displayName {
    switch (this) {
      case RegistrationStatus.registered:
        return 'Registered';
      case RegistrationStatus.checkedIn:
        return 'Checked In';
      case RegistrationStatus.cancelled:
        return 'Cancelled';
      case RegistrationStatus.noShow:
        return 'No Show';
    }
  }
}

/// Represents a user's registration for an event
class EventRegistration {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic>? formResponses;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    this.status = RegistrationStatus.registered,
    required this.registeredAt,
    this.checkedInAt,
    this.cancelledAt,
    this.formResponses,
  });

  bool get isRegistered => status == RegistrationStatus.registered;
  bool get isCheckedIn => status == RegistrationStatus.checkedIn;
  bool get isCancelled => status == RegistrationStatus.cancelled;

  EventRegistration copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    RegistrationStatus? status,
    DateTime? registeredAt,
    DateTime? checkedInAt,
    DateTime? cancelledAt,
    Map<String, dynamic>? formResponses,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      formResponses: formResponses ?? this.formResponses,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'userId': userId,
      'userName': userName,
      'status': status.name,
      'registeredAt': registeredAt.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'formResponses': formResponses,
    };
  }

  factory EventRegistration.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return EventRegistration(
      id: id ?? data['id'] ?? '',
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      status: RegistrationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RegistrationStatus.registered,
      ),
      registeredAt: data['registeredAt'] != null ? DateTime.parse(data['registeredAt']) : DateTime.now(),
      checkedInAt: data['checkedInAt'] != null ? DateTime.parse(data['checkedInAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? DateTime.parse(data['cancelledAt']) : null,
      formResponses: data['formResponses'] as Map<String, dynamic>?,
    );
  }
}
