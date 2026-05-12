import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_application/models/account_model.dart';

class ApiService {
  static const String _baseUrl =
      'https://my-json-server.typicode.com/vzyhug/data-accounts';

  Future<List<Account>> fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/accounts'));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        List<Account> accounts = jsonList
            .map((json) => Account.fromJson(json))
            .toList();
        return accounts;
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching accounts: $e');
    }
  }
}
