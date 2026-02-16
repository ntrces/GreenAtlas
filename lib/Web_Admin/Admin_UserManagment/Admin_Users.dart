import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_user_dialog.dart';
import 'edit_user_dialog.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});
  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final _supabase = Supabase.instance.client;
  int _selectedUserIndex = 0;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        const SizedBox(height: 32),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('profiles').stream(primaryKey: ['id']).order('full_name'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
            
            final rawUsers = snapshot.data ?? [];
            final users = rawUsers.where((u) => (u['full_name'] ?? "").toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

            if (_selectedUserIndex >= users.length) _selectedUserIndex = 0;

            return Column(children: [
              _buildMetricRow(rawUsers),
              const SizedBox(height: 32),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 7, child: _buildUserList(users)),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: users.isEmpty ? const Text("No users found") : _buildUserDetails(users[_selectedUserIndex])),
              ]),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Text("USER MANAGEMENT & ACCESS CONTROL", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    ElevatedButton.icon(
      onPressed: () => showDialog(context: context, builder: (_) => const CreateUserDialog()),
      icon: const Icon(Icons.add), label: const Text("CREATE USER"),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4D6D4D), foregroundColor: Colors.white),
    ),
  ]);

  Widget _buildMetricRow(List users) => Row(children: [
    _card("${users.length}", "TOTAL USERS", Colors.black),
    _card("${users.where((u)=>u['role']=='employee').length}", "EMPLOYEES", Colors.purple),
    _card("${users.where((u)=>u['role']=='user').length}", "USERS", Colors.green),
  ]);

  Widget _buildUserList(List users) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
    child: ListView.builder(
      shrinkWrap: true, itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          selected: _selectedUserIndex == index,
          onTap: () => setState(() => _selectedUserIndex = index),
          title: Text(user['full_name'] ?? "Unknown"),
          subtitle: Text(user['role']?.toString().toUpperCase() ?? ""),
        );
      },
    ),
  );

  Widget _buildUserDetails(Map user) => Container(
    padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(user['full_name'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          // FIX: Explicitly cast Map to avoid argument type error
          onPressed: () => showDialog(context: context, builder: (_) => EditUserDialog(user: Map<String, dynamic>.from(user))), 
          icon: const Icon(Icons.edit_outlined)
        ),
      ]),
      _detailTile("EMAIL", user['email'] ?? "N/A"),
      _detailTile("PHONE", user['phone'] ?? "N/A"),
      _detailTile("ROLE", user['role']?.toString().toUpperCase() ?? "USER"),
    ]),
  );

  Widget _card(String v, String l, Color c) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(l, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold))]))));
  Widget _detailTile(String l, String v) => Padding(padding: const EdgeInsets.only(top: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black26)), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]));
}