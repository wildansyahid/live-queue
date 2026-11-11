import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'screens/admin/admin_screen.dart';
import 'screens/display_screen.dart';
import 'screens/queue_screen.dart';
import 'providers/live_queue_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Queue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: kIsWeb ? const WebPortalScreen() : const MobileHomeScreen(),
    );
  }
}

// =========================================================================
// 1. TAMPILAN KHUSUS APLIKASI PENGGUNA (APK MOBILE - WARGA)
// =========================================================================
class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen> {
  bool _isLoading = false;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // FUNGSI 1: Memunculkan Pop-up Formulir
  void _tampilkanFormAntrean() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Pengunjung', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Silakan lengkapi data diri Anda untuk mengambil nomor antrean.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'No. WhatsApp / Telepon',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _namaController.clear();
              _phoneController.clear();
            },
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_namaController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan No Telepon wajib diisi!'), backgroundColor: Colors.red)
                );
                return;
              }
              Navigator.pop(ctx); // Tutup dialog
              _prosesAmbilAntrean(_namaController.text.trim(), _phoneController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ambil Tiket', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // FUNGSI 2: Memproses data ke Backend API
  Future<void> _prosesAmbilAntrean(String nama, String phone) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiProvider);
      
      // Kirim data ke fungsi API yang baru
      final response = await api.ambilTiket(1, nama, phone); 
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QueueScreen(myTicket: response['data']['ticket_number']),
        ),
      );
      
      // Bersihkan form setelah berhasil
      _namaController.clear();
      _phoneController.clear();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final queueState = ref.watch(queueStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Pusat Layanan Warga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 100, color: theme.primary),
              const SizedBox(height: 24),
              const Text('Selamat Datang', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Antrean saat ini: ${queueState.jumlahMenunggu} Orang menunggu', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _tampilkanFormAntrean, // Panggil form saat diklik
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('AMBIL ANTREAN SEKARANG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 2. TAMPILAN KHUSUS WEB / DESKTOP (PORTAL ADMIN & DISPLAY TV)
// =========================================================================
class WebPortalScreen extends StatelessWidget {
  const WebPortalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Portal Sistem Antrean (Web Admin)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWebMenu(
                context,
                title: 'Dasbor Petugas',
                subtitle: 'Panel kendali loket & analitik',
                icon: Icons.admin_panel_settings,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
              ),
              const SizedBox(width: 48),
              _buildWebMenu(
                context,
                title: 'Layar TV Display',
                subtitle: 'Mode monitor ruang tunggu',
                icon: Icons.tv,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisplayScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebMenu(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 80, color: theme.primary),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}