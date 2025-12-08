import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';

class GeminiService {
  // Ejercicio 1: Obtener API Key desde variables de entorno
  static String get _apikey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Ejercicio 3: Método actualizado con contexto conversacional
  Future<String> sendMessage(String message, {List<Message>? conversationHistory}) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apikey');
      
      // Construir el historial de conversación
      List<Map<String, dynamic>> contents = [];
      
      // Ejercicio 3: Limitar a los últimos 3 mensajes previos
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        // Tomar máximo los últimos 3 mensajes (excluyendo el mensaje actual)
        final int startIndex = conversationHistory.length > 5
            ? conversationHistory.length - 5 
            : 0;
        
        for (int i = startIndex; i < conversationHistory.length; i++) {
          final msg = conversationHistory[i];
          contents.add({
            'role': msg.isUser ? 'user' : 'model',
            'parts': [
              {'text': msg.text}
            ]
          });
        }
      }
      
      // Agregar el mensaje actual
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      });

      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 8192,
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null || data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Respuesta no válida de la API: ${response.body}');
        }

        final candidate = data['candidates'][0];

        if (candidate['content'] == null) {
          throw Exception('Respuesta no válida de la API: ${response.body}');
        }

        final content = candidate['content'];

        String? text;

        if (content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        } else if (content['text'] != null) {
          text = content['text'];
        }

        if (text == null || text.isEmpty) {
          throw Exception('No se encontro texto en la respuesta: ${response.body}');
        }

        return text;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al conectar con la API de Gemini: $e');
    }
  }
}