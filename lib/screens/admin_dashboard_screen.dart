import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/auth_service.dart';
import '../services/admin_office_service.dart';
import 'login_screen.dart';
import 'admin_qr_view_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String _error = "";
  List<dynamic> _offices = [];

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _radius = TextEditingController(text: "100");

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    setState(() {
      _loading = true;
      _error = "";
    });
    try {
      final data = await AdminOfficeService.listOffices();
      if (!mounted) return;
      setState(() {
        _offices = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
    }
  }

  Future<void> _createOffice() async {
    final name = _name.text.trim();
    final address = _address.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final radius = int.tryParse(_radius.text.trim());

    if (name.isEmpty || lat == null || lng == null || radius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name, Lat, Lng, Radius required")),
      );
      return;
    }

    try {
      await AdminOfficeService.createOffice(
        name: name,
        address: address,
        lat: lat,
        lng: lng,
        radiusM: radius,
      );

      _name.clear();
      _address.clear();
      _lat.clear();
      _lng.clear();
      _radius.text = "100";

      if (!mounted) return;
      Navigator.pop(context);
      _loadOffices();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Office created")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Office"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _name, decoration: const InputDecoration(labelText: "Office Name")),
              TextField(controller: _address, decoration: const InputDecoration(labelText: "Address (optional)")),
              TextField(controller: _lat, decoration: const InputDecoration(labelText: "Latitude"), keyboardType: TextInputType.number),
              TextField(controller: _lng, decoration: const InputDecoration(labelText: "Longitude"), keyboardType: TextInputType.number),
              TextField(controller: _radius, decoration: const InputDecoration(labelText: "Allowed Radius (meters)"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: _createOffice, child: const Text("Create")),
        ],
      ),
    );
  }

  Future<void> _generateQr(Map<String, dynamic> office) async {
    final id = office["id"] as int;
    try {
      final qrData = await AdminOfficeService.generateQr(id);
      final token = qrData["qr_token"].toString();
      final officeName = (qrData["office_name"] ?? office["name"] ?? "Office").toString();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminQrViewScreen(officeName: officeName, qrToken: token),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> office) async {
    final id = office["id"] as int;
    final current = office["is_active"] == true;
    try {
      await AdminOfficeService.updateOffice(id, {"is_active": !current});
      _loadOffices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _radius.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Office Setup"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOffices),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenService.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : _offices.isEmpty
          ? const Center(child: Text("No offices yet. Click + to create."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _offices.length,
        itemBuilder: (_, i) {
          final office = _offices[i] as Map<String, dynamic>;
          final active = office["is_active"] == true;

          return Card(
            child: ListTile(
              title: Text(office["name"]?.toString() ?? "Office"),
              subtitle: Text(
                "Lat: ${office["latitude"]}  Lng: ${office["longitude"]}\nRadius: ${office["allowed_radius_m"]}m • ${active ? "Active" : "Inactive"}",
              ),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: "Generate QR",
                    icon: const Icon(Icons.qr_code),
                    onPressed: active ? () => _generateQr(office) : null,
                  ),
                  IconButton(
                    tooltip: active ? "Deactivate" : "Activate",
                    icon: Icon(active ? Icons.toggle_on : Icons.toggle_off),
                    onPressed: () => _toggleActive(office),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
