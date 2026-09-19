import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/multiselect_dropdown.dart';
import 'dart:convert'; // For JSON encoding/decoding
import '../AppConstants.dart'; // Assuming this contains your API constants
import '../rest_util.dart';

class SelectExpertiseWidget extends StatefulWidget {
  final int userId;
  final List<ValueItem<String>> initialSelectedOptions;
  final Function(List<ValueItem<String>>) onSelectionChanged;
  final bool isEditable; // Add an isEditable flag

  SelectExpertiseWidget({
    required this.userId,
    required this.onSelectionChanged,
    this.initialSelectedOptions = const [],
    this.isEditable = false, // Default is false
  });

  @override
  _SelectExpertiseWidgetState createState() => _SelectExpertiseWidgetState();
}

class _SelectExpertiseWidgetState extends State<SelectExpertiseWidget> {
  List<ValueItem<String>> selectedOptions = [];
  List<ValueItem<String>> expertiseOptions = [];
  bool _isLoading = true; // To show a loading indicator
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected options with the ones passed in initially
    selectedOptions = widget.initialSelectedOptions;
  }

  void _onOptionSelected(List<ValueItem<String>> options) {
    // Maintain the previous selected options and add new ones without duplication
    setState(() {
      options.forEach((option) {
        if (!selectedOptions.contains(option)) {
          selectedOptions.add(option);
        }
      });
      _showError = false;
    });
    widget.onSelectionChanged(selectedOptions); // Notify parent widget about selection
  }

  @override
  Widget build(BuildContext context) {
    // Filter out options that are already selected
    List<ValueItem<String>> availableOptions = [
      ValueItem<String>(label: 'Cricket', value: 19),
      ValueItem<String>(label: 'Food', value: 2),
      ValueItem<String>(label: 'Travel', value: 3),
      ValueItem<String>(label: 'Medicine', value: 4),
      ValueItem<String>(label: 'Real Estate', value: 5),
      ValueItem<String>(label: 'Computer Networks', value: 6),
      ValueItem<String>(label: 'Music', value: 7),
    ].where((option) => !selectedOptions.contains(option)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected options
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: selectedOptions.map((option) {
            return Chip(
              label: Text(option.label),
              backgroundColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(color: Colors.white),
              deleteIconColor: Colors.white,
              onDeleted: widget.isEditable
                  ? () {
                setState(() {
                  selectedOptions.remove(option);
                });
              }
                  : null, // Disable delete if not editable
            );
          }).toList(),
        ),
        if (widget.isEditable) ...[
          SizedBox(height: 16.0),
          // Show search dropdown only when editable
          MultiSelectDropDown<String>(
            options: availableOptions, // Filtered options
            searchEnabled: true,
            searchLabel: 'Search Expertise',
            onOptionSelected: _onOptionSelected,
          ),
        ],
        if (_showError)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Please select at least one expertise option.',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
