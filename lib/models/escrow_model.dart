/// Escrow Model - Security deposit and payment holds
class EscrowHold {
  final String escrowId;
  final String paymentId;
  final String userId; // User whose funds are held
  final double amount;
  final String reason; // 'dispute_protection' or 'disputed'
  final String status; // 'held', 'released', 'disputed', 'refunded'
  final DateTime createdAt;
  final DateTime releaseDate; // When escrow can be released (14 days default)
  final DateTime? releasedAt;
  final DateTime? disputeStartedAt;
  final String? disputeReason;
  final String? releaseReason;
  final Map<String, dynamic>? metadata;

  EscrowHold({
    required this.escrowId,
    required this.paymentId,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.releaseDate,
    this.releasedAt,
    this.disputeStartedAt,
    this.disputeReason,
    this.releaseReason,
    this.metadata,
  });

  /// Days remaining until automatic release
  int get daysUntilRelease {
    final diff = releaseDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Is escrow still held?
  bool get isHeld => status == 'held' || status == 'disputed';

  Map<String, dynamic> toJson() {
    return {
      'escrowId': escrowId,
      'paymentId': paymentId,
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'releaseDate': releaseDate.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
      'disputeStartedAt': disputeStartedAt?.toIso8601String(),
      'disputeReason': disputeReason,
      'releaseReason': releaseReason,
      'metadata': metadata,
    };
  }

  factory EscrowHold.fromJson(Map<String, dynamic> json) {
    return EscrowHold(
      escrowId: json['escrowId'] as String,
      paymentId: json['paymentId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'] as String)
          : null,
      disputeStartedAt: json['disputeStartedAt'] != null
          ? DateTime.parse(json['disputeStartedAt'] as String)
          : null,
      disputeReason: json['disputeReason'] as String?,
      releaseReason: json['releaseReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Refund Model - Payment refunds and chargebacks
class Refund {
  final String refundId;
  final String stripeRefundId;
  final String paymentId;
  final String originatorUserId; // User receiving refund
  final double amount;
  final String reason;
  final String status; // 'pending', 'succeeded', 'failed'
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? processedAt;

  Refund({
    required this.refundId,
    required this.stripeRefundId,
    required this.paymentId,
    required this.originatorUserId,
    required this.amount,
    required this.reason,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'refundId': refundId,
      'stripeRefundId': stripeRefundId,
      'paymentId': paymentId,
      'originatorUserId': originatorUserId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      refundId: json['refundId'] as String,
      stripeRefundId: json['stripeRefundId'] as String,
      paymentId: json['paymentId'] as String,
      originatorUserId: json['originatorUserId'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }
}

/// Fee Variant for A/B testing
class FeeVariant {
  final String variantId; // 'variant_a', 'variant_b'
  final String name; // Display name
  final double stripePercentage; // Stripe's cut (%)
  final double stripeFixed; // Stripe's fixed fee ($)
  final double platformPercentage; // SpaceShare's cut (%)

  FeeVariant({
    required this.variantId,
    required this.name,
    required this.stripePercentage,
    required this.stripeFixed,
    required this.platformPercentage,
  });

  /// Calculate total fees in cents
  int calculateFeesCents(int amountCents) {
    final stripeFee =
        (amountCents * stripePercentage + stripeFixed * 100).toInt();
    final platformFee = (amountCents * platformPercentage).toInt();
    return stripeFee + platformFee;
  }

  /// Calculate amount recipient receives
  double getRecipientAmount(double senderAmount) {
    final feeCents = calculateFeesCents((senderAmount * 100).toInt());
    return (senderAmount * 100 - feeCents) / 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'name': name,
      'stripePercentage': stripePercentage,
      'stripeFixed': stripeFixed,
      'platformPercentage': platformPercentage,
    };
  }

  factory FeeVariant.fromJson(Map<String, dynamic> json) {
    return FeeVariant(
      variantId: json['variantId'] as String,
      name: json['name'] as String,
      stripePercentage: (json['stripePercentage'] as num).toDouble(),
      stripeFixed: (json['stripeFixed'] as num).toDouble(),
      platformPercentage: (json['platformPercentage'] as num).toDouble(),
    );
  }
}
