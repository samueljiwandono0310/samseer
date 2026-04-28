import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:samseer/samseer.dart';

late final Samseer samseer;
late final Dio dio;
late final http.Client httpClient;

void main() {
  samseer = Samseer(
    configuration: const SamseerConfiguration(
      showInspectorOnShake: true,
    ),
  );

  dio = Dio()..interceptors.add(samseer.dioInterceptor);
  httpClient = samseer.httpClient();
  HttpOverrides.global = samseer.httpOverrides;

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'samseer example',
      navigatorKey: samseer.navigatorKey,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      builder: (context, child) => samseer.overlay(child: child!),
      home: const Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('samseer example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: samseer.showInspector,
            tooltip: 'Open inspector',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Dio', children: [
            _Tile(
              label: 'GET /posts',
              onTap: () => dio.get('https://jsonplaceholder.typicode.com/posts'),
            ),
            _Tile(
              label: 'GET /posts/1',
              onTap: () => dio.get('https://jsonplaceholder.typicode.com/posts/1'),
            ),
            _Tile(
              label: 'POST /posts',
              onTap: () => dio.post(
                'https://jsonplaceholder.typicode.com/posts',
                data: {'title': 'hello', 'body': 'samseer', 'userId': 1},
              ),
            ),
            _Tile(
              label: 'GET 404',
              onTap: () => dio
                  .get('https://jsonplaceholder.typicode.com/notfound')
                  .catchError(
                    (_) => Response(requestOptions: RequestOptions(path: '')),
                  ),
            ),
          ]),
          _Section(title: 'http package', children: [
            _Tile(
              label: 'GET /todos/1',
              onTap: () => httpClient
                  .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1')),
            ),
            _Tile(
              label: 'POST /posts',
              onTap: () => httpClient.post(
                Uri.parse('https://jsonplaceholder.typicode.com/posts'),
                body: '{"title":"x","body":"y","userId":1}',
                headers: {'content-type': 'application/json'},
              ),
            ),
          ]),
          _Section(title: 'dart:io HttpClient', children: [
            _Tile(
              label: 'GET /users/1',
              onTap: () async {
                final c = HttpClient();
                final req = await c.getUrl(
                  Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
                );
                final res = await req.close();
                await res.drain<void>();
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.send),
        onTap: onTap,
      ),
    );
  }
}
