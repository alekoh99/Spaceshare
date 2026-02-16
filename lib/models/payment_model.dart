
/// Payment Model - Handles rent splits and utility payments
class Payment {
  final String paymentId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency; // 'USD', 'CAD', etc.
  final String type; // 'rent', 'utility', 'other'
  final String description; // e.g., "August Rent", "Electricity Split"
  
  // Stripe Integration
  final String stripePaymentIntentId;
  final String status; // 'pending', 'processing', 'completed', 'failed', 'disputed', 'refunded'
  final String? stripeTransferId; // For Stripe Connect transfers
  
  // Dates
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  
  // Dispute Info
  final String? disputeId;
  final String? disputeReason;
  
  // Associated Match (optional)
  final String? matchId;
  final String? listingId;
  
  // Metadata
  final Map<String, dynamic>? metadata; // For storing additional info

  Payment({
    required this.paymentId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.description,
    required this.stripePaymentIntentId,
    required this.status,
    this.stripeTransferId,
    required this.createdAt,
    required this.dueDate,
    this.paidAt,
    this.refundedAt,
    this.disputeId,
    this.disputeReason,
    this.matchId,
    this.listingId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'currency': currency,
      'type': type,
      'description': description,
      'stripe': {
        'paymentIntentId': stripePaymentIntentId,
        'transferId': stripeTransferId,
      },
      'status': status,
      'dates': {
        'createdAt': createdAt,
        'dueDate': dueDate,
        'paidAt': paidAt,
        'refundedAt': refundedAt,
      },
      'dispute': {
        'disputeId': disputeId,
        'reason': disputeReason,
      },
      'associatedData': {
        'matchId': matchId,
        'listingId': listingId,
      },
      'metadata': metadata,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    final stripe = json['stripe'] as Map<String, dynamic>? ?? {};
    final dates = json['dates'] as Map<String, dynamic>? ?? {};
    final dispute = json['dispute'] as Map<String, dynamic>? ?? {};
    final associatedData =
        json['associatedData'] as Map<String, dynamic>? ?? {};

    return Payment(
      paymentId: json['paymentId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      type: json['type'] as String,
      description: json['description'] as String,
      stripePaymentIntentId: stripe['paymentIntentId'] as String,
      status: json['status'] as String,
      stripeTransferId: stripe['transferId'] as String?,
      createdAt: dates['createdAt'] is String
          ? DateTime.parse(dates['createdAt'])
          : DateTime.parse(json['createdAt'] as String),
      dueDate: dates['dueDate'] is String
          ? DateTime.parse(dates['dueDate'])
          : DateTime.parse(json['dueDate'] as String),
      paidAt: dates['paidAt'] is String ? DateTime.parse(dates['paidAt']) : null,
      refundedAt: dates['refundedAt'] is String ? DateTime.parse(dates['refundedAt']) : null,
      disputeId: dispute['disputeId'] as String?,
      disputeReason: dispute['reason'] as String?,
      matchId: associatedData['matchId'] as String?,
      listingId: associatedData['listingId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Payment copyWith({
    String? status,
    DateTime? paidAt,
    String? stripeTransferId,
    String? disputeId,
    String? disputeReason,
    DateTime? refundedAt,
  }) {
    return Payment(
      paymentId: paymentId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      currency: currency,
      type: type,
      description: description,
      stripePaymentIntentId: stripePaymentIntentId,
      status: status ?? this.status,
      stripeTransferId: stripeTransferId ?? this.stripeTransferId,
      createdAt: createdAt,
      dueDate: dueDate,
      paidAt: paidAt ?? this.paidAt,
      refundedAt: refundedAt ?? this.refundedAt,
      disputeId: disputeId ?? this.disputeId,
      disputeReason: disputeReason ?? this.disputeReason,
      matchId: matchId,
      listingId: listingId,
      metadata: metadata,
    );
  }
}
/// Stripe Connect Account Model
class StripeConnectAccount {
  final String userId;
  final String connectId;
  final bool isConnected;
  final bool chargesEnabled;
  final bool transfersEnabled;
  final String? bankAccountId;
  final String? bankAccountLast4;
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  StripeConnectAccount({
    required this.userId,
    required this.connectId,
    required this.isConnected,
    this.chargesEnabled = false,
    this.transfersEnabled = false,
    this.bankAccountId,
    this.bankAccountLast4,
    this.createdAt,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'connectId': connectId,
      'isConnected': isConnected,
      'chargesEnabled': chargesEnabled,
      'transfersEnabled': transfersEnabled,
      'bankAccountId': bankAccountId,
      'bankAccountLast4': bankAccountLast4,
      'createdAt': createdAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory StripeConnectAccount.fromJson(Map<String, dynamic> json) {
    return StripeConnectAccount(
      userId: json['userId'] as String,
      connectId: json['connectId'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      chargesEnabled: json['chargesEnabled'] as bool? ?? false,
      transfersEnabled: json['transfersEnabled'] as bool? ?? false,
      bankAccountId: json['bankAccountId'] as String?,
      bankAccountLast4: json['bankAccountLast4'] as String?,
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : null,
      verifiedAt: json['verifiedAt'] is String ? DateTime.parse(json['verifiedAt']) : null,
    );
  }
}

/// Payment Split Model - for splitting rent/utilities among roommates
class PaymentSplit {
  final String splitId;
  final String userId;
  final String paymentId;
  final double amount;
  final double percentage; // Percentage of total
  final String currency;
  final String status; // 'pending', 'approved', 'completed'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final String? notes;

  PaymentSplit({
    required this.splitId,
    required this.userId,
    required this.paymentId,
    required this.amount,
    required this.percentage,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'splitId': splitId,
      'userId': userId,
      'paymentId': paymentId,
      'amount': amount,
      'percentage': percentage,
      'currency': currency,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      splitId: json['splitId'] as String,
      userId: json['userId'] as String,
      paymentId: json['paymentId'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String,
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : DateTime.now(),
      approvedAt: json['approvedAt'] is String ? DateTime.parse(json['approvedAt']) : null,
      completedAt: json['completedAt'] is String ? DateTime.parse(json['completedAt']) : null,
      notes: json['notes'] as String?,
    );
  }
}

/// Payout Model - for withdrawing earned money
class Payout {
  final String payoutId;
  final String userId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String? stripePayoutId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final String? failureReason;
  final List<String>? relatedPaymentIds;
  final String? bankAccountLast4;

  Payout({
    required this.payoutId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.stripePayoutId,
    required this.createdAt,
    this.completedAt,
    this.failedAt,
    this.failureReason,
    this.relatedPaymentIds,
    this.bankAccountLast4,
  });

  Map<String, dynamic> toJson() {
    return {
      'payoutId': payoutId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'stripePayoutId': stripePayoutId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'failureReason': failureReason,
      'relatedPaymentIds': relatedPaymentIds,
      'bankAccountLast4': bankAccountLast4,
    };
  }

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      payoutId: json['payoutId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String,
      stripePayoutId: json['stripePayoutId'] as String?,
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt']) : DateTime.now(),
      completedAt: json['completedAt'] is String ? DateTime.parse(json['completedAt']) : null,
      failedAt: json['failedAt'] is String ? DateTime.parse(json['failedAt']) : null,
      failureReason: json['failureReason'] as String?,
      relatedPaymentIds: List<String>.from(json['relatedPaymentIds'] as List? ?? []),
      bankAccountLast4: json['bankAccountLast4'] as String?,
    );
  }
}