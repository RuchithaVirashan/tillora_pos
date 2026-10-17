import 'package:material_ui/material_ui.dart';

import '../responsive/breakpoints.dart';
import '../theme/app_theme.dart';
import 'module_scaffold.dart';
import 'pos_button.dart';

/// Back Office list + form layout: the list on the left with Add New /
/// Edit / Delete, the form on the right. Stacks on phones.
class CrudLayout extends StatelessWidget {
  const CrudLayout({
    super.key,
    required this.hint,
    required this.list,
    required this.form,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.confirm,
    this.formWidth = 440,
    this.formOpen = false,
    this.onCloseForm,
  });

  /// On phones the form replaces the list while it is open (an item is
  /// selected or being added); [onCloseForm] goes back to the list.
  final bool formOpen;
  final VoidCallback? onCloseForm;

  /// "Selected: X" or "Please select … to edit or delete".
  final String hint;
  final Widget list;
  final Widget form;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Delete confirmation, shown under the toolbar when set.
  final Widget? confirm;
  final double formWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: Text(hint, style: TextStyle(fontWeight: FontWeight.w700, color: c.muted)),
            ),
            PosButton(label: 'Add New', icon: Icons.add_rounded, height: 44, style: PosButtonStyle.primary, onPressed: onAdd),
            PosButton(label: 'Edit', height: 44, style: PosButtonStyle.secondary, onPressed: onEdit),
            PosButton(label: 'Delete', height: 44, style: PosButtonStyle.voidTint, onPressed: onDelete),
          ],
        ),
        if (confirm != null) ...[const SizedBox(height: 12), confirm!],
        const SizedBox(height: 14),
        Expanded(child: list),
      ],
    );
    final right = Panel(child: form);
    return Padding(
      padding: EdgeInsets.all(phone ? 12 : 26),
      child: phone
          ? (formOpen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(onPressed: onCloseForm, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Back to list')),
                      const SizedBox(height: 8),
                      Expanded(child: right),
                    ],
                  )
                : left)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: left), const SizedBox(width: 20), SizedBox(width: formWidth, child: right)],
            ),
    );
  }
}

/// Red "Are you sure you want to delete X?" strip with No / Delete.
/// [onDelete] null shows only No (deleting is not allowed).
class DeleteConfirm extends StatelessWidget {
  const DeleteConfirm({super.key, required this.text, required this.onCancel, this.onDelete});

  final String text;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.voidFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.voidLine),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.voidInk))),
          PosButton(label: 'No', height: 42, style: PosButtonStyle.secondary, onPressed: onCancel),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            PosButton(label: 'Delete', height: 42, style: PosButtonStyle.danger, onPressed: onDelete),
          ],
        ],
      ),
    );
  }
}

/// Shown instead of a screen's content when the user lacks its access flag.
class NoAccess extends StatelessWidget {
  const NoAccess({super.key, required this.what});

  final String what;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(26),
    child: Panel(
      child: Text('You do not have access to $what.', style: TextStyle(color: context.colors.voidInk, fontWeight: FontWeight.w700)),
    ),
  );
}
