void _handleSave() async {
  if (_nameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a name for your palette')),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final result = await _paintService.createPalette(
      _nameController.text,
      _selectedColors,
      widget.token,
    );

    if (result['success'] == true) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create palette'),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating palette: $e')));
    }
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

void _handleColorTap(Color color) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    } else {
      _selectedColors.add(color);
    }
  });
}

void _handleColorLongPress(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragStart(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragEnd(Color color) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragUpdate(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragCancel() {
  setState(() {
    _selectedColors.clear();
  });
}

void _handleColorDragAccept(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragReject(Color color) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragEnter(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragExit(Color color) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragOver(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragLeave(Color color) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragMove(Color color) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragStartWithDetails(Color color, DragStartDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragUpdateWithDetails(Color color, DragUpdateDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragEndWithDetails(Color color, DragEndDetails details) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragCancelWithDetails(DragCancelDetails details) {
  setState(() {
    _selectedColors.clear();
  });
}

void _handleColorDragAcceptWithDetails(Color color, DragAcceptDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragRejectWithDetails(Color color, DragRejectDetails details) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragEnterWithDetails(Color color, DragEnterDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragExitWithDetails(Color color, DragExitDetails details) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragOverWithDetails(Color color, DragOverDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}

void _handleColorDragLeaveWithDetails(Color color, DragLeaveDetails details) {
  setState(() {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    }
  });
}

void _handleColorDragMoveWithDetails(Color color, DragMoveDetails details) {
  setState(() {
    if (!_selectedColors.contains(color)) {
      _selectedColors.add(color);
    }
  });
}
