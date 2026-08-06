class PaymentService {
  static final PaymentService _instance = PaymentService._();
  factory PaymentService() => _instance;
  PaymentService._();

  Future<bool> processCashPayment(double amount) async {
    return true;
  }

  Future<bool> processWalletPayment(String walletId, double amount) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> processBankTransfer(String accountNumber, double amount) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
}
