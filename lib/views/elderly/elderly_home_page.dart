import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ElderlyHomePage extends StatelessWidget {
  const ElderlyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          child: ListTile(
            leading: Icon(Icons.mail, color: Colors.orange[700], size: 36),
            title: const Text(
              'Group Invitations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('View pending invitations'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/elderly/invitations'),
          ),
        ),
      ),
    );
  }
}
