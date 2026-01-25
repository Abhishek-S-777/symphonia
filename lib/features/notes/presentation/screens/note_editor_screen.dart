import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/note_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/entities/note.dart';

/// Full-page Quill editor for creating/editing notes
class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  late FocusNode _editorFocusNode;
  bool _isLoading = false;
  bool _hasChanges = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    _editorFocusNode = FocusNode();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // Initialize Quill controller with existing content or empty document
    if (widget.note != null) {
      try {
        final deltaJson = jsonDecode(widget.note!.content);
        final doc = Document.fromJson(deltaJson);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackbar.showWarning(context, 'Please enter a title');
      return;
    }

    final content = jsonEncode(_quillController.document.toDelta().toJson());

    // Check if content is empty (only contains newline)
    final plainText = _quillController.document.toPlainText().trim();
    if (plainText.isEmpty) {
      AppSnackbar.showWarning(context, 'Please add some content');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final noteService = ref.read(noteServiceProvider);

      if (isEditing) {
        await noteService.updateNote(
          widget.note!.copyWith(title: title, content: content),
        );
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Note updated! ✨');
        }
      } else {
        await noteService.createNote(title: title, content: content);
        if (mounted) {
          AppSnackbar.showSuccess(context, 'Note saved! 📝');
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, 'Error saving note: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildEditor()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              isEditing ? 'Edit Note' : 'New Note',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Save button
          _buildSaveButton(),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveNote,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : null,
        label: Text(isEditing ? 'Save' : 'Create'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.6),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms);
  }

  Widget _buildEditor() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Title field
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                hintText: 'Note Title',
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: AppColors.gray.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
              ),
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          Divider(color: AppColors.gray.withValues(alpha: 0.2), height: 1),
          // Quill toolbar
          _buildToolbar(),
          Divider(color: AppColors.gray.withValues(alpha: 0.2), height: 1),
          // Quill editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _editorFocusNode,
                config: QuillEditorConfig(
                  placeholder: 'Start writing your note...',
                  padding: EdgeInsets.zero,
                  scrollable: true,
                  autoFocus: false,
                  expands: true,
                  customStyles: DefaultStyles(
                    placeHolder: DefaultTextBlockStyle(
                      TextStyle(
                        color: AppColors.gray.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                    paragraph: DefaultTextBlockStyle(
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(6, 0),
                      const VerticalSpacing(0, 6),
                      null,
                    ),
                    h1: DefaultTextBlockStyle(
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(12, 0),
                      const VerticalSpacing(0, 12),
                      null,
                    ),
                    h2: DefaultTextBlockStyle(
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(10, 0),
                      const VerticalSpacing(0, 10),
                      null,
                    ),
                    h3: DefaultTextBlockStyle(
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(8, 0),
                      const VerticalSpacing(0, 8),
                      null,
                    ),
                    bold: const TextStyle(fontWeight: FontWeight.bold),
                    italic: const TextStyle(fontStyle: FontStyle.italic),
                    underline: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                    strikeThrough: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                    ),
                    link: TextStyle(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                    lists: DefaultListBlockStyle(
                      const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      const HorizontalSpacing(0, 0),
                      const VerticalSpacing(6, 0),
                      const VerticalSpacing(0, 6),
                      null,
                      null,
                    ),
                    quote: DefaultTextBlockStyle(
                      TextStyle(
                        color: AppColors.gray,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      const HorizontalSpacing(16, 0),
                      const VerticalSpacing(8, 0),
                      const VerticalSpacing(0, 8),
                      BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppColors.accent, width: 3),
                        ),
                      ),
                    ),
                    code: DefaultTextBlockStyle(
                      TextStyle(
                        color: AppColors.primaryLight,
                        fontFamily: 'monospace',
                        fontSize: 14,
                        height: 1.6,
                      ),
                      const HorizontalSpacing(8, 8),
                      const VerticalSpacing(8, 0),
                      const VerticalSpacing(0, 8),
                      BoxDecoration(
                        color: AppColors.darkElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: true,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: false,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showInlineCode: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showAlignmentButtons: false,
          showLeftAlignment: false,
          showCenterAlignment: false,
          showRightAlignment: false,
          showJustifyAlignment: false,
          showHeaderStyle: true,
          showCodeBlock: false,
          showQuote: true,
          showIndent: false,
          showLink: true,
          showUndo: false,
          showRedo: false,
          showDirection: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showClipboardCut: false,
          showClipboardCopy: false,
          showClipboardPaste: false,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonUnselectedData: IconButtonData(color: AppColors.gray),
                iconButtonSelectedData: IconButtonData(
                  color: AppColors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
