import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'cubits/chat_cubit.dart';
import 'services/gemini_service.dart';
import 'screens/chat_screen.dart';

// Ejercicio 1: Cargar variables de entorno antes de iniciar la app
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar el archivo .env
  try {
    await dotenv.load(fileName: ".env");
    print(' Archivo .env cargado correctamente');
  } catch (e) {
    print(' Error cargando .env: $e');
    print(' Asegúrate de crear el archivo .env con tu GEMINI_API_KEY');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(GeminiService()),
      child: MaterialApp(
        title: 'Gemini Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, 
            brightness: Brightness.light
          ),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}

// NOTA: Las clases MyHomePage y _MyHomePageState son del template original
// de Flutter y no se usan en este proyecto de chatbot.
// Se pueden eliminar si lo deseas, pero no afectan el funcionamiento.

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}