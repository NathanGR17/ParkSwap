class HistoryService {
  Future<String> getUserHistory() async {
    return '''
- 20 mayo 2025: Plaza Comercial A, 10:00 - 12:00
- 18 mayo 2025: Calle Central 100, 09:30 - 11:30
- 15 mayo 2025: Estación Oeste, 14:00 - 15:30
''';
  }
}
