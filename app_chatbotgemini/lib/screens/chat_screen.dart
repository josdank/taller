import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_state.dart';
import '../models/message.dart';
import '../services/tts_service.dart';
  
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
 
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
 
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Ejercicio 4: Servicio TTS
  final TTSService _ttsService = TTSService();
  String? _currentSpeakingMessageText;

  @override
  void initState() {
    super.initState();
    // Inicializar TTS
    _ttsService.initialize();
  }
 
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.dispose();
    super.dispose();
  }
 
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Ejercicio 4: Método para hablar/detener
  void _toggleSpeak(String text) {
    setState(() {
      if (_currentSpeakingMessageText == text) {
        // Detener si ya está hablando este mensaje
        _ttsService.stop();
        _currentSpeakingMessageText = null;
      } else {
        // Hablar este mensaje
        _ttsService.stop(); 
        _ttsService.speak(text);
        _currentSpeakingMessageText = text;
        
        // Limpiar el estado cuando termine
        Future.delayed(const Duration(seconds: 1), () {
          _ttsService.isSpeaking().then((speaking) {
            if (!speaking && mounted) {
              setState(() {
                _currentSpeakingMessageText = null;
              });
            }
          });
        });
      }
    });
  }
 
  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(text);
      _controller.clear();
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat con Gemini AI'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _ttsService.stop();
              setState(() => _currentSpeakingMessageText = null);
              context.read<ChatCubit>().clearChat();
            },
            tooltip: 'Limpiar chat',
          ),
        ],
      ),
      
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                final messages = switch (state) {
                  ChatInitial() => <Message>[],
                  ChatLoading(messages: var m) => m,
                  ChatLoaded(messages: var m) => m,
                  ChatError(messages: var m) => m,
                };
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '¡Hola! Soy tu asistente de IA.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Escribe un mensaje para comenzar.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
 
                _scrollToBottom();
 
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (state is ChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (state is ChatLoading && index == messages.length) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(
                      message: messages[index],
                      onSpeak: _toggleSpeak,
                      isSpeaking: _currentSpeakingMessageText == messages[index].text,
                    );
                  },
                );
              },
            ),
          ),
          
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatError) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${state.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      final isLoading = state is ChatLoading;
                      return FloatingActionButton(
                        onPressed: isLoading ? null : _sendMessage,
                        mini: true,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
class _MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String) onSpeak;
  final bool isSpeaking;
  
  const _MessageBubble({
    required this.message,
    required this.onSpeak,
    required this.isSpeaking,
  });
 
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    // Ejercicio 2: Formatear timestamp
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.deepPurple),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isUser
                          ? Text(
                              message.text,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            )
                          : MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: Colors.black87),
                                h1: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                                h2: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
                                h3: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                                code: TextStyle(
                                  backgroundColor: Colors.grey.shade300,
                                  fontFamily: 'monospace',
                                ),
                                strong: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                      // Ejercicio 4: Botón TTS solo para mensajes de IA
                      if (!isUser) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => onSpeak(message.text),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpeaking ? Icons.volume_up : Icons.volume_off,
                                size: 16,
                                color: isSpeaking ? Colors.deepPurple : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSpeaking ? 'Detener' : 'Escuchar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSpeaking ? Colors.deepPurple : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Ejercicio 2: Mostrar timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
 
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            radius: 16,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.deepPurple),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Escribiendo', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}