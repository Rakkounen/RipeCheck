import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_state_views.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/ripeness_chip.dart';
import '../../data/models/fruit_prediction_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/prediction_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PredictionRepository _repository = PredictionRepository();
  final AuthRepository _authRepository = AuthRepository();

  List<FruitPredictionModel> _historyItems = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadHistory();
  }

  Future<void> _checkAuthAndLoadHistory() async {
    setState(() => _isLoading = true);
    final user = await _authRepository.loadCurrentUser();
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
        _historyItems = [];
      });
      return;
    }

    final items = await _repository.getHistory();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = true;
      _userName = user.name;
      _historyItems = items;
      _isLoading = false;
    });
  }

  void _openAuthScreen({bool isRegister = false}) async {
    final result = await Navigator.pushNamed(
      context,
      '/auth',
      arguments: {'isRegister': isRegister},
    );
    if (result == true || mounted) {
      _checkAuthAndLoadHistory();
    }
  }

  void _confirmClearAll() async {
    final confirmed = await AppDialog.showConfirmationDialog(
      context: context,
      title: 'Hapus Semua Riwayat?',
      message: 'Semua data riwayat pemindaian Anda akan dihapus secara permanen.',
      confirmText: 'Hapus Riwayat',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _repository.clearHistory();
      _checkAuthAndLoadHistory();
    }
  }

  void _deleteItem(String id) async {
    await _repository.deletePrediction(id);
    _checkAuthAndLoadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pemindaian'),
        actions: [
          if (_isLoggedIn && _historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Hapus Semua',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_isLoggedIn
              ? _buildGuestAuthPrompt(theme)
              : _buildHistoryList(theme),
    );
  }

  /// Tampilan ketika pengguna belum membuat/masuk akun
  Widget _buildGuestAuthPrompt(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Buat Akun untuk Melihat Riwayat',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textCharcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Agar riwayat pemindaian tersimpan rapi dan tidak membingungkan per pengguna, silakan buat akun atau masuk terlebih dahulu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Buat Akun Baru',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => _openAuthScreen(isRegister: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              text: 'Sudah Punya Akun? Masuk',
              icon: Icons.login_outlined,
              onPressed: () => _openAuthScreen(isRegister: false),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan daftar riwayat khusus user yang sedang login
  Widget _buildHistoryList(ThemeData theme) {
    if (_historyItems.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Belum Ada Riwayat',
        description: 'Halo $_userName, hasil pemindaian kematangan buah Anda akan otomatis tercatat di sini.',
        actionText: 'Mulai Pindai',
        onActionPressed: () => Navigator.pushNamed(context, '/scanner'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: AppRadius.smRadius,
          ),
          child: Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Riwayat Pemindaian: $_userName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: _historyItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = _historyItems[index];
              return Material(
                color: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                  side: BorderSide(color: AppColors.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: item.imagePath.isNotEmpty && File(item.imagePath).existsSync()
                      ? ClipRRect(
                          borderRadius: AppRadius.smRadius,
                          child: Image.file(
                            File(item.imagePath),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: const Icon(Icons.eco_outlined, color: AppColors.primary),
                        ),
                  title: Text(
                    item.fruitName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textCharcoal,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        RipenessChip.fromString(item.ripenessStatus),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${(item.confidence * 100).toInt()}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                    tooltip: 'Hapus item',
                    onPressed: () => _deleteItem(item.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
