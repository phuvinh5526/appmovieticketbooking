import 'dart:math' as math;

class SeatSelectionValidator {
  // Kiểm tra tính hợp lệ của toàn bộ ghế đã chọn
  static Map<String, List<String>> validateSeats(
    List<String> selectedSeats,
    List<String> bookedSeats,
    int totalSeatsInRow,
  ) {
    Map<String, List<String>> errors = {};

    // Nếu không có ghế nào được chọn
    if (selectedSeats.isEmpty) {
      errors['general'] = ['Vui lòng chọn ít nhất một ghế'];
      return errors;
    }

    // Nhóm ghế theo hàng
    Map<String, List<int>> seatsByRow = {};
    for (String seat in selectedSeats) {
      String row = seat[0];
      int number = int.parse(seat.substring(1));
      if (!seatsByRow.containsKey(row)) {
        seatsByRow[row] = [];
      }
      seatsByRow[row]!.add(number);
    }

    // Kiểm tra từng hàng
    for (var row in seatsByRow.keys) {
      var numbers = seatsByRow[row]!..sort();
      List<String> rowErrors = [];

      // Kiểm tra ghế ở bìa trái
      if (numbers.contains(2) &&
          !numbers.contains(1) &&
          !bookedSeats.contains('$row${1}')) {
        rowErrors.add('Không được để trống ghế 1 khi chọn ghế 2');
      }

      // Kiểm tra ghế ở bìa phải
      if (numbers.contains(totalSeatsInRow - 1) &&
          !numbers.contains(totalSeatsInRow) &&
          !bookedSeats.contains('$row$totalSeatsInRow')) {
        rowErrors.add('Không được để trống ghế cuối khi chọn ghế kế cuối');
      }

      // Kiểm tra khoảng trống giữa các ghế
      List<int> allOccupiedNumbers = [
        ...numbers,
        ...bookedSeats
            .where((seat) => seat[0] == row)
            .map((seat) => int.parse(seat.substring(1)))
      ]..sort();

      for (int i = 0; i < allOccupiedNumbers.length - 1; i++) {
        if (allOccupiedNumbers[i + 1] - allOccupiedNumbers[i] == 2) {
          rowErrors.add(
              'Không được để trống 1 ghế giữa các ghế đã chọn hoặc đã đặt ở hàng $row');
          break;
        }
      }

      // Kiểm tra tính liền kề của ghế đã chọn trong hàng
      for (int i = 0; i < numbers.length - 1; i++) {
        if (numbers[i + 1] - numbers[i] > 1) {
          rowErrors.add('Các ghế được chọn trong hàng $row phải liền kề nhau');
          break;
        }
      }

      if (rowErrors.isNotEmpty) {
        errors[row] = rowErrors;
      }
    }

    return errors;
  }

  // Kiểm tra xem việc chọn ghế có hợp lệ không
  static bool isValidSeatSelection(
    String selectedSeat,
    List<String> currentlySelectedSeats,
    List<String> bookedSeats,
    int totalSeatsInRow,
  ) {
    String row = selectedSeat[0];
    int seatNumber = int.parse(selectedSeat.substring(1));

    // Lấy tất cả số ghế đã đặt và đang chọn trong cùng hàng và sắp xếp
    List<int> allOccupiedNumbers = [...bookedSeats, ...currentlySelectedSeats]
        .where((seat) => seat[0] == row)
        .map((seat) => int.parse(seat.substring(1)))
        .toList()
      ..sort();

    // Kiểm tra ghế ở bìa
    // Nếu chọn ghế thứ 2 từ trái qua, ghế 1 phải được đặt hoặc chọn
    if (seatNumber == 2) {
      String firstSeat = '$row${1}';
      if (!bookedSeats.contains(firstSeat) &&
          !currentlySelectedSeats.contains(firstSeat)) {
        return false;
      }
    }

    // Nếu chọn ghế áp cuối, ghế cuối phải được đặt hoặc chọn
    if (seatNumber == totalSeatsInRow - 1) {
      String lastSeat = '$row$totalSeatsInRow';
      if (!bookedSeats.contains(lastSeat) &&
          !currentlySelectedSeats.contains(lastSeat)) {
        return false;
      }
    }

    // Nếu không có ghế nào được đặt/chọn, cho phép chọn
    if (allOccupiedNumbers.isEmpty) {
      return true;
    }

    // Kiểm tra xem có tạo ra ghế trống đơn lẻ không
    for (int i = 0; i < allOccupiedNumbers.length; i++) {
      // Nếu ghế đang chọn nằm cạnh ghế đã đặt/chọn, cho phép chọn
      if ((allOccupiedNumbers[i] - seatNumber).abs() == 1) {
        return true;
      }

      // Nếu ghế đang chọn tạo ra khoảng trống 1 ghế
      if ((allOccupiedNumbers[i] - seatNumber).abs() == 2) {
        // Không cho phép tạo khoảng trống 1 ghế trong mọi trường hợp
        return false;
      }
    }

    // Nếu đã có ghế được chọn trong lượt này, ghế mới phải liền kề
    if (currentlySelectedSeats.isNotEmpty) {
      bool hasAdjacentSeat = false;
      for (String seat
          in currentlySelectedSeats.where((seat) => seat[0] == row)) {
        int selectedNumber = int.parse(seat.substring(1));
        if ((selectedNumber - seatNumber).abs() == 1) {
          hasAdjacentSeat = true;
          break;
        }
      }
      if (!hasAdjacentSeat) {
        return false;
      }
    }

    return true;
  }

  // Kiểm tra tính liền kề của ghế đã chọn
  static bool areSeatsContiguous(List<String> selectedSeats) {
    if (selectedSeats.isEmpty || selectedSeats.length == 1) return true;

    // Nhóm ghế theo hàng
    Map<String, List<int>> seatsByRow = {};
    for (String seat in selectedSeats) {
      String row = seat[0];
      int number = int.parse(seat.substring(1));
      if (!seatsByRow.containsKey(row)) {
        seatsByRow[row] = [];
      }
      seatsByRow[row]!.add(number);
    }

    // Kiểm tra từng hàng
    for (var numbers in seatsByRow.values) {
      numbers.sort();
      for (int i = 0; i < numbers.length - 1; i++) {
        if (numbers[i + 1] - numbers[i] != 1) {
          return false;
        }
      }
    }

    return true;
  }
}
