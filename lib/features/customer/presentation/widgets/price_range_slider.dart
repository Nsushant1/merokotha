import 'package:flutter/material.dart';
import 'package:merokotha/core/constants/app_colors.dart';
import 'package:merokotha/core/utils/formatters.dart';

class PriceRangeSlider extends StatefulWidget {
  final double? minValue;
  final double? maxValue;
  final void Function(double? min, double? max) onChanged;

  const PriceRangeSlider({
    super.key,
    this.minValue,
    this.maxValue,
    required this.onChanged,
  });

  @override
  State<PriceRangeSlider> createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  static const _min = 0.0;
  static const _max = 100000.0;

  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(widget.minValue ?? _min, widget.maxValue ?? _max);
  }

  String _label(double v) {
    if (v >= 100000) return 'Any';
    return 'NPR ${Formatters.amount(v)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _label(_values.start),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            Text(
              _label(_values.end),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.customerPrimary,
            inactiveTrackColor: AppColors.grey100,
            thumbColor: AppColors.customerPrimary,
            overlayColor: AppColors.customerLight,
            trackHeight: 3,
          ),
          child: RangeSlider(
            values: _values,
            min: _min,
            max: _max,
            divisions: 100,
            onChanged: (v) {
              setState(() => _values = v);
              widget.onChanged(
                v.start <= _min ? null : v.start,
                v.end >= _max ? null : v.end,
              );
            },
          ),
        ),
      ],
    );
  }
}
