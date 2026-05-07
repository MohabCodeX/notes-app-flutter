import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/components/highlighted_text.dart';
import 'package:notesapp/database/task_database.dart';
import 'package:notesapp/models/task.dart';
import 'package:provider/provider.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final void Function()? onTap;
  final void Function()? onDeletePressed;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDeletePressed,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 0:
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = context.watch<TaskDatabase>().searchQuery;

    return Container(
      margin: const EdgeInsets.only(top: 15, left: 25, right: 25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: task.isCompleted 
            ? Colors.transparent 
            : _getPriorityColor(task.priority).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Subtle Priority Background Glow
          if (!task.isCompleted)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
          
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 15, top: 15, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE & CHECKBOX & MENU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Checkbox and Title
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: task.isCompleted,
                                onChanged: (val) {
                                  context.read<TaskDatabase>().toggleCompletion(task);
                                },
                                activeColor: _getPriorityColor(task.priority),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: _getPriorityColor(task.priority),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: HighlightedText(
                                text: task.title.isEmpty ? 'Untitled' : task.title,
                                highlight: searchQuery,
                                maxLines: 1,
                                style: GoogleFonts.dmSerifText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: task.isCompleted 
                                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6)
                                    : Theme.of(context).colorScheme.inversePrimary,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                                highlightStyle: GoogleFonts.dmSerifText(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.inversePrimary,
                                  backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        onSelected: (value) {
                          if (value == 'delete') {
                            onDeletePressed?.call();
                          } else if (value == 'edit') {
                            onTap?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  if (task.content.isNotEmpty) const SizedBox(height: 8),

                  // CONTENT SNIPPET
                  if (task.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 36.0),
                      child: HighlightedText(
                        text: task.content,
                        highlight: searchQuery,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.secondary,
                          height: 1.4,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        highlightStyle: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // FOOTER: DUE DATE & MEDIA ICONS
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Due Date or Timestamp
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.isCompleted 
                                ? Colors.transparent 
                                : (task.dueDate != null && task.dueDate!.isBefore(DateTime.now())
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.dueDate != null ? Icons.calendar_today_rounded : Icons.access_time_rounded,
                                size: 12,
                                color: task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                task.dueDate != null ? task.formattedDueDate : task.formattedTimestamp,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !task.isCompleted
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Media Indicators
                        Row(
                          children: [
                            if (task.imagePaths.isNotEmpty)
                              _MediaBadge(icon: Icons.image_outlined, count: task.imagePaths.length),
                            if (task.audioRecordings.isNotEmpty)
                              _MediaBadge(icon: Icons.mic_none_outlined, count: task.audioRecordings.length),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  const _MediaBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.secondary),
          if (count > 1) ...[
            const SizedBox(width: 2),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
