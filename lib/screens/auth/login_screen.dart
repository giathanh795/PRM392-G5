import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _activeTab = 0;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _loginEmailController = TextEditingController(text: 'john.henry@liverpoolfc.com');
  final _loginPasswordController = TextEditingController(text: '123');

  final _regNameController = TextEditingController(text: 'John W. Henry');
  final _regEmailController = TextEditingController(text: 'john.henry@gmail.com');
  final _regPasswordController = TextEditingController(text: '123456');
  String _regRole = 'Principal Owner & Club Chairman';

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  Future<void> _handleEmailLogin() async {
    final email = _loginEmailController.text.trim();
    final pass = _loginPasswordController.text;

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ Email và Mật khẩu!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
      _navigateToMain();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final gmailController = TextEditingController(text: 'john.henry@gmail.com');

    final selectedGmail = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 10),
            const Text(
              'Đăng nhập với Google',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn hoặc nhập tài khoản Gmail để xác thực truy cập:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gmailController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ Gmail',
                prefixIcon: Icon(Icons.mail_outline),
                hintText: 'vidu@gmail.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(null),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(gmailController.text.trim()),
            child: const Text('Tiếp tục với Gmail'),
          ),
        ],
      ),
    );

    if (selectedGmail != null && selectedGmail.isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      final state = context.read<AppStateProvider>();
      final name = selectedGmail.split('@')[0];
      await state.loginWithGoogle(
        email: selectedGmail,
        fullName: name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : 'Google User',
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xác thực thành công qua tài khoản Google: $selectedGmail')),
        );
        _navigateToMain();
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final pass = _regPasswordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin đăng ký!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final state = context.read<AppStateProvider>();
    await state.registerAccount(
      fullName: name,
      email: email,
      password: pass,
      role: _regRole,
      department: 'Liverpool FC Executive Leadership',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chúc mừng $name đã tạo tài khoản quản lý thành công!')),
      );
      _navigateToMain();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.lfcRed.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.lfcRed.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/liverpool.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.sports_soccer,
                              size: 54,
                              color: AppTheme.lfcRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LIVERPOOL FC',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Executive & Club Ownership Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.subtextColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceNavyLight : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor(context)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 14, color: AppTheme.lfcYellow),
                          SizedBox(width: 6),
                          Text(
                            'Official Partner: adidas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lfcYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceNavy : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? AppTheme.lfcRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Đăng Nhập',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _activeTab == 0 ? Colors.white : AppTheme.subtextColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? AppTheme.lfcRed : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Đăng Ký Tài Khoản',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _activeTab == 1 ? Colors.white : AppTheme.subtextColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_activeTab == 0) ...[
                    TextField(
                      controller: _loginEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email / Gmail Ban Quản Trị',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _loginPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lfcRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Đăng Nhập Vào Hệ Thống LFC',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderColor(context))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'HOẶC TIẾP TỤC VỚI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtextColor(context)),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderColor(context))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.surfaceNavy : Colors.white,
                        foregroundColor: AppTheme.textColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: AppTheme.borderColor(context), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Đăng nhập với Google / Gmail',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_activeTab == 1) ...[
                    TextField(
                      controller: _regNameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và Tên',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _regEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Gmail / Email',
                        prefixIcon: Icon(Icons.alternate_email),
                        hintText: 'vidu@gmail.com',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _regPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu bảo mật',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _regRole,
                      decoration: const InputDecoration(
                        labelText: 'Chức danh / Vai trò',
                        prefixIcon: Icon(Icons.assignment_ind_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Principal Owner & Club Chairman',
                          child: Text('Chủ sở hữu & Chủ tịch CLB (Ông bầu)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Board Director & Executive',
                          child: Text('Thành viên Hội đồng Quản trị', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Sporting Director',
                          child: Text('Giám đốc Thể thao', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Commercial Manager',
                          child: Text('Giám đốc Khai thác Thương mại', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _regRole = val);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lfcRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Đăng Ký Tài Khoản & Vào Hệ Thống',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'You\'ll Never Walk Alone',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
