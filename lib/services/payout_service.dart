import 'package:dio/dio.dart';
import 'api_config.dart';

class CreatorWithdrawal {
  final String id;
  final double amount;
  final String status; // pending, approved, rejected, paid
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;
  final String? adminNotes;
  final String? paymentReference;
  final String requestedAt;

  const CreatorWithdrawal({
    required this.id,
    required this.amount,
    required this.status,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.adminNotes,
    this.paymentReference,
    required this.requestedAt,
  });

  factory CreatorWithdrawal.fromJson(Map<String, dynamic> json) {
    return CreatorWithdrawal(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      bankAccountName: json['bankAccountName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankIfsc: json['bankIfsc'] as String?,
      upiId: json['upiId'] as String?,
      adminNotes: json['adminNotes'] as String?,
      paymentReference: json['paymentReference'] as String?,
      requestedAt: json['requestedAt'] as String? ?? '',
    );
  }
}

class CreatorWalletBalance {
  final double availableBalance;
  final double totalEarned;
  final double totalWithdrawn;

  const CreatorWalletBalance({
    required this.availableBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  factory CreatorWalletBalance.fromJson(Map<String, dynamic> json) {
    return CreatorWalletBalance(
      availableBalance: (json['availableBalance'] as num? ?? 0).toDouble(),
      totalEarned: (json['totalEarned'] as num? ?? 0).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] as num? ?? 0).toDouble(),
    );
  }
}

class PayoutService {
  final Dio _dio;

  PayoutService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Map<String, String> _authHeaders(String accessToken) => {
        'Authorization': 'Bearer $accessToken',
      };

  /// GET /api/withdrawals/balance
  Future<CreatorWalletBalance> fetchBalance({required String accessToken}) async {
    final response = await _dio.get(
      '/api/withdrawals/balance',
      options: Options(headers: _authHeaders(accessToken)),
    );
    return CreatorWalletBalance.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/withdrawals/my
  Future<List<CreatorWithdrawal>> fetchWithdrawals({required String accessToken}) async {
    final response = await _dio.get(
      '/api/withdrawals/my',
      options: Options(headers: _authHeaders(accessToken)),
    );
    final list = response.data as List<dynamic>;
    return list.map((item) => CreatorWithdrawal.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// POST /api/withdrawals/request
  Future<CreatorWithdrawal> requestWithdrawal({
    required String accessToken,
    required double amount,
    required String paymentMethod,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankIfsc,
    String? upiId,
  }) async {
    final response = await _dio.post(
      '/api/withdrawals/request',
      data: {
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (paymentMethod == 'bank') 'bankAccountName': bankAccountName,
        if (paymentMethod == 'bank') 'bankAccountNumber': bankAccountNumber,
        if (paymentMethod == 'bank') 'bankIfsc': bankIfsc,
        if (paymentMethod == 'upi') 'upiId': upiId,
      },
      options: Options(headers: _authHeaders(accessToken)),
    );
    return CreatorWithdrawal.fromJson(response.data as Map<String, dynamic>);
  }
}
