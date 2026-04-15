import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Model/User.dart';
import '../../Services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String searchQuery = '';
  String? selectedProvince;
  String selectedStatus = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  List<User> users = [];
  List<User> filteredUsers = [];
  bool isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    _userService.getAllUsers().listen(
      (userList) {
        setState(() {
          users = userList;
          filteredUsers = List.from(users);
          isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading users: $error');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách người dùng'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  void _searchUser(String query) {
    setState(() {
      filteredUsers = users
          .where((user) =>
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()) ||
              user.phoneNumber.contains(query))
          .toList();
    });
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
      setState(() {
        users.removeWhere((user) => user.id == userId);
        filteredUsers = List.from(users);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Người dùng đã được xóa"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể xóa người dùng. Vui lòng thử lại sau."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editUser(User user) {
    TextEditingController nameController =
        TextEditingController(text: user.fullName);
    TextEditingController phoneController =
        TextEditingController(text: user.phoneNumber);
    String status = user.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Chỉnh sửa người dùng",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Họ và Tên",
                      labelStyle: TextStyle(color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[900],
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      labelStyle: TextStyle(color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[900],
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: Colors.black,
                    items: ["Active", "Blocked"]
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  style: TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      status = value!;
                    },
                    decoration: InputDecoration(
                      labelText: "Trạng thái",
                      labelStyle: TextStyle(color: Colors.orange),
                      filled: true,
                      fillColor: Colors.grey[900],
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          await _userService.updateUser(user.id, {
                            'fullName': nameController.text,
                            'phoneNumber': phoneController.text,
                            'status': status,
                            'updatedAt': DateTime.now(),
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Đã cập nhật thông tin người dùng"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Không thể cập nhật thông tin. Vui lòng thử lại sau."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Lưu",
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xff252429),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border(
          bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // Thanh tìm kiếm
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, email, số điện thoại...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Bộ lọc tỉnh/thành và trạng thái
          Row(
            children: [
              Expanded(
                child: _buildProvinceDropdown(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusDropdown(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    final provinces = users.map((u) => u.province).toSet().toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedProvince,
          isExpanded: true,
          hint: const Text('Tất cả tỉnh/thành',
              style: TextStyle(color: Colors.white70)),
          dropdownColor: const Color(0xff252429),
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Tất cả tỉnh/thành'),
            ),
            ...provinces.map((province) => DropdownMenuItem(
                  value: province,
                  child: Text(province),
                )),
          ],
          onChanged: (value) {
            setState(() {
              selectedProvince = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          dropdownColor: const Color(0xff252429),
          style: const TextStyle(color: Colors.white),
          items: ['Tất cả', 'Active', 'Blocked', 'Deleted'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedStatus = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    // Lọc người dùng dựa trên các điều kiện
    List<User> filteredUsers = users.where((user) {
      bool matchesSearch = searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.phoneNumber.contains(searchQuery);

      bool matchesProvince =
          selectedProvince == null || user.province == selectedProvince;

      bool matchesStatus =
          selectedStatus == 'Tất cả' || user.status == selectedStatus;

      return matchesSearch && matchesProvince && matchesStatus;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(filteredUsers[index]);
      },
    );
  }

  Widget _buildUserCard(User user) {
    Color statusColor;
    switch (user.status) {
      case 'Active':
        statusColor = Colors.green;
        break;
      case 'Blocked':
        statusColor = Colors.red;
        break;
      case 'Deleted':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      user.status,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    user.phoneNumber,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${user.district}, ${user.province}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Chi tiết người dùng',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Họ tên', user.fullName),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Số điện thoại', user.phoneNumber),
              _buildDetailRow('Giới tính', user.gender),
              _buildDetailRow(
                  'Ngày sinh', DateFormat('dd/MM/yyyy').format(user.birthDate)),
              _buildDetailRow('Địa chỉ', '${user.district}, ${user.province}'),
              _buildDetailRow('Trạng thái', user.status),
              _buildDetailRow('Ngày tạo',
                  DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt)),
              if (user.updatedAt != null)
                _buildDetailRow('Cập nhật lần cuối',
                    DateFormat('dd/MM/yyyy HH:mm').format(user.updatedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => _showStatusChangeDialog(user),
            child: const Text('Đổi trạng thái',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(User user) {
    String newStatus = user.status;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff252429),
        title: const Text(
          'Đổi trạng thái người dùng',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: newStatus,
              dropdownColor: const Color(0xff252429),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                ),
              ),
              items: ['Active', 'Blocked', 'Deleted'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                newStatus = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _userService.updateUser(user.id, {
                  'status': newStatus,
                  'updatedAt': DateTime.now(),
                });
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã cập nhật trạng thái người dùng'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Không thể cập nhật trạng thái. Vui lòng thử lại sau.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
