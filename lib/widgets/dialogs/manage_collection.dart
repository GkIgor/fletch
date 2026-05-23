import 'package:flutter/material.dart';
import 'package:fletch/models/collection_model.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:provider/provider.dart';

class NewCollectionDialogBody extends StatefulWidget {
  const NewCollectionDialogBody({
    super.key,
    required this.icons,
    required this.colors,
    required this.isDark,
    this.collection,
  });

  final Map<String, IconData> icons;
  final Map<String, Color> colors;
  final bool isDark;
  final RequestCollection? collection;

  @override
  State<NewCollectionDialogBody> createState() =>
      _NewCollectionDialogBodyState();
}

class _NewCollectionDialogBodyState extends State<NewCollectionDialogBody> {
  String currentColor = '#8b5cf6';
  String currentIcon = 'folder';
  late TextEditingController _collectionDescriptionController;
  late TextEditingController _collectionNameController;
  bool _editing = false;

  @override
  void initState() {
    _collectionDescriptionController = TextEditingController();
    _collectionNameController = TextEditingController();

    if (widget.collection != null) {
      _editing = true;
      currentColor = widget.collection!.color;
      currentIcon = widget.collection!.icon;
      _collectionNameController.text = widget.collection?.name ?? '';
      _collectionDescriptionController.text =
          widget.collection?.description ?? '';
    }

    super.initState();
  }

  @override
  void dispose() {
    _collectionDescriptionController.dispose();
    _collectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 500,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_editing ? Icons.edit_note_rounded : Icons.create_new_folder),
                const SizedBox(width: 8),
                Text(_editing ? 'Edit Collection' : 'Create New Collection'),
              ],
            ),
            Divider(
              height: 1,
              color: widget.isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
            const SizedBox(height: 25),
            const Text('COLLECTION NAME'),
            const SizedBox(height: 12),
            TextField(
              controller: _collectionNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Payments API',
                hintStyle: TextStyle(
                  color:
                      (widget.isDark ? AppColors.textDark : AppColors.textLight)
                          .withValues(alpha: 0.2),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SELECT ICON'),
                    // const SizedBox(height: 2),
                    Row(
                      children: [
                        for (final entry in widget.icons.entries) ...[
                          _buildIconSelector(entry, entry.key == currentIcon),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Column(
                  children: [
                    Text('FOLDER COLOR'),
                    Row(
                      children: [
                        for (final color in widget.colors.entries) ...[
                          _buildColorSelector(color, color.key == currentColor),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESCRIPTION (OPTIONAL)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _collectionDescriptionController,
                  maxLines: 8,
                  minLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText:
                        'Briefly describe the purpose of this collection...',
                    hintStyle: TextStyle(
                      color:
                          (widget.isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight)
                              .withValues(alpha: 0.2),
                      fontSize: 13,
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: [
                SizedBox(height: 24),
                Divider(height: 1),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: widget.isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: widget.isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleSubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _editing ? 'Update Collection' : 'Create Collection',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector(MapEntry<String, IconData> entry, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          currentIcon = entry.key;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1.5,
            color: isSelected
                ? AppColors.primary.withValues(alpha: .9)
                : (widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
          ),

          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(8),
        child: Icon(
          entry.value,
          color: isSelected
              ? AppColors.primary.withValues(alpha: .9)
              : AppColors.slate500,
        ),
      ),
    );
  }

  Widget _buildColorSelector(MapEntry<String, Color> entry, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          currentColor = entry.key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? entry.value : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_collectionNameController.text.isEmpty) {
      return;
    }

    final collection = RequestCollection(
      name: _collectionNameController.text,
      description: _collectionDescriptionController.text,
      workspaceId: _editing
          ? widget.collection!.workspaceId
          : Provider.of<WorkspaceProvider>(
              context,
              listen: false,
            ).currentWorkspace!.id,
      requests: _editing ? widget.collection!.requests : [],
      isExpanded: _editing ? widget.collection!.isExpanded : true,
      icon: currentIcon,
      color: currentColor,
      id: _editing ? widget.collection!.id : null,
      parentId: _editing ? widget.collection!.parentId : null,
      sortOrder: _editing ? widget.collection!.sortOrder : 0,
    );

    if (!_editing) {
      await Provider.of<RequestProvider>(
        context,
        listen: false,
      ).addCollection(collection);
    } else {
      await Provider.of<RequestProvider>(
        context,
        listen: false,
      ).updateCollection(collection);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
