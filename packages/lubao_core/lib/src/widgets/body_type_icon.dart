import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/common.dart';

/// Коды, для которых есть миниатюра (`assets/vehicles/<code>.svg`, эталон 29).
/// Новый тип кузова из админки без файла — обычная иконка грузовика.
const _knownBodyCodes = {'tent', 'refrigerator', 'isotherm', 'flatbed', 'container', 'dump', 'lowloader', 'carcarrier', 'grain', 'tank'};

/// Миниатюра кузова (045 п.4): тип кузова по коду справочника; тягач без
/// прицепа и одиночка — по виду машины. Ширина задаётся, высота — половина
/// (SVG 160×80).
class BodyTypeIcon extends StatelessWidget {
  const BodyTypeIcon({super.key, this.bodyTypeCode, this.vehicleKind, this.width = 40});

  final String? bodyTypeCode;
  final VehicleKind? vehicleKind;
  final double width;

  String? get _file {
    if (vehicleKind == VehicleKind.tractor) return 'tractor';
    final code = bodyTypeCode?.toLowerCase();
    if (code != null && _knownBodyCodes.contains(code)) return code;
    if (vehicleKind == VehicleKind.rigid) return 'rigid';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file == null) {
      return SizedBox(width: width, height: width / 2, child: Icon(LucideIcons.truck, size: width / 2));
    }
    return SvgPicture.asset('assets/vehicles/$file.svg', package: 'lubao_core', width: width, height: width / 2, excludeFromSemantics: true);
  }
}
