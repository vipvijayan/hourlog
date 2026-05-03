class TimeRecord {
  final int? id;
  final int checkIn; // milliseconds since epoch
  final int? checkOut; // milliseconds since epoch, null if active

  TimeRecord({this.id, required this.checkIn, this.checkOut});

  DateTime get checkInTime => DateTime.fromMillisecondsSinceEpoch(checkIn);
  DateTime? get checkOutTime =>
      checkOut != null ? DateTime.fromMillisecondsSinceEpoch(checkOut!) : null;

  Duration? get duration {
    if (checkOut == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  bool get isActive => checkOut == null;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'check_in': checkIn,
      'check_out': checkOut,
    };
  }

  factory TimeRecord.fromMap(Map<String, dynamic> map) {
    return TimeRecord(
      id: map['id'] as int?,
      checkIn: map['check_in'] as int,
      checkOut: map['check_out'] as int?,
    );
  }

  TimeRecord copyWith({int? id, int? checkIn, int? checkOut}) {
    return TimeRecord(
      id: id ?? this.id,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
    );
  }
}
