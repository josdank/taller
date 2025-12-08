import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;
  final List<Message> _messages = [];

  ChatCubit(this._geminiService) : super(ChatInitial());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    _messages.add(Message(text: text, isUser: true));
    
    emit(ChatLoading(List.from(_messages)));

    try {
      // Ejercicio 3: Pasar historial de conversación
      final response = await _geminiService.sendMessage(
        text, 
        conversationHistory: _messages.where((m) => m.text != text).toList()
      );

      _messages.add(Message(text: response, isUser: false));

      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      emit(ChatError(e.toString(), List.from(_messages)));  
    } 
  }

  void clearChat() {
    _messages.clear();
    emit(ChatInitial());
  }
}