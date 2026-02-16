import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class MessageBubbleWidget extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final DateTime timestamp;
  final Function()? onLongPress;

  const MessageBubbleWidget({super.key, 
    required this.message,
    required this.isCurrentUser,
    required this.timestamp,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppPadding.medium,
          vertical: AppPadding.small,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppTheme.primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.medium,
                  vertical: AppPadding.small,
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              Formatters.formatTime(timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
