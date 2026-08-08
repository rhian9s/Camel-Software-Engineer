class UssdService {
  static Future<String> sendUssd(String code, int slot) async {
    return "USSD: \$code SIM \${slot+1}";
  }
}
