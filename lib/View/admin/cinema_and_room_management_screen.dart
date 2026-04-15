import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/Room.dart';
import '../../Model/Ticket.dart';
import '../../Model/Movie.dart';
import '../../Model/Cinema.dart';
import '../../Model/Province.dart';
import '../../Services/ticket_service.dart';
import '../../Services/movie_service.dart';
import '../../Services/cinema_service.dart';
import '../../Services/room_service.dart';
import '../../Services/province_service.dart';

class CinemaAndRoomManagementScreen extends StatefulWidget {
  const CinemaAndRoomManagementScreen({Key? key}) : super(key: key);

  @override
  _CinemaAndRoomManagementScreenState createState() =>
      _CinemaAndRoomManagementScreenState();
}

class _CinemaAndRoomManagementScreenState
    extends State<CinemaAndRoomManagementScreen> {
  final CinemaService _cinemaService = CinemaService();
  final RoomService _roomService = RoomService();
  final ProvinceService _provinceService = ProvinceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";
  String? selectedProvinceId;
  String? selectedCinemaId;
  bool isLoading = true;
  List<Cinema> cinemas = [];
  List<Room> rooms = [];
  List<Province> provinces = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load provinces
      final provinceList = await _provinceService.getAllProvinces().first;

      // Load cinemas
      final cinemaList = await _firestore
          .collection('cinemas')
          .get()
          .then((snapshot) => snapshot.docs
              .map((doc) => Cinema(
                    id: doc.id,
                    name: doc['name'] ?? '',
                    provinceId: doc['provinceId'] ?? '',
                    address: doc['address'] ?? '',
                  ))
              .toList());

      if (mounted) {
        setState(() {
          provinces = provinceList;
          cinemas = cinemaList;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRoomsByCinema(String cinemaId) async {
    try {
      final roomList = await _roomService.getRoomsByCinema(cinemaId).first;
      if (mounted) {
        setState(() {
          rooms = roomList;
        });
      }
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildSearchField(),
                _buildProvinceSelector(),
                if (selectedProvinceId != null) _buildCinemaSelector(),
                if (selectedCinemaId != null) _buildRoomList(),
                if (selectedCinemaId == null) _buildCinemaList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedCinemaId != null
            ? () => _showAddRoomDialog()
            : () => _showAddCinemaDialog(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          selectedCinemaId != null ? 'Thêm phòng' : 'Thêm rạp',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: "Tìm kiếm...",
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildProvinceSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedProvinceId,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
        dropdownColor: const Color(0xff252429),
        style: const TextStyle(color: Colors.white),
        hint: const Text('Chọn Tỉnh/Thành phố',
            style: TextStyle(color: Colors.white70)),
        items: provinces.map((province) {
          return DropdownMenuItem<String>(
            value: province.id,
            child: Text(province.name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedProvinceId = newValue;
            selectedCinemaId = null;
            rooms = [];
          });
        },
      ),
    );
  }

  Widget _buildCinemaSelector() {
    final filteredCinemas = cinemas
        .where((cinema) => cinema.provinceId == selectedProvinceId)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButtonFormField<String>(
        value: selectedCinemaId,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black12,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
        ),
        dropdownColor: const Color(0xff252429),
        style: const TextStyle(color: Colors.white),
        hint: const Text('Chọn Rạp', style: TextStyle(color: Colors.white70)),
        items: filteredCinemas.map((cinema) {
          return DropdownMenuItem<String>(
            value: cinema.id,
            child: Text(cinema.name),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedCinemaId = newValue;
            if (newValue != null) {
              _loadRoomsByCinema(newValue);
            }
          });
        },
      ),
    );
  }

  Widget _buildCinemaList() {
    final filteredCinemas = cinemas.where((cinema) {
      bool matchesProvince =
          selectedProvinceId == null || cinema.provinceId == selectedProvinceId;
      bool matchesSearch = searchQuery.isEmpty ||
          cinema.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesProvince && matchesSearch;
    }).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCinemas.length,
        itemBuilder: (context, index) {
          final cinema = filteredCinemas[index];
          return _buildCinemaCard(cinema);
        },
      ),
    );
  }

  Widget _buildRoomList() {
    final filteredRooms = rooms.where((room) {
      return searchQuery.isEmpty ||
          room.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          final room = filteredRooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildCinemaCard(Cinema cinema) {
    return Card(
      color: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.local_movies, color: Colors.orange),
        title: Text(
          cinema.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          cinema.address,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditCinemaDialog(cinema),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteCinemaDialog(cinema),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            selectedCinemaId = cinema.id;
            _loadRoomsByCinema(cinema.id);
          });
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Card(
      color: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.meeting_room, color: Colors.orange),
        title: Text(
          room.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Số ghế: ${room.rows * room.cols}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditRoomDialog(room),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteRoomDialog(room),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCinemaDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Thêm Rạp Mới',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tên rạp',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedProvinceId,
              decoration: const InputDecoration(
                labelText: 'Tỉnh/Thành phố',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
              dropdownColor: const Color(0xff252429),
              style: const TextStyle(color: Colors.white),
              items: provinces.map((province) {
                return DropdownMenuItem<String>(
                  value: province.id,
                  child: Text(province.name),
                );
              }).toList(),
              onChanged: (String? newValue) {
                selectedProvinceId = newValue;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  selectedProvinceId != null) {
                try {
                  final cinema = Cinema(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    provinceId: selectedProvinceId!,
                    address: addressController.text,
                  );
                  await _cinemaService.createCinema(cinema);
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm rạp thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    final nameController = TextEditingController();
    final rowsController = TextEditingController();
    final colsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Thêm Phòng Chiếu',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tên phòng',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rowsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số hàng ghế',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số cột ghế',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  rowsController.text.isNotEmpty &&
                  colsController.text.isNotEmpty &&
                  selectedCinemaId != null) {
                try {
                  final rows = int.parse(rowsController.text);
                  final cols = int.parse(colsController.text);
                  final room = Room(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cinemaId: selectedCinemaId!,
                    name: nameController.text,
                    rows: rows,
                    cols: cols,
                    seatLayout: [],
                  );
                  await _roomService.createRoom(room);
                  Navigator.pop(context);
                  _loadRoomsByCinema(selectedCinemaId!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm phòng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditCinemaDialog(Cinema cinema) {
    final nameController = TextEditingController(text: cinema.name);
    final addressController = TextEditingController(text: cinema.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Chỉnh Sửa Rạp',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tên rạp',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                try {
                  await _cinemaService.updateCinema(cinema.id, {
                    'name': nameController.text,
                    'address': addressController.text,
                  });
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật rạp thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    final nameController = TextEditingController(text: room.name);
    final rowsController = TextEditingController(text: room.rows.toString());
    final colsController = TextEditingController(text: room.cols.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Chỉnh Sửa Phòng Chiếu',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tên phòng',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rowsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số hàng ghế',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số cột ghế',
                labelStyle: TextStyle(color: Colors.orange),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  rowsController.text.isNotEmpty &&
                  colsController.text.isNotEmpty) {
                try {
                  final rows = int.parse(rowsController.text);
                  final cols = int.parse(colsController.text);
                  await _roomService.updateRoom(room.id, {
                    'name': nameController.text,
                    'rows': rows,
                    'cols': cols,
                  });
                  Navigator.pop(context);
                  _loadRoomsByCinema(room.cinemaId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật phòng thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCinemaDialog(Cinema cinema) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Xóa Rạp',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa rạp "${cinema.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _cinemaService.deleteCinema(cinema.id);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa rạp thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Xóa Phòng Chiếu',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa phòng "${room.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _roomService.deleteRoom(room.id);
                Navigator.pop(context);
                _loadRoomsByCinema(room.cinemaId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa phòng thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
