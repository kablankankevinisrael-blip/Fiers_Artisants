import 'dart:html' as html;

String? readWebLocalStorage(String key) => html.window.localStorage[key];

Future<void> writeWebLocalStorage(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> clearWebLocalStorage() async {
  html.window.localStorage.clear();
}
