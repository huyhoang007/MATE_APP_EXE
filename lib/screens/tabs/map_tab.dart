import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/couple_model.dart';

class MapTab extends StatefulWidget {
  final String coupleId;
  final String currentUserId;
  final CoupleData? coupleData;

  const MapTab({
    super.key,
    required this.coupleId,
    required this.currentUserId,
    required this.coupleData,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  LatLng _myLocation = const LatLng(10.8231, 106.6297); // Tọa độ mặc định TP.HCM

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition();
        setState(() {
          _myLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_myLocation, 14.5);

        // Đẩy vị trí lên Firestore - ghi vào user1 (current device)
        await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).update({
          'user1.location': {
            'lat': pos.latitude,
            'lng': pos.longitude,
          },
          'user1.lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy vị trí: $e");
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(p1.latitude, p1.longitude, p2.latitude, p2.longitude) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final u1 = widget.coupleData?.user1 ?? const UserInfo(name: 'Bạn 1');
    final u2 = widget.coupleData?.user2 ?? const UserInfo(name: 'Bạn 2');

    final loc1 = u1.location;
    final loc2 = u2.location;
    final pos1 = loc1.isValid ? LatLng(loc1.lat, loc1.lng) : _myLocation;
    final pos2 = loc2.isValid ? LatLng(loc2.lat, loc2.lng) : LatLng(_myLocation.latitude + 0.02, _myLocation.longitude + 0.02);

    final distanceKm = _calculateDistance(pos1, pos2);

    return Scaffold(
      body: Stack(
        children: [
          // 1. LAYER BẢN ĐỒ THẬT NỀN TOÀN MÀN HÌNH
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: pos1,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
                  maxZoom: 20,
                  userAgentPackageName: 'com.mateapp.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [pos1, pos2],
                      color: const Color(0xFFC084FC),
                      strokeWidth: 3.5,
                      pattern: StrokePattern.dashed(segments: const [8, 8]),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Marker User 1
                    Marker(
                      point: pos1,
                      width: 90,
                      height: 90,
                      child: _buildAvatarMarker(u1.name, u1.stayMinutes ?? 0, Colors.pinkAccent),
                    ),
                    // Marker User 2
                    Marker(
                      point: pos2,
                      width: 90,
                      height: 90,
                      child: _buildAvatarMarker(u2.name, u2.stayMinutes ?? 0, Colors.lightBlue),
                    ),
                    // Badge Khoảng cách giữa 2 người
                    Marker(
                      point: LatLng((pos1.latitude + pos2.latitude) / 2, (pos1.longitude + pos2.longitude) / 2),
                      width: 100,
                      height: 36,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC084FC),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: Text(
                            "${distanceKm.toStringAsFixed(1)} km",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. LAYER HEADER ĐẾM NGÀY NỔI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(icon: const Icon(Icons.settings, color: Colors.black87), onPressed: () {}),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Bên nhau ${widget.coupleData?.daysLoved ?? 2392} bầu trời 💕",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black87), onPressed: () {}),
                  ),
                ],
              ),
            ),
          ),

          // 3. NÚT ĐỊNH VỊ GPS NỔI GÓC PHẢI
          Positioned(
            right: 16,
            bottom: 240,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () => _mapController.move(_myLocation, 15.0),
              child: const Icon(Icons.my_location, color: Colors.pinkAccent),
            ),
          ),

          // 4. BẢNG ĐIỀU KHIỂN TRƯỢT TỪ ĐÁY (BOTTOM SHEET)
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.18,
            maxChildSize: 0.82,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    Center(
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 14),
                    // Banner Premium
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFEEF2), Color(0xFFFDE8EC)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("1 Đăng ký", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("2 Người Dùng 💕", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF18181B),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {},
                            child: const Text("MUA NGAY", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 4 Nút tiện ích
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAction(Icons.location_on, "Vị trí", const Color(0xFFCCFBF1), const Color(0xFF0D9488)),
                        _buildAction(Icons.auto_stories, "Khoảnh khắc", const Color(0xFFFCE7F3), const Color(0xFFE11D48)),
                        _buildAction(Icons.videogame_asset, "Chơi", const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
                        _buildAction(Icons.widgets, "Tiện ích", const Color(0xFFFEF9C3), const Color(0xFFD97706)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Nhiệm vụ hằng ngày
                    const Text("Trái Tim Mỗi Ngày", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ListTile(
                      tileColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: const Icon(Icons.favorite_border, color: Colors.pinkAccent),
                      title: const Text("Thử thách ăn ý", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("+5 điểm thân mật"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: const StadiumBorder()),
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('couples').doc(widget.coupleId).update({
                            'intimacyScore': FieldValue.increment(5),
                            'streakDays': FieldValue.increment(1),
                          });
                        },
                        child: const Text("Làm", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarMarker(String name, int stayMins, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Text("Ở lại ${stayMins}min", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 2),
        CircleAvatar(radius: 24, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildAction(IconData icon, String label, Color bg, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
