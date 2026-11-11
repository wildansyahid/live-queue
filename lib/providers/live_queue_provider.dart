import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

final apiProvider = Provider((ref) => ApiService());
final wsProvider = Provider((ref) => WebSocketService());

class QueueData {
  final String antreanDipanggil;
  final String namaPelanggan;     // DATA BARU
  final String teleponPelanggan;  // DATA BARU
  final int jumlahMenunggu;
  final int totalAntrean;
  final String notifikasiTerbaru;

  QueueData({
    this.antreanDipanggil = "-",
    this.namaPelanggan = "-",
    this.teleponPelanggan = "-",
    this.jumlahMenunggu = 0,
    this.totalAntrean = 0,
    this.notifikasiTerbaru = "Menunggu antrean masuk...",
  });

  QueueData copyWith({
    String? antreanDipanggil, 
    String? namaPelanggan, 
    String? teleponPelanggan, 
    int? jumlahMenunggu, 
    int? totalAntrean, 
    String? notifikasiTerbaru
  }) {
    return QueueData(
      antreanDipanggil: antreanDipanggil ?? this.antreanDipanggil,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      teleponPelanggan: teleponPelanggan ?? this.teleponPelanggan,
      jumlahMenunggu: jumlahMenunggu ?? this.jumlahMenunggu,
      totalAntrean: totalAntrean ?? this.totalAntrean,
      notifikasiTerbaru: notifikasiTerbaru ?? this.notifikasiTerbaru,
    );
  }
}

class QueueNotifier extends StateNotifier<QueueData> {
  final WebSocketService ws;
  final ApiService api;

  QueueNotifier(this.ws, this.api) : super(QueueData()) {
    _initData();
    ws.connect();

    ws.listenToQueueCreated((data) {
      state = state.copyWith(
        jumlahMenunggu: data['waiting_count'] ?? (state.jumlahMenunggu + 1),
        totalAntrean: data['total_count'] ?? (state.totalAntrean + 1),
        notifikasiTerbaru: "Tiket baru masuk: ${data['ticket_number']}",
      );
    });

    ws.listenToQueueCalled((data) {
      state = state.copyWith(
        antreanDipanggil: data['ticket_number'],
        namaPelanggan: data['customer_name'] ?? "-",    // UPDATE NAMA DARI SOCKET
        teleponPelanggan: data['customer_phone'] ?? "-", // UPDATE NO TELP DARI SOCKET
        jumlahMenunggu: data['waiting_count'] ?? (state.jumlahMenunggu > 0 ? state.jumlahMenunggu - 1 : 0),
      );
    });

    ws.socket.on('antrean_selesai', (data) {
      state = state.copyWith(
        antreanDipanggil: data['display_text'] ?? '-',
        namaPelanggan: '-',
        teleponPelanggan: '-',
        jumlahMenunggu: data['jumlah_menunggu'] ?? state.jumlahMenunggu,
      );
    });

    ws.socket.on('antrean_direset', (data) {
      state = state.copyWith(
        antreanDipanggil: data['display_text'] ?? '-',
        namaPelanggan: '-',
        teleponPelanggan: '-',
        jumlahMenunggu: data['jumlah_menunggu'] ?? 0,
        totalAntrean: 0,
        notifikasiTerbaru: "Antrean hari ini telah di-reset ke 0",
      );
    });

    ws.socket.on('queue.recalled', (data) {
      state = state.copyWith(notifikasiTerbaru: "PANGGILAN ULANG: ${data['ticket_number']} diharap menuju loket!");
    });
  }

  Future<void> _initData() async {
    try {
      final status = await api.getQueueStatus(1);
      state = state.copyWith(
        jumlahMenunggu: status['waiting_count'] ?? 0,
        totalAntrean: status['total_count'] ?? 0,
        antreanDipanggil: status['current_ticket'] ?? '-',
        namaPelanggan: status['current_name'] ?? '-',   // LOAD AWAL NAMA
        teleponPelanggan: status['current_phone'] ?? '-', // LOAD AWAL NO TELP
      );
    } catch (e) {
      // Abaikan
    }
  }

  @override
  void dispose() {
    ws.disconnect();
    super.dispose();
  }
}

final queueStateProvider = StateNotifierProvider<QueueNotifier, QueueData>((ref) {
  return QueueNotifier(ref.read(wsProvider), ref.read(apiProvider));
});