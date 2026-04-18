import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

import '../http/senior_http_client.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends SeniorScreenState<UsersScreen> {
  final _client = SeniorHttpClient();
  List<dynamic>? _users;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _fetchUsers,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _users?.length ?? 0,
      itemBuilder: (context, index) {
        final user = _users![index] as Map<String, dynamic>;
        final fullName = '${user['firstName']} ${user['lastName']}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(fullName),
            subtitle: Text(user['email'] as String),
            trailing: Text(
              user['company']?['name'] as String? ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _client.get(
        Uri.parse('https://dummyjson.com/users?limit=10'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _users = body['users'] as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'HTTP ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e, s) {
      await SeniorObservability.logError(e, s);
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
}
