import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/live_queue_provider.dart';

class DisplayScreen extends ConsumerWidget {
  const DisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueStateProvider);
    final theme = Theme.of(context).colorScheme;

    // FIX: Mengganti (---) menjadi teks 'BELUM ADA' agar rapi saat loket menganggur
    final isKosong = queueState.antreanDipanggil == '-';
    final displayNomor = isKosong ? 'BELUM ADA' : queueState.antreanDipanggil;

    return Scaffold(
      backgroundColor: theme.background,
      body: Row(
        children: [
          // PANEL KIRI - Nomor Sedang Dipanggil
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('SEDANG DIPANGGIL', 
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 2)
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tampilan Nomor Antrean
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        displayNomor,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: isKosong ? Colors.grey.shade300 : theme.primary
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
                      decoration: BoxDecoration(
                        color: isKosong ? Colors.grey : Colors.green, 
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: isKosong ? [] : [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: const Text('LOKET 1', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // PANEL KANAN - Informasi & Antrean Menunggu
          Expanded(
            flex: 3,
            child: Container(
              color: theme.primary,
              padding: const EdgeInsets.all(32), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown, 
                    child: Text('Live Queue', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white))
                  ),
                  const FittedBox(
                    fit: BoxFit.scaleDown, 
                    child: Text('Pusat Pelayanan Warga', style: TextStyle(fontSize: 24, color: Colors.white70))
                  ),
                  
                  const Spacer(),
                  
                  // Card Total Menunggu
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown, 
                          child: Text('Total Menunggu', style: TextStyle(fontSize: 28, color: Colors.white70))
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${queueState.jumlahMenunggu} Orang', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Notifikasi Real-Time
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.secondary, 
                      borderRadius: BorderRadius.circular(24)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            queueState.notifikasiTerbaru,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}