import '../services/api_service.dart';

class SmsService {
  final ApiService _apiService = ApiService();

  // Send SMS
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await _apiService.post(
        '/sms/send',
        data: {
          'phone_number': phoneNumber,
          'message': message,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur d\'envoi SMS: ${e.toString()}');
    }
  }

  // Send medication available notification
  Future<bool> sendMedicationAvailableNotification({
    required String phoneNumber,
    required String patientName,
    required String medicamentName,
    required String pharmacyName,
  }) async {
    final message = _buildMedicationAvailableMessage(
      patientName: patientName,
      medicamentName: medicamentName,
      pharmacyName: pharmacyName,
    );

    return await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Build medication available message
  String _buildMedicationAvailableMessage({
    required String patientName,
    required String medicamentName,
    required String pharmacyName,
  }) {
    return '''
Bonjour $patientName,

Votre médicament $medicamentName est maintenant disponible à $pharmacyName.

Vous pouvez venir le récupérer aux heures d'ouverture.

Cordialement,
$pharmacyName
''';
  }

  // Send bulk SMS
  Future<Map<String, bool>> sendBulkSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final results = <String, bool>{};

    for (final phoneNumber in phoneNumbers) {
      try {
        final success = await sendSms(
          phoneNumber: phoneNumber,
          message: message,
        );
        results[phoneNumber] = success;
      } catch (e) {
        results[phoneNumber] = false;
      }
    }

    return results;
  }

  // Send custom notification
  Future<bool> sendCustomNotification({
    required String phoneNumber,
    required String title,
    required String body,
  }) async {
    final message = '''
$title

$body
''';

    return await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Send reminder
  Future<bool> sendReminder({
    required String phoneNumber,
    required String patientName,
    required String medicamentName,
    required int daysWaiting,
  }) async {
    final message = '''
Bonjour $patientName,

Ceci est un rappel concernant votre demande de $medicamentName effectuée il y a $daysWaiting jours.

Nous vous informerons dès que le médicament sera disponible.

Cordialement
''';

    return await sendSms(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // Validate phone number format
  bool validatePhoneNumber(String phoneNumber) {
    // Remove spaces and special characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return false;
    }

    // Check length
    if (cleaned.length < 10 || cleaned.length > 15) {
      return false;
    }

    return true;
  }

  // Get SMS delivery status
  Future<SmsStatus?> getSmsStatus(String smsId) async {
    try {
      final response = await _apiService.get('/sms/status/$smsId');

      if (response.statusCode == 200) {
        return SmsStatus.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get SMS history
  Future<List<SmsHistory>> getSmsHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _apiService.get(
        '/sms/history',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'];
        return data.map((json) => SmsHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get SMS statistics
  Future<SmsStatistics?> getSmsStatistics() async {
    try {
      final response = await _apiService.get('/sms/statistics');

      if (response.statusCode == 200) {
        return SmsStatistics.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// SMS Status Model
class SmsStatus {
  final String id;
  final String status;
  final DateTime? deliveredAt;
  final String? errorMessage;

  SmsStatus({
    required this.id,
    required this.status,
    this.deliveredAt,
    this.errorMessage,
  });

  factory SmsStatus.fromJson(Map<String, dynamic> json) {
    return SmsStatus(
      id: json['id'],
      status: json['status'],
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      errorMessage: json['error_message'],
    );
  }

  bool get isDelivered => status == 'delivered';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
}

// SMS History Model
class SmsHistory {
  final String id;
  final String phoneNumber;
  final String message;
  final String status;
  final DateTime sentAt;

  SmsHistory({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.status,
    required this.sentAt,
  });

  factory SmsHistory.fromJson(Map<String, dynamic> json) {
    return SmsHistory(
      id: json['id'],
      phoneNumber: json['phone_number'],
      message: json['message'],
      status: json['status'],
      sentAt: DateTime.parse(json['sent_at']),
    );
  }
}

// SMS Statistics Model
class SmsStatistics {
  final int totalSent;
  final int delivered;
  final int failed;
  final int pending;

  SmsStatistics({
    required this.totalSent,
    required this.delivered,
    required this.failed,
    required this.pending,
  });

  factory SmsStatistics.fromJson(Map<String, dynamic> json) {
    return SmsStatistics(
      totalSent: json['total_sent'],
      delivered: json['delivered'],
      failed: json['failed'],
      pending: json['pending'],
    );
  }

  double get deliveryRate {
    if (totalSent == 0) return 0;
    return (delivered / totalSent) * 100;
  }
}