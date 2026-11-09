import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_dialog.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authRepository.loadCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    final confirmed = await AppDialog.showConfirmationDialog(
      context: context,
      title: 'Keluar dari Akun?',
      message: 'Anda harus masuk kembali untuk melihat riwayat scan Anda.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _authRepository.logout();
      _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil keluar dari akun')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Bagian Akun Pengguna
          Text(
            'Akun Pengguna',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : _currentUser != null
                    ? Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              _currentUser!.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(_currentUser!.email),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.error),
                            title: const Text(
                              'Keluar dari Akun',
                              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                            onTap: _handleLogout,
                          ),
                        ],
                      )
                    : ListTile(
                        leading: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
                        title: const Text('Belum Masuk Akun'),
                        subtitle: const Text('Masuk atau buat akun untuk riwayat Anda'),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () async {
                          final res = await Navigator.pushNamed(context, '/auth');
                          if (res == true || mounted) _loadUser();
                        },
                      ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Umum & Bantuan',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback_outlined, color: AppColors.primary),
                  title: const Text('Beri Umpan Balik'),
                  subtitle: const Text('Kirim masukan akurasi deteksi'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.pushNamed(context, '/feedback'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                  title: const Text('Panduan Penggunaan'),
                  subtitle: const Text('Lihat kembali pengenalan aplikasi'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.pushNamed(context, '/onboarding'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  title: const Text('Panduan Buah'),
                  subtitle: const Text('Katalog kematangan buah'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.pushNamed(context, '/fruit_guide'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Informasi Model & Sistem',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.mdRadius,
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.memory_outlined, color: AppColors.secondary),
                  title: Text('Model TensorFlow Lite'),
                  subtitle: Text('ripecheck_model.tflite (On-device)'),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.storage_outlined, color: AppColors.secondary),
                  title: Text('Penyimpanan Database'),
                  subtitle: Text('SQLite (sqflite) per-user'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.secondary),
                  title: const Text(AppConstants.appName),
                  subtitle: const Text('Versi ${AppConstants.appVersion}'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                  title: const Text(
                    'Bersihkan Cache Pemindaian',
                    style: TextStyle(color: AppColors.error),
                  ),
                  subtitle: const Text('Hapus file sementara gambar kamera'),
                  onTap: () async {
                    final confirmed = await AppDialog.showConfirmationDialog(
                      context: context,
                      title: 'Bersihkan Cache?',
                      message: 'File gambar sementara dari kamera akan dibersihkan.',
                      confirmText: 'Bersihkan',
                      isDestructive: true,
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache berhasil dibersihkan')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
