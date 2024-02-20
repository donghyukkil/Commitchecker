import 'package:flutter/material.dart';

class RepositoryDropdownButton extends StatefulWidget {
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
  _RepositoryDropdownButtonState createState() =>
      _RepositoryDropdownButtonState();
}

class _RepositoryDropdownButtonState extends State<RepositoryDropdownButton> {
  late String? currentItem;

  @override
  void initState() {
    super.initState();

    currentItem = widget.selectedRepository ??
        (widget.repositories.isNotEmpty ? widget.repositories.first : null);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          currentItem = value;
        });

        widget.onChanged(value);
      },
      itemBuilder: (BuildContext context) {
        return widget.repositories.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(
              choice,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: IntrinsicWidth(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: Text(
                  currentItem ?? 'Select repository',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 50),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
