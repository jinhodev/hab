import 'package:flutter/material.dart';

class AddCategoryDialog extends StatefulWidget {
  final bool isExpense;
  final Function(String) onSave;

  const AddCategoryDialog({
    super.key,
    required this.isExpense,
    required this.onSave,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF404040),
      title: const Text(
        '카테고리 추가',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '카테고리명을 입력하세요',
          hintStyle: TextStyle(color: Colors.grey[600]),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '취소',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            final category = _controller.text.trim();
            if (category.isNotEmpty) {
              widget.onSave(category);
              Navigator.of(context).pop();
            }
          },
          child: Text(
            '추가',
            style: TextStyle(
              color: widget.isExpense
                  ? const Color(0xFFFF6666) // 지출일 때는 빨간색
                  : const Color(0xFF438BFF), // 수입일 때는 파란색
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
