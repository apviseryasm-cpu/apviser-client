
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import '../widgets/multiselect_dropdown.dart';
import 'dart:convert'; // For JSON encoding/decoding
import '../AppConstants.dart'; // Assuming this contains your API constants
import '../CommonHelper.dart';
import '../rest_util.dart';

class SelectExpertiseWidget2 extends StatefulWidget {
  final int userId;
  final List<ValueItem<String>> initialSelectedOptions;
  final Function(List<ValueItem<String>>) onSelectionChanged;
  final bool isEditable;
  final String? labelText;

  const SelectExpertiseWidget2({
    required this.userId,
    required this.onSelectionChanged,
    this.initialSelectedOptions = const [],
    this.isEditable = false, // Default is not editable
    this.labelText = "Search Expertise", // Default text is Search Expertise
    Key? key,
  }) : super(key: key);

  @override
  _SelectExpertiseWidgetState createState() => _SelectExpertiseWidgetState();
}

class _SelectExpertiseWidgetState extends State<SelectExpertiseWidget2> {
  List<ValueItem<String>> selectedOptions = [];
  List<ValueItem<String>> availableOptions = [];
  bool _isLoading = false;
  bool _showError = false;
  final TextEditingController _searchController = TextEditingController();

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.SUGGEST_EXPERTISE,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  @override
  void initState() {
    super.initState();
    selectedOptions = widget.initialSelectedOptions;
    if(widget.isEditable){
      _initializeAvailableOptions();
    }

    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeAvailableOptions() async {
    // Add default options initially (these can be updated dynamically based on your use case)
    try {
      final RESTUtil _apiUtil = RESTUtil(
        baseUrl: AppConstants.SUGGEST_TOP_EXPERTISE,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );
      final response = await _apiUtil.get(_apiUtil.baseUrl);
      final List<dynamic> data = json.decode(response.body);
      final fetchedOptions = data
          .map((item) => ValueItem<String>(label: item['name'] ?? '', value: item['id']))
          .toList();

      setState(() {
        availableOptions = [
          ...fetchedOptions.where((option) => !selectedOptions.contains(option)),
        ];

        // // If no expertise is found, allow adding new expertise
        // if (availableOptions.isEmpty) {
        //   availableOptions.add(ValueItem<String>(label: query, value: -1));
        // }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CommonHelper.logDebug('Error fetching data: $e');
    }

    // availableOptions = [
    //   ValueItem<String>(label: 'Cricket', value: 19),
    //   ValueItem<String>(label: 'Food', value: 2),
    //   ValueItem<String>(label: 'Travel', value: 3),
    //   ValueItem<String>(label: 'Medicine', value: 4),
    //   ValueItem<String>(label: 'Real Estate', value: 5),
    //   ValueItem<String>(label: 'Computer Networks', value: 6),
    //   ValueItem<String>(label: 'Music', value: 7),
    // ];

    // Remove already selected options from available options
    availableOptions.removeWhere((option) => selectedOptions.contains(option));
  }


  void _onSearchChanged() {
    String query = _searchController.text.trim();
    if (query.isEmpty) {
      _initializeAvailableOptions();
    } else {
      _fetchData(query);
    }
  }

  Future<void> _fetchData(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiUtil.get(_apiUtil.baseUrl + '$query/');
      final List<dynamic> data = json.decode(response.body);
      final fetchedOptions = data
          .map((item) => ValueItem<String>(label: item['name'] ?? '', value: item['id']))
          .toList();

      setState(() {
        availableOptions = [
          ...fetchedOptions.where((option) => !selectedOptions.contains(option)),
        ];

        // If no expertise is found, allow adding new expertise
        if (availableOptions.isEmpty) {
          availableOptions.add(ValueItem<String>(label: query, value: -1));
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      CommonHelper.logDebug('Error fetching data: $e');
    }
  }



  void _addCustomExpertise(String expertise) {
    ValueItem<String> newExpertise = ValueItem(label: expertise, value: -1);

    if (!selectedOptions.contains(newExpertise)) {
      setState(() {
        selectedOptions.add(newExpertise);
        widget.onSelectionChanged(selectedOptions);
        _searchController.clear();
      });
    }
  }
  void _toggleSelection(ValueItem<String> option) {
    setState(() {
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
      } else {
        selectedOptions.add(option);
      }

      availableOptions.remove(option);
      _showError = selectedOptions.isEmpty;
    });
    widget.onSelectionChanged(selectedOptions); // Notify parent widget
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display selected expertise options
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: selectedOptions.map((option) {
            return Chip(
              label: Text(option.label),
              backgroundColor: Theme.of(context).primaryColor,
              labelStyle: const TextStyle(color: Colors.white),
              deleteIconColor: Colors.white,
              onDeleted: widget.isEditable
                  ? () {
                setState(() {
                  selectedOptions.remove(option);
                  availableOptions.add(option); // Return the option to available list
                });
                widget.onSelectionChanged(selectedOptions);
              }
                  : null, // Disable delete if not editable
            );
          }).toList(),
        ),

        if (widget.isEditable) ...[
          SizedBox(height: 16.0),
          // Search box for expertise options
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '${widget.labelText}',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) _addCustomExpertise(value.trim());
              },
            ),
          ),
        ],

        // Expertise selection dropdown
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
        // if (widget.isEditable) ...[
          SingleChildScrollView(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: availableOptions.map((option) {
                final isSelected = selectedOptions.contains(option);
                return ChoiceChip(
                  label: Text(option.label),
                  selected: isSelected,
                  backgroundColor: isSelected ? Colors.green : Theme.of(context).primaryColor,
                  labelStyle: const TextStyle(color: Colors.white),
                  onSelected: (_) => _toggleSelection(option),
                );
              }).toList(),
            ),
          ),
        // ],
        if (_showError)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Please select at least one expertise option.',
              style: TextStyle(color: Colors.red),
            ),
          ),
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
              label.toLowerCase() == other.label.toLowerCase();

  @override
  int get hashCode => label.toLowerCase().hashCode;

  // Factory constructor to create an ExpertiseDTO from JSON
  factory ValueItem.fromJson(Map<String, dynamic> json) {
    return ValueItem(
      value: int.parse(json['expertise_id']),
      label: json['name'] ??
          (json['expertise_names'] != null
              ? (json['expertise_names'] as List).join(', ')
              : ''),
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
