import 'dart:convert';
import 'package:Apviser/AppConstants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../CommonHelper.dart';
import '../rest_util.dart';
import '../pages/error_screen.dart'; // Ensure this path is correct

typedef OnOptionSelected<T> = void Function(List<ValueItem<T>> selectedOptions);

class MultiSelectDropDown<T> extends StatefulWidget {
  final OnOptionSelected<T> onOptionSelected;
  final List<ValueItem<T>> options;
  final bool searchEnabled;
  final String? searchLabel;

  const MultiSelectDropDown({
    Key? key,
    required this.onOptionSelected,
    required this.options,
    this.searchEnabled = false,
    this.searchLabel,

  }) : super(key: key);

  @override
  _MultiSelectDropDownState<T> createState() => _MultiSelectDropDownState<T>();
}

class _MultiSelectDropDownState<T> extends State<MultiSelectDropDown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<ValueItem<T>> _options = [];
  List<ValueItem<T>> _selectedOptions = [];
  bool _isLoading = false;

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.SUGGEST_EXPERTISE,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _options = widget.options;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // If the search field is cleared, reset the options
    if (_searchController.text.isEmpty) {
      setState(() {
        _options = widget.options;
      });
    } else {
      _fetchData(_searchController.text);
    }
  }

  Future<void> _fetchData(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiUtil.get(_apiUtil.baseUrl+'$query/');
      final List<dynamic> data = json.decode(response.body);
      final newOptions = data.map((item) => ValueItem<T>(
        label: item['name'] ?? '',
        value: item['id'],
      )).toList();

      setState(() {
        // Merge new search results with existing options and filter out already selected ones
        _options = [
          ...widget.options, // Keep initial options
          ...newOptions.where((option) => !_selectedOptions.contains(option))
        ].toSet().toList(); // Ensure no duplicates in the list

        _isLoading = false;
      });
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(ValueItem<T> option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
      widget.onOptionSelected(_selectedOptions);
    });
  }

  void _removeSelection(ValueItem<T> option) {
    setState(() {
      _selectedOptions.remove(option);
      widget.onOptionSelected(_selectedOptions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.searchEnabled)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: widget.searchLabel ?? 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        // Wrap(
        //   spacing: 8.0,
        //   runSpacing: 4.0,
        //   children: _selectedOptions.map((option) {
        //     return Chip(
        //       label: Text(option.label),
        //       onDeleted: () => _removeSelection(option),
        //     );
        //   }).toList(),
        // ),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : Container(
          height: 200, // Specify a height constraint
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _options.map((option) {
                final isSelected = _selectedOptions.contains(option);
                return ChoiceChip(
                  backgroundColor: isSelected
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                  labelStyle: TextStyle(color: Colors.white),
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => _toggleSelection(option),
                );
              }).toList(),
            ),
          ),
        ),
        // Display selected options with delete icon
        // Wrap(
        //   spacing: 8.0,
        //   runSpacing: 4.0,
        //   children: _selectedOptions.map((option) {
        //     return Chip(
        //       label: Text(option.label),
        //       onDeleted: () => _removeSelection(option),
        //     );
        //   }).toList(),
        // ),
      ],
    );
  }
}

class ValueItem<T> {
  final String label;
  final int value;

  ValueItem({
    required this.label,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ValueItem<T> &&
              runtimeType == other.runtimeType &&
              label == other.label &&
              value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  // Factory constructor to create an ExpertiseDTO from JSON
  factory ValueItem.fromJson(Map<String, dynamic> json) {
    return ValueItem(
      value: int.parse(json['expertise_id']),
      label: json['name'] ?? '',
    );
  }

  // Method to convert ExpertiseDTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'expertise_id': value,
      'name': label,
    };
  }
}
