import 'package:flutter/material.dart';

class GuestLogicProvider extends ChangeNotifier {
    bool _guestLogic = true;

    bool get guestLogic => _guestLogic;

    set guestLogic(bool value) {
        if (_guestLogic != value) {
            _guestLogic = value;
            notifyListeners();
        }
    }
}