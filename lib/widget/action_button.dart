import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Function action;
  final Function longPressAction;
  final bool requireConfirmation;

  ActionButton({
    this.label,
    this.icon,
    this.action,
    this.longPressAction,
    this.requireConfirmation = false,
  });

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    //if (sub != null) sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: (widget.longPressAction == null || _isLoading)
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });

              try {
                await widget.longPressAction();
              } catch (e) {
                // TODO Print
              }

              setState(() {
                _isLoading = false;
              });
            },
      onTap: _isLoading
          ? null
          : () async {
              if (widget.requireConfirmation) {
                final result = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirmation'),
                    content: Text(
                        'Do you really want to execute "${widget.label}"?'),
                    actions: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Execute'),
                      ),
                    ],
                  ),
                );
                if (result != true) return;
              }
              setState(() {
                _isLoading = true;
              });

              try {
                await widget.action();
              } catch (e) {
                // TODO Print
              }

              setState(() {
                _isLoading = false;
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(),
                  )
                : Icon(widget.icon),
            SizedBox(
              height: 4,
            ),
            Text(widget.label),
          ],
        ),
      ),
    );
  }
}
