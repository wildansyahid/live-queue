import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_queue_provider.dart';
import '../services/api_service.dart';

class QueueScreen extends ConsumerStatefulWidget {
  final String myTicket;
  const QueueScreen({Key? key, required this.myTicket}) : super(key: key);

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  bool _isProcessing = false;

  // ==========================================
  // FUNGSI RESCHEDULE DENGAN KALENDER (DATE PICKER)
  // ==========================================
  Future<void> _handleReschedule() async {
    final now = DateTime.now();

    // 1. Munculkan Kalender
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Tidak bisa pilih hari kemarin
      lastDate: now.add(const Duration(days: 30)), // Maksimal 30 hari ke depan
    );

    if (pickedDate == null) return; // User membatalkan pemilihan kalender

    // 2. Validasi Ketentuan: Jika mendaftar untuk HARI INI, pastikan sudah lewat jam 08:00 pagi
    if (pickedDate.year == now.year && pickedDate.month == now.month && pickedDate.day == now.day) {
      if (now.hour < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maaf, pendaftaran antrean hari ini baru dibuka pukul 08:00 WIB.'), 
            backgroundColor: Colors.red
          )
        );
        return;
      }
    }

    // 3. Format tanggal untuk dikirim ke API
    String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    String displayDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";

    // 4. Munculkan Dialog Konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Reschedule'),
        content: Text('Anda akan membatalkan tiket ini dan mendaftar antrean untuk tanggal $displayDate.\n\nLanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Batal')
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Ya, Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm != true) return;

    // 5. Proses ke API Backend
    setState(() => _isProcessing = true);
    try {
      final api = ref.read(apiProvider);
      
      final newTicket = await api.kelolaTiket(widget.myTicket, 'reschedule', formattedDate);
      
      if (!mounted) return;
      
      if (newTicket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reschedule berhasil! Tiket baru Anda: $newTicket'))
        );
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => QueueScreen(myTicket: newTicket))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ==========================================
  // FUNGSI BATAL ANTREAN
  // ==========================================
  Future<void> _handleBatal() async {
    setState(() => _isProcessing = true);
    try {
      final api = ref.read(apiProvider);
      
      String todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}";
      await api.kelolaTiket(widget.myTicket, 'cancel', todayStr);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrean berhasil dibatalkan'))
      );
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueStateProvider);
    final theme = Theme.of(context).colorScheme;
    
    // ==========================================
    // LOGIKA LISTENER EVENT SERVER
    // ==========================================
    ref.listen<QueueData>(queueStateProvider, (previous, next) {
      if (next.antreanDipanggil == widget.myTicket && previous?.antreanDipanggil != widget.myTicket) {
        showDialog(
          context: context, barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('GILIRAN ANDA!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            content: Text('Nomor antrean Anda (${widget.myTicket}) sedang dipanggil menuju loket.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text('SIAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              )
            ],
          ),
        );
      }
      if (previous?.antreanDipanggil == widget.myTicket && next.antreanDipanggil == '-') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelayanan selesai/dilewati. Terima kasih!'), backgroundColor: Colors.green));
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      if (next.notifikasiTerbaru.contains("di-reset") && (previous?.notifikasiTerbaru != next.notifikasiTerbaru)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Antrean di-reset oleh admin. Silakan ambil ulang.'), backgroundColor: Colors.orange));
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      if (next.notifikasiTerbaru.contains("PANGGILAN ULANG") && (previous?.notifikasiTerbaru != next.notifikasiTerbaru)) {
        if (next.notifikasiTerbaru.contains(widget.myTicket)) {
          showDialog(
            context: context, barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 2)),
              title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('PANGGILAN KEDUA!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
              content: Text('Nomor ${widget.myTicket} segera menuju loket sekarang atau antrean Anda akan dilewati.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('SAYA SEGERA KESANA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                )
              ],
            ),
          );
        }
      }
    });

    final isMyTurn = queueState.antreanDipanggil == widget.myTicket;
    int currentNum = int.tryParse(queueState.antreanDipanggil.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int myNum = int.tryParse(widget.myTicket.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int orangSebelumnya = (myNum - currentNum - 1).clamp(0, 999);
    final isWarning = orangSebelumnya <= 2 && !isMyTurn;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Live Tracker', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black87)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isWarning)
              Container(
                margin: const EdgeInsets.only(bottom: 24), 
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: Colors.yellow.shade400)
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.orange), 
                    SizedBox(width: 12), 
                    Expanded(
                      child: Text('Bersiap-siap! Sisa antrean kurang dari 3 orang.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
                    )
                  ]
                ),
              ),

            Container(
              width: double.infinity, 
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isMyTurn ? Colors.green : Colors.white, 
                borderRadius: BorderRadius.circular(32), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]
              ),
              child: Column(
                children: [
                  Text('Nomor Antrean Utama', style: TextStyle(color: isMyTurn ? Colors.white70 : Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    widget.myTicket, 
                    style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: isMyTurn ? Colors.white : theme.primary, height: 1.0)
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMyTurn ? Colors.white.withOpacity(0.2) : theme.primary.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(100)
                    ),
                    child: Text('Loket 1 - Customer Service', style: TextStyle(fontWeight: FontWeight.bold, color: isMyTurn ? Colors.white : theme.primary)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (!isMyTurn)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24), 
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          const Text('Sisa Menunggu', style: TextStyle(color: Colors.grey)), 
                          const SizedBox(height: 8), 
                          Text('$orangSebelumnya', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: theme.secondary)), 
                          const Text('Orang lagi', style: TextStyle(fontWeight: FontWeight.bold))
                        ]
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24), 
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        children: [
                          const Text('Estimasi Waktu', style: TextStyle(color: Colors.grey)), 
                          const SizedBox(height: 8), 
                          Text('±${orangSebelumnya * 8}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange)), 
                          Text('Hingga ${(orangSebelumnya * 8) + 10} Menit', style: const TextStyle(fontWeight: FontWeight.bold))
                        ]
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            const Align(
              alignment: Alignment.centerLeft, 
              child: Text('Pantau Loket Lain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 16),
            _buildLoketList('Loket 2', '-', 'Istirahat'),
            _buildLoketList('Loket 3', 'B005', 'Aktif'),
            
            const SizedBox(height: 48),
            
            // ==========================================
            // TOMBOL AKSI: BATAL & RESCHEDULE
            // ==========================================
            if (!isMyTurn)
              _isProcessing 
              ? const Center(child: CircularProgressIndicator()) 
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          side: const BorderSide(color: Colors.red), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: _handleBatal,
                        child: const Text('Batal', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary, 
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: _handleReschedule, 
                        child: const Text('Reschedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
          ],
        ),
      ),
    );
  }

  // WIDGET PEMBANTU
  Widget _buildLoketList(String loket, String nomor, String status) {
    bool isAktif = status == 'Aktif';
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.monitor, color: isAktif ? Colors.blue : Colors.grey), 
              const SizedBox(width: 12), 
              Text(loket, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAktif ? Colors.blue.shade50 : Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text(nomor, style: TextStyle(fontWeight: FontWeight.bold, color: isAktif ? Colors.blue : Colors.grey)),
          )
        ],
      ),
    );
  }
}