import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReportTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool onlyNumbers;

  const ReportTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onlyNumbers = false,
  });

  static const _fill = Color(0xFF162346);
  static const _text = Colors.white;
  static const _muted = Color(0xFFAAB6D3);
  static const _focus = Color(0xFF42D7FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _text,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _focus.withValues(alpha: 0.10),
                blurRadius: 14,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            inputFormatters: onlyNumbers
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _focus,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _muted,
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: _fill,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: maxLines > 1 ? 18 : 17,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: _focus.withValues(alpha: 0.22),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: _focus,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B7A),
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B7A),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}