import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Thêm cho định dạng ngày
import 'package:cached_network_image/cached_network_image.dart'; // Thêm thư viện để sử dụng CachedNetworkImage
import '../../Model/Movie.dart';
import '../../Model/Genre.dart';
import '../../Services/genre_service.dart';

class MovieEditScreen extends StatefulWidget {
  final bool isEdit;
  final Movie? movie;

  const MovieEditScreen({Key? key, required this.isEdit, this.movie})
      : super(key: key);

  @override
  _MovieEditScreenState createState() => _MovieEditScreenState();
}

class _MovieEditScreenState extends State<MovieEditScreen> {
  final GenreService _genreService = GenreService();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _releaseDateController;
  late TextEditingController _descriptionController;
  late TextEditingController _trailerUrlController;
  late TextEditingController _directorController;
  late TextEditingController _castController;
  late List<Genre> _selectedGenres;
  List<Genre> _allGenres = [];
  File? _imageFile;
  DateTime _selectedDate = DateTime.now(); // Mặc định là ngày hiện tại
  bool _isShowingNow = false; // Trạng thái phim đang chiếu
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenres();
    if (widget.isEdit && widget.movie != null) {
      _titleController = TextEditingController(text: widget.movie!.title);
      _durationController = TextEditingController(text: widget.movie!.duration);
      _releaseDateController =
          TextEditingController(text: widget.movie!.releaseDate);
      _descriptionController =
          TextEditingController(text: widget.movie!.description);
      _trailerUrlController =
          TextEditingController(text: widget.movie!.trailerUrl);
      _directorController = TextEditingController(text: widget.movie!.director);
      _castController =
          TextEditingController(text: widget.movie!.cast.join(", "));
      _selectedGenres = List.from(widget.movie!.genres);
      if (!widget.movie!.imagePath.startsWith('http')) {
        _imageFile = File(widget.movie!.imagePath);
      }
      _isShowingNow = widget.movie!.isShowingNow; // Lấy trạng thái phim
    } else {
      _titleController = TextEditingController();
      _durationController = TextEditingController();
      _releaseDateController = TextEditingController();
      _descriptionController = TextEditingController();
      _trailerUrlController = TextEditingController();
      _directorController = TextEditingController();
      _castController = TextEditingController();
      _selectedGenres = [];
    }
  }

  void _loadGenres() {
    _genreService.getAllGenres().listen(
      (genres) {
        setState(() {
          _allGenres = genres;
          _isLoading = false;
        });
      },
      onError: (error) {
        print('Error loading genres: $error');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã có lỗi xảy ra khi tải danh sách thể loại'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _releaseDateController.dispose();
    _descriptionController.dispose();
    _trailerUrlController.dispose();
    _directorController.dispose();
    _castController.dispose();
    super.dispose();
  }

  void _selectGenres(List<Genre> selectedGenres) {
    setState(() {
      _selectedGenres = selectedGenres;
    });
  }

  // Chọn ảnh từ máy hoặc chụp ảnh
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
        _releaseDateController.text =
            DateFormat('dd-MM-yyyy').format(_selectedDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xff252429),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Chỉnh sửa Phim" : "Thêm Phim"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập tên phim'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final movie = Movie(
                id: widget.movie?.id ?? DateTime.now().toString(),
                title: _titleController.text,
                imagePath: _imageFile?.path ?? widget.movie?.imagePath ?? '',
                trailerUrl: _trailerUrlController.text,
                duration: _durationController.text,
                genres: _selectedGenres,
                isShowingNow: _isShowingNow,
                description: _descriptionController.text,
                cast: _castController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                reviewCount: widget.movie?.reviewCount ?? 0,
                releaseDate: _releaseDateController.text,
                director: _directorController.text,
              );

              Navigator.pop(context, movie);
            },
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xff252429),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _imageFile == null
                      ? 'Chọn Poster Phim'
                      : 'Thay Đổi Poster Phim',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 200,
              height: 300, // Tăng chiều cao
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black12,
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : widget.movie?.imagePath != null &&
                          widget.movie!.imagePath.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.movie!.imagePath,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.error,
                                color: Colors.orange,
                                size: 40,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.movie,
                            size: 50,
                            color: Colors.orange,
                          ),
                        ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_titleController, "Tên Phim", Icons.movie),
            _buildTextField(_durationController, "Thời gian", Icons.timer),
            _buildTextField(
              _releaseDateController,
              "Ngày phát hành",
              Icons.calendar_today,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            _buildTextField(
              _descriptionController,
              "Mô tả",
              Icons.description,
              maxLines: 3,
            ),
            _buildTextField(
              _trailerUrlController,
              "URL Trailer",
              Icons.play_circle_filled,
            ),
            _buildTextField(_directorController, "Tên Đạo Diễn", Icons.person),
            _buildTextField(_castController,
                "Diễn Viên (ngăn cách bằng dấu phẩy)", Icons.people),

            const SizedBox(height: 10),
            _buildGenreSelector(),

            const SizedBox(height: 20),

            // Switch với style mới
            SwitchListTile(
              title: const Text(
                "Phim đang chiếu",
                style: TextStyle(color: Colors.white70),
              ),
              subtitle: Text(
                _isShowingNow ? 'Đang chiếu' : 'Sắp chiếu',
                style: TextStyle(
                  color: _isShowingNow ? Colors.green : Colors.blue,
                ),
              ),
              value: _isShowingNow,
              onChanged: (bool value) {
                setState(() {
                  _isShowingNow = value;
                });
              },
              activeColor: Colors.orange,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.orange),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange),
          ),
          filled: true,
          fillColor: Colors.black12,
        ),
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Thể loại phim",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allGenres.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return FilterChip(
                label: Text(
                  genre.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedGenres.add(genre);
                    } else {
                      _selectedGenres.removeWhere((g) => g.id == genre.id);
                    }
                  });
                },
                backgroundColor: Colors.black26,
                selectedColor: Colors.orange,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.orange
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
