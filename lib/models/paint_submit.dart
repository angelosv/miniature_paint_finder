import 'package:flutter/material.dart';

class PaintSubmit {
    final String imageUrl;
    final String brandId;
    final String barcode;   
    final String name;   
    final String status;
    String? color;
    String? set;
    String? code;
    String? hex;
    int? r;
    int? g;
    int? b;

    PaintSubmit({
    required this.imageUrl,
    required this.brandId,
    this.color,
    this.set,
    this.code,
    required this.barcode,
    required this.name,
    required this.status,
    this.hex,
    this.r,
    this.g,
    this.b,
    });

    Map<String, dynamic> toJson() {
        return {
            'imageUrl': imageUrl,
            'brandId': brandId,
            'color': color,
            'set': set,
            'code': code,
            'barcode': barcode,
            'name': name,
            'status': status,   
            'hex': hex,
            'r': r,
            'g': g,
            'b': b,
        };
    }   
}

