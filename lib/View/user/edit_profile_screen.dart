import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/User.dart';
import '../../Providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Components/loading_animation.dart';
import '../../Services/district_service.dart';
import '../../Model/District.dart';
import '../../Services/province_service.dart';
import '../../Model/Province.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  List<Province> _provinces = [];
  Province? _selectedProvince;
  List<District> _districts = [];
  District? _selectedDistrict;
  late DateTime _selectedDate;
  String _selectedGender = 'Nam';
  bool _isLoading = false;
  bool _isVerifyingEmail = false;
  String? _phoneError;
  final ProvinceService _provinceService = ProvinceService();
  final DistrictService _districtService = DistrictService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedDate = widget.user.birthDate;
    _selectedGender = widget.user.gender;
    _loadProvinces();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isVerifyingEmail = true);

    try {
      // Lấy user hiện tại từ Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Gửi email xác thực
        await currentUser.sendEmailVerification();

        // Hiển thị thông báo
        if (!mounted) return;

        // Hiển thị dialog xác nhận
        bool? confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xff252429),
              title: Text(
                'Xác thực Email',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chúng tôi đã gửi một email xác thực đến địa chỉ email của bạn.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vui lòng kiểm tra hộp thư và nhấn vào liên kết xác thực.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sau khi xác thực, nhấn "Đã xác thực" để tiếp tục.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    'Đã xác thực',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          // Kiểm tra xác thực
          await currentUser.reload();
          if (currentUser.emailVerified) {
            // Tiến hành lưu thông tin sau khi đã xác thực
            await _saveChanges();
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Email chưa được xác thực. Vui lòng thử lại sau khi xác thực.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error sending verification email: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi email xác thực'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifyingEmail = false);
      }
    }
  }

  Future<void> _handleSave() async {
    // Kiểm tra nếu số điện thoại thay đổi
    if (_phoneController.text != widget.user.phoneNumber) {
      // Gửi email xác thực
      await _sendVerificationEmail();
    } else {
      // Nếu không thay đổi số điện thoại, lưu trực tiếp
      await _saveChanges();
    }
  }

  Future<void> _loadProvinces() async {
    try {
      _provinceService.getAllProvinces().listen((provinceList) {
        if (mounted) {
          setState(() {
            _provinces = provinceList;
            // Tìm province hiện tại của user
            _selectedProvince = _provinces.firstWhere(
              (p) => p.name == widget.user.province,
              orElse: () => _provinces.first,
            );
            // Load districts của province đã chọn
            if (_selectedProvince != null) {
              _loadDistricts(_selectedProvince!.id);
            }
          });
        }
      });
    } catch (e) {
      print('Error loading provinces: $e');
    }
  }

  Future<void> _loadDistricts(String provinceId) async {
    try {
      _districtService
          .getDistrictsByProvince(provinceId)
          .listen((districtList) {
        if (mounted) {
          setState(() {
            _districts = districtList;
            // Tìm district hiện tại của user
            _selectedDistrict = _districts.firstWhere(
              (d) => d.name == widget.user.district,
              orElse: () => _districts.first,
            );
          });
        }
      });
    } catch (e) {
      print('Error loading districts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải danh sách quận/huyện'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      appBar: AppBar(
        title: Text(
          "Chỉnh sửa thông tin",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xff252429),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xff252429),
                  Color(0xff2A2A2A),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: "Họ và tên",
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Số điện thoại",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  SizedBox(height: 16),
                  _buildDatePicker(),
                  SizedBox(height: 16),
                  _buildGenderSelector(),
                  SizedBox(height: 16),
                  _buildProvinceSelector(),
                  SizedBox(height: 16),
                  _buildDistrictSelector(),
                  SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
          if (_isLoading || _isVerifyingEmail)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: LoadingAnimation(
                  message: _isVerifyingEmail
                      ? "Đang xác thực..."
                      : "Đang cập nhật thông tin",
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? errorText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        readOnly: readOnly,
        enabled: !readOnly,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorText: errorText,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today_outlined, color: Colors.orange),
        title: Text(
          "Ngày sinh",
          style: TextStyle(color: Colors.white70),
        ),
        subtitle: Text(
          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
          style: TextStyle(color: Colors.white),
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: Text(
                "Nam",
                style: TextStyle(color: Colors.white),
              ),
              value: "Nam",
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text(
                "Nữ",
                style: TextStyle(color: Colors.white),
              ),
              value: "Nữ",
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.location_city_outlined, color: Colors.orange),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Province>(
                value: _selectedProvince,
                hint: Text('Chọn Tỉnh/Thành phố',
                    style: TextStyle(color: Colors.white70)),
                dropdownColor: Color(0xff252429),
                style: TextStyle(color: Colors.white),
                isExpanded: true,
                items: _provinces.map((Province province) {
                  return DropdownMenuItem<Province>(
                    value: province,
                    child: Text(province.name),
                  );
                }).toList(),
                onChanged: (Province? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedProvince = newValue;
                      _selectedDistrict = null;
                    });
                    _loadDistricts(newValue.id);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: Colors.orange),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<District>(
                value: _selectedDistrict,
                hint: Text('Chọn Quận/Huyện',
                    style: TextStyle(color: Colors.white70)),
                dropdownColor: Color(0xff252429),
                style: TextStyle(color: Colors.white),
                isExpanded: true,
                items: _districts.map((District district) {
                  return DropdownMenuItem<District>(
                    value: district,
                    child: Text(district.name),
                  );
                }).toList(),
                onChanged: (District? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: Colors.orange.withOpacity(0.5),
        ),
        child: Text(
          'Lưu thay đổi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // Tạo user object mới với thông tin đã cập nhật
      final updatedUser = widget.user.copyWith(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        province: _selectedProvince?.name ?? widget.user.province,
        district: _selectedDistrict?.name ?? widget.user.district,
        birthDate: _selectedDate,
        gender: _selectedGender,
        updatedAt: DateTime.now(),
      );

      // Cập nhật thông tin trong Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'fullName': updatedUser.fullName,
        'phoneNumber': updatedUser.phoneNumber,
        'province': updatedUser.province,
        'district': updatedUser.district,
        'birthDate': Timestamp.fromDate(updatedUser.birthDate),
        'gender': updatedUser.gender,
        'updatedAt': Timestamp.fromDate(updatedUser.updatedAt!),
      });

      // Cập nhật thông tin trong Provider
      if (!mounted) return;
      context.read<UserProvider>().setUser(updatedUser);

      // Hiển thị thông báo thành công
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // Quay lại màn hình trước
      Navigator.pop(context);
    } catch (e) {
      print('Error updating profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã có lỗi xảy ra khi cập nhật thông tin'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
