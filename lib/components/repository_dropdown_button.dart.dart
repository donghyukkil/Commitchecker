import 'package:flutter/material.dart';

class RepositoryDropdownButton extends StatelessWidget {
  final String? selectedRepository;
  final List<String> repositories;
  final ValueChanged<String?> onChanged;

  const RepositoryDropdownButton({
    Key? key,
    this.selectedRepository,
    required this.repositories,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      isExpanded: true,
      value: selectedRepository,
      onChanged: onChanged,
      items: repositories.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
