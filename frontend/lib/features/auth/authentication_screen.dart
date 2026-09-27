import 'package:flutter/material.dart';
import '../../core/theme/mausam_colors.dart';

/// Clean, reference-compliant Authentication Screen (Prompt Section 3 & design/references/authentication.md)
/// STRICT RULE: CREDENTIALS ONLY.
/// Answers: "WHO ARE YOU / CAN YOU AUTHENTICATE?"
/// Does NOT ask for any persona or role (no Dispatcher, RMC Manager, etc.).
class AuthenticationScreen extends StatefulWidget {
  final VoidCallback onBackToLanding;
  final void Function(String email, String password) onSignIn;
  final void Function(String name, String email, String password)? onSignUp;
  final VoidCallback? onGoogleSignIn;
  final String? errorMessage;
  final bool isLoading;

  const AuthenticationScreen({
    super.key,
    required this.onBackToLanding,
    required this.onSignIn,
    this.onSignUp,
    this.onGoogleSignIn,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'rmc.demo@mausam.local');
  final _passwordController = TextEditingController(text: 'RmcManager2026!');
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  int _carouselIndex = 0;

  final List<Map<String, String>> _showcaseSlides = [
    {
      'tag': 'MICROCLIMATE RADAR',
      'title': 'Weather Intelligence, Adapted to Your World',
      'body':
          'Continuous atmospheric modeling tracking localized precipitation fronts, thermal air masses, and wind dispersion before you move.',
    },
    {
      'tag': 'MULTI-CONTEXT ADAPTATION',
      'title': 'Decisions Scaled to Your Stakes',
      'body':
          'From personal wellness and family commute safety to highway travel, agriculture, and high-precision commercial operations.',
    },
    {
      'tag': 'PREDICTIVE ACTION ENGINE',
      'title': 'Turning Weather Into Calculated Action',
      'body':
          'Translate raw sensor telemetry and meteorological forecasting into clear, proactive operational decisions.',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isSignUp) {
        if (widget.onSignUp != null) {
          widget.onSignUp!(
            _nameController.text.trim().isEmpty ? 'Operations Lead' : _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        } else {
          widget.onSignIn(_emailController.text.trim(), _passwordController.text.trim());
        }
      } else {
        widget.onSignIn(_emailController.text.trim(), _passwordController.text.trim());
      }
    }
  }

  void _handleGoogleSignIn() {
    if (widget.onGoogleSignIn != null) {
      widget.onGoogleSignIn!();
    } else {
      widget.onSignIn('dispatcher@mausam.in', 'password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MausamColors.isDark(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F14), Color(0xFF111827), Color(0xFF0F172A)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2FE), Color(0xFFCCFBF1), Color(0xFFE6FFFA)],
          );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Clean Minimal Top Navigation Bar
              _buildTopNav(context),

              // Master Centered Rounded Card
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 960 : 440,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111820) : Colors.white,
                          borderRadius: BorderRadius.circular(28.0),
                          border: Border.all(
                            color: isDark ? const Color(0xFF27323D) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : const Color(0xFF0F172A).withValues(alpha: 0.08),
                              offset: const Offset(0, 12),
                              blurRadius: 36,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28.0),
                          child: isDesktop
                              ? IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Left: Form Column (~48%)
                                      Expanded(
                                        flex: 48,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
                                          child: _buildFormContent(context),
                                        ),
                                      ),
                                      // Right: Showcase Column (~52%)
                                      Expanded(
                                        flex: 52,
                                        child: _buildShowcaseColumn(context, isDark),
                                      ),
                                    ],
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(28.0),
                                  child: _buildFormContent(context),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: InkWell(
              onTap: widget.onBackToLanding,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'Back to Home',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'SECURE PLATFORM',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_queue, size: 18, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 10),
              const Text(
                'MAUSAM',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Headline & Instruction (Cashly typography)
          Text(
            _isSignUp ? 'Create Account' : 'Welcome back',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUp
                ? 'Enter your work credentials to register'
                : 'Enter your credentials to login',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner if authentication fails
          if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Name field if Sign Up
          if (_isSignUp) ...[
            _buildInputField(
              controller: _nameController,
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
          ],

          // Email Field (White rounded pill)
          _buildInputField(
            controller: _emailController,
            hintText: 'Work email',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
          ),
          const SizedBox(height: 14),

          // Password Field (White rounded pill with toggle)
          _buildInputField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF64748B),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Password is required' : null,
          ),

          // Forgot password link (Right-aligned)
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forget password?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Primary Solid Dark Pill Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // "or continue" Divider
          Row(
            children: [
              Expanded(child: Divider(color: const Color(0xFFE2E8F0), height: 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'or continue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(child: Divider(color: const Color(0xFFE2E8F0), height: 1)),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary "Log in with Google" Pill Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _handleGoogleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4285F4),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Log in with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Footer toggle between Sign In and Sign Up
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _isSignUp ? 'Already have an account ? ' : "Don't have an account ? ",
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildShowcaseColumn(BuildContext context, bool isDark) {
    final slide = _showcaseSlides[_carouselIndex];

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Brand Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  slide['tag'] ?? 'ENVIRONMENTAL INTELLIGENCE',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(Icons.shield_outlined, size: 16, color: Colors.white.withValues(alpha: 0.6)),
            ],
          ),

          // Middle: Abstract Environmental Intelligence Product Visual
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Abstract concentric radar pulse / environmental decision ring
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.waves, size: 28, color: Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'MAUSAM ENVIRONMENTAL DECISION SYSTEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Predictive environmental modeling & automated operational risk evaluation across 7 distinct domains.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Slide Narrative & Pagination Carousel
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide['title']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                slide['body']!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // 3-Dot Carousel Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _showcaseSlides.length,
                  (index) => GestureDetector(
                    onTap: () => setState(() => _carouselIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _carouselIndex == index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _carouselIndex == index ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
