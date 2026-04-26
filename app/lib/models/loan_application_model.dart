import '../core/enums/app_enums.dart';
import 'loan_offer_model.dart';
import 'application_timeline_item.dart';

class LoanApplicationModel {
  final String id;
  final LoanOfferModel offer;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime lastUpdatedAt;
  final String referenceNumber;
  final List<ApplicationTimelineItem> timeline;

  const LoanApplicationModel({
    required this.id,
    required this.offer,
    required this.status,
    required this.appliedAt,
    required this.lastUpdatedAt,
    required this.referenceNumber,
    required this.timeline,
  });

  factory LoanApplicationModel.fromJson(Map<String, dynamic> json) => LoanApplicationModel(
    id: json['id'] as String,
    offer: LoanOfferModel.fromJson(json['offer']),
    status: ApplicationStatus.values.firstWhere((e) => e.name == json['status']),
    appliedAt: DateTime.parse(json['appliedAt'] as String),
    lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    referenceNumber: json['referenceNumber'] as String,
    timeline: (json['timeline'] as List).map((e) => ApplicationTimelineItem.fromJson(e)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'offer': offer.toJson(),
    'status': status.name,
    'appliedAt': appliedAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'referenceNumber': referenceNumber,
    'timeline': timeline.map((e) => e.toJson()).toList(),
  };

  LoanApplicationModel copyWith({
    ApplicationStatus? status,
    DateTime? lastUpdatedAt,
    List<ApplicationTimelineItem>? timeline,
  }) {
    return LoanApplicationModel(
      id: id,
      offer: offer,
      status: status ?? this.status,
      appliedAt: appliedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      referenceNumber: referenceNumber,
      timeline: timeline ?? this.timeline,
    );
  }
}
