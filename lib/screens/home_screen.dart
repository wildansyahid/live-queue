import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_queue_provider.dart';
import 'queue_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = false;
  
  // Controller untuk menangkap input nama dan nomor telepon warga
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // FUNGSI 1: Memunculkan Dialog Formulir Pengisian Data Diri
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
              // Validasi agar form tidak boleh kosong
              if (_namaController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan No Telepon wajib diisi!'), backgroundColor: Colors.red)
                );
                return;
              }
              Navigator.pop(ctx); // Tutup dialog form
              
              // Lanjut proses ambil antrean dengan data yang sudah diisi
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

  // FUNGSI 2: Mengirimkan data (Service ID, Nama, No Telp) ke API Backend
  Future<void> _prosesAmbilAntrean(String nama, String phone) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiProvider);
      
      // FIX: Memanggil API dengan 3 Parameter (ID Layanan, Nama, No Telepon)
      final response = await api.ambilTiket(1, nama, phone); 
      
      if (!mounted) return;
      
      // Jika berhasil, arahkan ke layar Tracker Warga (QueueScreen)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QueueScreen(myTicket: response['data']['ticket_number']),
        ),
      );
      
      // Bersihkan formulir untuk pengunjung berikutnya
      _namaController.clear();
      _phoneController.clear();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
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
              
              // Menampilkan jumlah sisa antrean secara real-time
              Text(
                'Antrean saat ini: ${queueState.jumlahMenunggu} Orang menunggu', 
                style: const TextStyle(fontSize: 16, color: Colors.grey)
              ),
              const SizedBox(height: 48),
              
              // Tombol Ambil Antrean
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _tampilkanFormAntrean, // Menampilkan form saat diklik
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary, 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'AMBIL ANTREAN SEKARANG', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}