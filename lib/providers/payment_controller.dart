import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/stripe_connect_service.dart';
import '../utils/logger.dart';
import 'auth_controller.dart';

class PaymentController extends GetxController {
  late IPaymentService _paymentService;
  late IStripeConnectService _stripeConnectService;

  IPaymentService get paymentService => _paymentService;
  IStripeConnectService get stripeConnectService => _stripeConnectService;

  // State
  final payments = RxList<Payment>([]);
  final currentPayment = Rx<Payment?>(null);
  final isProcessing = false.obs;
  final isLoadingPayments = false.obs;
  final error = Rx<String?>(null);
  final paymentStats = Rx<Map<String, dynamic>>({});
  final totalPending = 0.0.obs;
  final totalCompleted = 0.0.obs;

  // Stripe Connect State
  final stripeConnectAccount = Rx<StripeConnectAccount?>(null);
  final paymentSplits = RxList<PaymentSplit>([]);
  final payouts = RxList<Payout>([]);
  final payoutStats = Rx<Map<String, dynamic>>({});
  final isLoadingConnectAccount = false.obs;
  final isLoadingSplits = false.obs;
  final isLoadingPayouts = false.obs;

  // Payment form
  final paymentAmount = Rx<double?>(null);
  final paymentType = Rx<String?>(null); // 'rent', 'utility', 'other'
  final paymentDescription = TextEditingController();
  final paymentDueDate = Rx<dynamic>(null);
  final recipientUserId = Rx<String?>(null);

  late AuthController authController;

  @override
  void onInit() {
    super.onInit();
    try {
      _paymentService = Get.find<IPaymentService>();
      _stripeConnectService = Get.find<IStripeConnectService>();
    } catch (e) {
      debugPrint('Failed to resolve PaymentController services: $e');
      rethrow;
    }
    authController = Get.find<AuthController>();
    loadPaymentHistory();
  }

  Future<void> loadPaymentHistory({int limit = 50}) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingPayments.value = true;
      final paymentResult = await _paymentService.getPaymentHistory(
        authController.currentUserId.value!,
        limit: limit,
      );
      if (paymentResult.isSuccess()) {
        payments.value = paymentResult.getOrNull() ?? [];
      } else {
        throw paymentResult.getExceptionOrNull() ?? Exception('Failed to load payments');
      }
      calculateStats();
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingPayments.value = false;
    }
  }

  @override
  void onClose() {
    AppLogger.info('PaymentController', 'Disposing controller resources');
    paymentDescription.dispose();
    payments.clear();
    paymentSplits.clear();
    payouts.clear();
    super.onClose();
  }

  void calculateStats() {
    double pending = 0;
    double completed = 0;

    for (var payment in payments) {
      if (payment.status == 'pending') {
        pending += payment.amount;
      } else if (payment.status == 'completed') {
        completed += payment.amount;
      }
    }

    totalPending.value = pending;
    totalCompleted.value = completed;

    paymentStats.value = {
      'totalPayments': payments.length,
      'totalPending': pending,
      'totalCompleted': completed,
      'averageAmount': payments.isEmpty ? 0 : completed / payments.length,
    };
  }

  Future<void> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      if (paymentDueDate.value == null) {
        throw Exception('Due date is required');
      }

      if (recipientUserId.value == null) {
        throw Exception('Recipient is required');
      }

      isProcessing.value = true;
      error.value = null;

      final paymentIntentResult = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: currency,
        type: paymentType.value ?? 'other',
        description: description,
        recipientUserId: recipientUserId.value!,
        dueDate: paymentDueDate.value!,
      );

      if (!paymentIntentResult.isSuccess() || paymentIntentResult.getOrNull() == null) {
        throw paymentIntentResult.getExceptionOrNull() ?? Exception('Failed to create payment intent');
      }

      final paymentIntent = paymentIntentResult.getOrNull()!;

      currentPayment.value = Payment(
        paymentId: paymentIntent['paymentId'] as String,
        fromUserId: authController.currentUserId.value!,
        toUserId: recipientUserId.value!,
        amount: amount,
        currency: currency,
        type: paymentType.value ?? 'other',
        description: description,
        stripePaymentIntentId: paymentIntent['paymentIntentId'] as String? ?? '',
        status: 'pending',
        dueDate: (paymentDueDate.value ?? DateTime.now()) as DateTime,
        createdAt: DateTime.now(),
      );

      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> confirmPayment({
    required String paymentIntentId,
  }) async {
    try {
      if (currentPayment.value == null) {
        throw Exception('No payment to confirm');
      }

      isProcessing.value = true;
      error.value = null;

      final _ = await _paymentService.confirmPayment(
        currentPayment.value!.paymentId,
      );

      // Reload payment history
      await loadPaymentHistory();

      currentPayment.value = null;
      paymentDescription.clear();
      paymentAmount.value = null;
      paymentType.value = null;
      paymentDueDate.value = null;
      recipientUserId.value = null;

      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<double> calculateFee(double amount) async {
    try {
      final result = await _paymentService.calculateFee(amount);
      if (result.isSuccess()) {
        return result.getOrNull() ?? 0;
      } else {
        error.value = result.getExceptionOrNull()?.toString() ?? 'Failed to calculate fee';
        return 0;
      }
    } catch (e) {
      error.value = e.toString();
      return 0;
    }
  }

  void resetForm() {
    paymentDescription.clear();
    paymentAmount.value = null;
    paymentType.value = null;
    paymentDueDate.value = null;
    recipientUserId.value = null;
    error.value = null;
  }

  // ===== Stripe Connect Methods =====

  Future<void> loadStripeConnectAccount() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingConnectAccount.value = true;
      final accountResult = await _stripeConnectService.getConnectAccount(
        authController.currentUserId.value!,
      );
      if (accountResult.isSuccess()) {
        final accountData = accountResult.getOrNull();
        if (accountData != null) {
          stripeConnectAccount.value = StripeConnectAccount.fromJson(accountData);
        }
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingConnectAccount.value = false;
    }
  }

  Future<void> createStripeConnectAccount() async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      isProcessing.value = true;
      final result = await _stripeConnectService.createConnectAccount(
        authController.currentUserId.value!,
      );
      
      if (!result.isSuccess()) {
        throw result.getExceptionOrNull() ?? Exception('Failed to create connect account');
      }

      await loadStripeConnectAccount();
      Get.snackbar(
        'Success',
        'Stripe Connect account created. Set up banking info to enable payouts.',
      );
      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to create account');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> loadPaymentSplits() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingSplits.value = true;
      final splitsResult = await _stripeConnectService.getPaymentSplitsByUser(
        authController.currentUserId.value!,
      );
      
      if (splitsResult.isSuccess() && splitsResult.getOrNull() != null) {
        paymentSplits.value = splitsResult.getOrNull()!.map((split) => PaymentSplit.fromJson(split)).toList();
      } else {
        throw splitsResult.getExceptionOrNull() ?? Exception('Failed to load payment splits');
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingSplits.value = false;
    }
  }

  Future<void> createPaymentSplit({
    required String matchId,
    required String recipientId,
    required double totalAmount,
    required double userAmount,
    required String type,
    required String month,
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      isProcessing.value = true;
      final splitResult = await _stripeConnectService.createPaymentSplit({
        'matchId': matchId,
        'user1Id': authController.currentUserId.value!,
        'user2Id': recipientId,
        'totalAmount': totalAmount,
        'user1Amount': userAmount,
        'type': type,
        'month': month,
      });

      if (splitResult.isSuccess() && splitResult.getOrNull() != null) {
        paymentSplits.insert(0, PaymentSplit.fromJson(splitResult.getOrNull()!));
      } else {
        throw splitResult.getExceptionOrNull() ?? Exception('Failed to create payment split');
      }
      Get.snackbar('Success', 'Payment split created and sent to roommate');
      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to create split');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> confirmPaymentSplit(String splitId) async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      isProcessing.value = true;
      await _stripeConnectService.confirmPaymentSplit(
        splitId,
        authController.currentUserId.value!,
      );

      await loadPaymentSplits();
      Get.snackbar('Success', 'Payment split confirmed');
      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to confirm split');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> loadPayouts() async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingPayouts.value = true;
      final payoutsResult = await _stripeConnectService.getPayoutsByUser(
        authController.currentUserId.value!,
      );
      
      if (payoutsResult.isSuccess() && payoutsResult.getOrNull() != null) {
        payouts.value = payoutsResult.getOrNull()!.map((payout) => Payout.fromJson(payout)).toList();
      } else {
        throw payoutsResult.getExceptionOrNull() ?? Exception('Failed to load payouts');
      }

      final statsResult = await _stripeConnectService.getUserPayoutStats(
        authController.currentUserId.value!,
      );
      
      if (statsResult.isSuccess()) {
        payoutStats.value = statsResult.getOrNull() ?? {};
      } else {
        throw statsResult.getExceptionOrNull() ?? Exception('Failed to load payout stats');
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingPayouts.value = false;
    }
  }

  Future<void> initiateManualPayout({
    required double amount,
    required String currency,
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      isProcessing.value = true;

      // Get eligible payments for payout
      final eligiblePayments = payments
          .where((p) =>
              p.status == 'completed' &&
              p.toUserId == authController.currentUserId.value)
          .toList();

      if (eligiblePayments.isEmpty) {
        throw Exception('No eligible payments for payout');
      }

      final payoutResult = await _stripeConnectService.createPayout(
        userId: authController.currentUserId.value!,
        amount: amount,
        currency: currency,
        paymentIds: eligiblePayments.map((p) => p.paymentId).toList(),
      );
      
      if (payoutResult.isSuccess() && payoutResult.getOrNull() != null) {
        payouts.insert(0, Payout.fromJson(payoutResult.getOrNull()!));
      } else {
        throw payoutResult.getExceptionOrNull() ?? Exception('Failed to create payout');
      }
      Get.snackbar(
        'Payout Initiated',
        'Your payout will arrive in 1-2 business days',
      );
      await loadPayouts();
      error.value = null;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', error.value ?? 'Failed to initiate payout');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> fileDispute({
    required String paymentId,
    required String reason,
    String? description,
  }) async {
    try {
      isProcessing.value = true;
      await _paymentService.fileDispute(paymentId, reason);
      Get.snackbar('Dispute Filed', 'We will review your dispute');
      loadPaymentHistory();
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isProcessing.value = false;
    }
  }

  String getPaymentStatusDisplay(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'disputed':
        return 'Disputed';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}
