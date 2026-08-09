import 'package:permission_handler/permission_handler.dart';
import 'package:ussd_advanced/ussd_advanced.dart';

class UssdService {
  static Future<String> checkBalance(int subId, String code) async {
    // Ask permission first
    if (await Permission.phone.request().isGranted) {
      try {
        String? result = await UssdAdvanced.sendUssd(code: code, subscriptionId: subId);
        return result ?? "No response";
      } catch (e) {
        return "Error: $e";
      }
    } else {
      return "Phone permission denied";
    }
  }
}
