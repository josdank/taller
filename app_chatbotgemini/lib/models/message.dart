class Message {
  // el texto del mensaje
  final String text;
  // indica si el mensaje es del usuarrio (true) o de la IA (false)
  final bool isUser;
  // timestamp del mensaje
  final DateTime timestamp;

  //constructor del mensaje

  Message({
    required this.text, 
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}