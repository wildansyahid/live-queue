import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/live_queue_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool isLoketActive = true;

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueStateProvider);
    final theme = Theme.of(context).colorScheme;
    final isQueueEmpty = queueState.jumlahMenunggu == 0;
    final isMelayani = queueState.antreanDipanggil != "-";
    
    final api = ref.read(apiProvider);
    final ws = ref.read(wsProvider).socket;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Row(
          children: [
            // ==========================================
            // PANEL KIRI: Kendali Panggilan
            // ==========================================
            Expanded(
              flex: 35,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF1E3A8A),
                          child: Text('WS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Wildan Syahid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Loket 1 - CS', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.red),
                          label: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Reset Antrean Hari Ini?'),
                                content: const Text('Semua antrean yang menunggu akan dihapus dan diulang dari 0.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () {
                                      ws.emit('reset_antrean', {'service_id': 1}); 
                                      Navigator.pop(ctx);
                                    }, 
                                    child: const Text('Ya, Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                  ),
                                ]
                              )
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: isLoketActive,
                          activeColor: Colors.green,
                          onChanged: (val) => setState(() => isLoketActive = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // KOTAK LIVE STATUS (Kini Ada Nama & No Telp)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isLoketActive ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isLoketActive ? const Color(0xFFBFDBFE) : Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: isMelayani ? Colors.red : Colors.grey, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              const Text('LIVE STATUS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                queueState.antreanDipanggil == '-' ? 'KOSONG' : queueState.antreanDipanggil,
                                key: ValueKey<String>(queueState.antreanDipanggil),
                                style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: theme.primary, height: 1.1),
                              ),
                            ),
                          ),
                          
                          // FIX: DATA NAMA & NO TELEPON MUNCUL DI SINI
                          if (isMelayani) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: [
                                  Text(queueState.namaPelanggan, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(queueState.teleponPelanggan, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // GRID TOMBOL AKSI
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        // FIX: Tombol Selesai berubah warna menjadi HIJAU
                        _buildActionButton(
                          'Selesai', Icons.check_circle, Colors.white, Colors.green, 
                          isMelayani ? () => ws.emit('selesaikan_antrean', {'service_id': 1}) : null
                        ),
                        _buildActionButton(
                          'Lewati', Icons.skip_next, Colors.orange.shade700, Colors.orange.shade100, 
                          isMelayani ? () => ws.emit('lewati_antrean', {'service_id': 1}) : null
                        ),
                        _buildActionButton(
                          'Panggil Ulang', Icons.replay, Colors.blue.shade700, Colors.blue.shade100, 
                          isMelayani ? () => ws.emit('panggil_ulang', {'service_id': 1}) : null
                        ),
                        _buildActionButton(
                          'Berikutnya', Icons.campaign, Colors.grey.shade800, Colors.grey.shade200, 
                          (!isQueueEmpty && isLoketActive) ? () async {
                            try {
                              await api.panggilBerikutnya(1);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                              }
                            }
                          } : null
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Daftar Tunggu Berikutnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: queueState.jumlahMenunggu,
                        itemBuilder: (context, index) {
                          String prefix = queueState.antreanDipanggil.startsWith('A') ? 'A' : 'A';
                          int currentNum = int.tryParse(queueState.antreanDipanggil.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: Color(0xFFF3F4F6), child: Icon(Icons.person, color: Colors.grey)),
                            title: Text('$prefix-${(currentNum + index + 1).toString().padLeft(3, '0')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: const Text('Menunggu', style: TextStyle(color: Colors.orange, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // PANEL KANAN: Analitik & Metrik
            // ==========================================
            Expanded(
              flex: 65,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Antrean', '${queueState.totalAntrean}', Icons.people, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<DateTime>(
                            stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                            builder: (context, snapshot) {
                              final time = snapshot.data ?? DateTime.now();
                              final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
                              return _buildMetricCard('Waktu Saat Ini', timeStr, Icons.access_time, Colors.purple);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Sisa Menunggu', '${queueState.jumlahMenunggu}', Icons.hourglass_empty, Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Grafik Jam Sibuk (Peak Hours)',
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false),
                                  lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 10), FlSpot(3, 7), FlSpot(4, 12), FlSpot(5, 4)], isCurved: true, color: Colors.blue, barWidth: 4, isStrokeCapRound: true, belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)))],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildBentoCard(
                              title: 'Kinerja Loket',
                              child: BarChart(
                                BarChartData(
                                  gridData: FlGridData(show: false), titlesData: FlTitlesData(show: false), borderData: FlBorderData(show: false),
                                  barGroups: [
                                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.green, width: 16)]),
                                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.blue, width: 16)]),
                                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 4, color: Colors.orange, width: 16)]),
                                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 5, color: Colors.purple, width: 16)]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: _buildBentoCard(
                        title: 'Aktivitas Loket Real-Time',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text('Loket')), DataColumn(label: Text('Status')), DataColumn(label: Text('Sedang Dilayani')), DataColumn(label: Text('Antrean Terlewat')),
                              ],
                              rows: [
                                DataRow(cells: [
                                  const DataCell(Text('Loket 1 - CS', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Row(children: const [Icon(Icons.circle, color: Colors.green, size: 12), SizedBox(width: 8), Text('Aktif')])),
                                  DataCell(Text(queueState.antreanDipanggil, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  const DataCell(Text('0')),
                                ]),
                                DataRow(cells: [
                                  const DataCell(Text('Loket 2 - CS', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Row(children: const [Icon(Icons.circle, color: Colors.grey, size: 12), SizedBox(width: 8), Text('Istirahat')])),
                                  const DataCell(Text('-')),
                                  const DataCell(Text('2')),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color textColor, Color bgColor, VoidCallback? onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: onPressed == null ? Colors.grey : textColor),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: TextStyle(color: onPressed == null ? Colors.grey : textColor, fontWeight: FontWeight.bold))
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: Colors.grey.shade200,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
              children: [FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14))), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16), Expanded(child: child)]),
    );
  }
}