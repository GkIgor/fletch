import 'package:flutter/material.dart';
import 'package:fletch/models/http_auth.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';
import 'package:provider/provider.dart';

class HttpAuthEditor extends StatefulWidget {
  final HttpAuth initialAuth;
  final void Function(HttpAuth) onChanged;
  final bool showInheritOption;
  final String? inheritedFromName;
  final HttpAuth? resolvedInheritedAuth;

  const HttpAuthEditor({
    super.key,
    required this.initialAuth,
    required this.onChanged,
    this.showInheritOption = true,
    this.inheritedFromName,
    this.resolvedInheritedAuth,
  });

  @override
  State<HttpAuthEditor> createState() => _HttpAuthEditorState();
}

class _HttpAuthEditorState extends State<HttpAuthEditor> {
  late final InterpolatedTextController _apiKeyKeyController;
  late final InterpolatedTextController _apiKeyValueController;
  late String _apiKeyAddTo;

  late final InterpolatedTextController _bearerTokenController;

  late final InterpolatedTextController _basicUsernameController;
  late final InterpolatedTextController _basicPasswordController;

  late final InterpolatedTextController _oauth1ConsumerKeyController;
  late final InterpolatedTextController _oauth1ConsumerSecretController;
  late final InterpolatedTextController _oauth1TokenController;
  late final InterpolatedTextController _oauth1TokenSecretController;
  late String _oauth1SignatureMethod;

  late final InterpolatedTextController _oauth2AccessTokenController;
  late final InterpolatedTextController _oauth2TokenUrlController;
  late final InterpolatedTextController _oauth2ClientIdController;
  late final InterpolatedTextController _oauth2ClientSecretController;
  late final InterpolatedTextController _oauth2ScopeController;
  late String _oauth2GrantType;
  late final InterpolatedTextController _oauth2UsernameController;
  late final InterpolatedTextController _oauth2PasswordController;

  bool _isOauthFetching = false;
  bool _isUpdatingControllers = false;

  @override
  void initState() {
    super.initState();

    _apiKeyKeyController = InterpolatedTextController();
    _apiKeyValueController = InterpolatedTextController();
    _bearerTokenController = InterpolatedTextController();
    _basicUsernameController = InterpolatedTextController();
    _basicPasswordController = InterpolatedTextController();
    _oauth1ConsumerKeyController = InterpolatedTextController();
    _oauth1ConsumerSecretController = InterpolatedTextController();
    _oauth1TokenController = InterpolatedTextController();
    _oauth1TokenSecretController = InterpolatedTextController();
    _oauth2AccessTokenController = InterpolatedTextController();
    _oauth2TokenUrlController = InterpolatedTextController();
    _oauth2ClientIdController = InterpolatedTextController();
    _oauth2ClientSecretController = InterpolatedTextController();
    _oauth2ScopeController = InterpolatedTextController();
    _oauth2UsernameController = InterpolatedTextController();
    _oauth2PasswordController = InterpolatedTextController();

    _updateControllers(widget.initialAuth);
  }

  @override
  void didUpdateWidget(HttpAuthEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAuth != oldWidget.initialAuth) {
      _updateControllers(widget.initialAuth);
    }
  }

  void _updateControllers(HttpAuth auth) {
    _isUpdatingControllers = true;
    _apiKeyKeyController.text = auth.apiKeyKey;
    _apiKeyValueController.text = auth.apiKeyValue;
    _apiKeyAddTo = auth.apiKeyAddTo;

    _bearerTokenController.text = auth.bearerToken;

    _basicUsernameController.text = auth.basicUsername;
    _basicPasswordController.text = auth.basicPassword;

    _oauth1ConsumerKeyController.text = auth.oauth1ConsumerKey;
    _oauth1ConsumerSecretController.text = auth.oauth1ConsumerSecret;
    _oauth1TokenController.text = auth.oauth1Token;
    _oauth1TokenSecretController.text = auth.oauth1TokenSecret;
    _oauth1SignatureMethod = auth.oauth1SignatureMethod;

    _oauth2AccessTokenController.text = auth.oauth2AccessToken;
    _oauth2TokenUrlController.text = auth.oauth2TokenUrl;
    _oauth2ClientIdController.text = auth.oauth2ClientId;
    _oauth2ClientSecretController.text = auth.oauth2ClientSecret;
    _oauth2ScopeController.text = auth.oauth2Scope;
    _oauth2GrantType = auth.oauth2GrantType;
    _oauth2UsernameController.text = auth.oauth2Username;
    _oauth2PasswordController.text = auth.oauth2Password;
    _isUpdatingControllers = false;
  }

  @override
  void dispose() {
    _apiKeyKeyController.dispose();
    _apiKeyValueController.dispose();
    _bearerTokenController.dispose();
    _basicUsernameController.dispose();
    _basicPasswordController.dispose();
    _oauth1ConsumerKeyController.dispose();
    _oauth1ConsumerSecretController.dispose();
    _oauth1TokenController.dispose();
    _oauth1TokenSecretController.dispose();
    _oauth2AccessTokenController.dispose();
    _oauth2TokenUrlController.dispose();
    _oauth2ClientIdController.dispose();
    _oauth2ClientSecretController.dispose();
    _oauth2ScopeController.dispose();
    _oauth2UsernameController.dispose();
    _oauth2PasswordController.dispose();
    super.dispose();
  }

  void _saveAuth({AuthType? overrideType}) {
    if (_isUpdatingControllers) return;

    final updatedAuth = HttpAuth(
      type: overrideType ?? widget.initialAuth.type,
      apiKeyKey: _apiKeyKeyController.text,
      apiKeyValue: _apiKeyValueController.text,
      apiKeyAddTo: _apiKeyAddTo,
      bearerToken: _bearerTokenController.text,
      basicUsername: _basicUsernameController.text,
      basicPassword: _basicPasswordController.text,
      oauth1ConsumerKey: _oauth1ConsumerKeyController.text,
      oauth1ConsumerSecret: _oauth1ConsumerSecretController.text,
      oauth1Token: _oauth1TokenController.text,
      oauth1TokenSecret: _oauth1TokenSecretController.text,
      oauth1SignatureMethod: _oauth1SignatureMethod,
      oauth2AccessToken: _oauth2AccessTokenController.text,
      oauth2TokenUrl: _oauth2TokenUrlController.text,
      oauth2ClientId: _oauth2ClientIdController.text,
      oauth2ClientSecret: _oauth2ClientSecretController.text,
      oauth2Scope: _oauth2ScopeController.text,
      oauth2GrantType: _oauth2GrantType,
      oauth2Username: _oauth2UsernameController.text,
      oauth2Password: _oauth2PasswordController.text,
    );

    widget.onChanged(updatedAuth);
  }

  Future<void> _fetchOAuth2Token() async {
    setState(() => _isOauthFetching = true);

    final requestProvider = Provider.of<RequestProvider>(context, listen: false);
    final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
    final activeEnv = wsProvider.activeEnvironment;
    final Map<String, String> variables = activeEnv?.variables.map((k, v) => MapEntry(k, v.value)) ?? {};

    try {
      final token = await requestProvider.fetchOAuth2Token(
        tokenUrl: _oauth2TokenUrlController.text,
        grantType: _oauth2GrantType,
        clientId: _oauth2ClientIdController.text,
        clientSecret: _oauth2ClientSecretController.text,
        scope: _oauth2ScopeController.text,
        username: _oauth2UsernameController.text,
        password: _oauth2PasswordController.text,
        variables: variables,
      );

      if (token != null) {
        setState(() {
          _oauth2AccessTokenController.text = token;
        });
        _saveAuth();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Token retrieved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Token response was empty or did not contain access_token');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retrieve token: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOauthFetching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Type: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<AuthType>(
                initialValue: widget.initialAuth.type,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.slate900.withValues(alpha: 0.4) : AppColors.slate100.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                ),
                items: [
                  if (widget.showInheritOption)
                    const DropdownMenuItem(value: AuthType.inherit, child: Text('Inherit from parent', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.none, child: Text('No Auth', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.apiKey, child: Text('API Key', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.bearer, child: Text('Bearer Token', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.basic, child: Text('Basic Auth', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.oauth1, child: Text('OAuth 1.0', style: TextStyle(fontSize: 13))),
                  const DropdownMenuItem(value: AuthType.oauth2, child: Text('OAuth 2.0', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (AuthType? value) {
                  if (value != null) {
                    _saveAuth(overrideType: value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildAuthForm(widget.initialAuth.type, isDark),
      ],
    );
  }

  Widget _buildAuthForm(AuthType type, bool isDark) {
    switch (type) {
      case AuthType.inherit:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Inheriting Authentication',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'This item inherits credentials from: ${widget.inheritedFromName ?? "Workspace"}.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'RESOLVED PREVIEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              _buildResolvedAuthPreview(widget.resolvedInheritedAuth, isDark),
            ],
          ),
        );
      case AuthType.apiKey:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Key',
              controller: _apiKeyKeyController,
              hint: 'e.g. X-API-Key',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Value',
              controller: _apiKeyValueController,
              hint: 'Value',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Add to',
              value: _apiKeyAddTo,
              items: const [
                DropdownMenuItem(value: 'header', child: Text('Headers', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'query', child: Text('Query Params', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _apiKeyAddTo = val);
                  _saveAuth();
                }
              },
              isDark: isDark,
            ),
          ],
        );
      case AuthType.bearer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Token',
              controller: _bearerTokenController,
              hint: 'Bearer token value',
              maxLines: 3,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
          ],
        );
      case AuthType.basic:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Username',
              controller: _basicUsernameController,
              hint: 'Username',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Password',
              controller: _basicPasswordController,
              hint: 'Password',
              obscureText: true,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
          ],
        );
      case AuthType.oauth1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Consumer Key',
              controller: _oauth1ConsumerKeyController,
              hint: 'Consumer Key',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Consumer Secret',
              controller: _oauth1ConsumerSecretController,
              hint: 'Consumer Secret',
              obscureText: true,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Token',
              controller: _oauth1TokenController,
              hint: 'Token',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Token Secret',
              controller: _oauth1TokenSecretController,
              hint: 'Token Secret',
              obscureText: true,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Signature Method',
              value: _oauth1SignatureMethod,
              items: const [
                DropdownMenuItem(value: 'HMAC-SHA1', child: Text('HMAC-SHA1', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'HMAC-SHA256', child: Text('HMAC-SHA256', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'PLAINTEXT', child: Text('PLAINTEXT', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _oauth1SignatureMethod = val);
                  _saveAuth();
                }
              },
              isDark: isDark,
            ),
          ],
        );
      case AuthType.oauth2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Access Token',
              controller: _oauth2AccessTokenController,
              hint: 'Access Token',
              maxLines: 2,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Text(
              'Get New Access Token',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in details below to fetch an access token automatically.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Grant Type',
              value: _oauth2GrantType,
              items: const [
                DropdownMenuItem(value: 'client_credentials', child: Text('Client Credentials', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'password', child: Text('Password Credentials', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _oauth2GrantType = val);
                  _saveAuth();
                }
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Token URL',
              controller: _oauth2TokenUrlController,
              hint: 'https://api.example.com/oauth/token',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Client ID',
              controller: _oauth2ClientIdController,
              hint: 'Client ID',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Client Secret',
              controller: _oauth2ClientSecretController,
              hint: 'Client Secret',
              obscureText: true,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Scope (Optional)',
              controller: _oauth2ScopeController,
              hint: 'read write',
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            if (_oauth2GrantType == 'password') ...[
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Username',
                controller: _oauth2UsernameController,
                hint: 'Username',
                onChanged: (_) => _saveAuth(),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Password',
                controller: _oauth2PasswordController,
                hint: 'Password',
                obscureText: true,
                onChanged: (_) => _saveAuth(),
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isOauthFetching ? null : _fetchOAuth2Token,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isOauthFetching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Get New Access Token',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        );
      case AuthType.none:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_person_rounded,
                  size: 40,
                  color: isDark ? AppColors.textSecondaryDark.withValues(alpha: 0.5) : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Authentication',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No authentication protocol configured.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildResolvedAuthPreview(HttpAuth? auth, bool isDark) {
    if (auth == null || auth.type == AuthType.none || auth.type == AuthType.inherit) {
      return Text(
        'No active authentication inherited.',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      );
    }

    final keyStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : Colors.black87,
    );

    final valueStyle = TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    switch (auth.type) {
      case AuthType.apiKey:
        return Table(
          columnWidths: const {0: FixedColumnWidth(100), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [Text('Type:', style: keyStyle), Text('API Key', style: valueStyle)]),
            TableRow(children: [Text('Key:', style: keyStyle), Text(auth.apiKeyKey, style: valueStyle)]),
            TableRow(children: [Text('Value:', style: keyStyle), Text(auth.apiKeyValue.isNotEmpty ? '••••••••' : '(Empty)', style: valueStyle)]),
            TableRow(children: [Text('Add to:', style: keyStyle), Text(auth.apiKeyAddTo == 'query' ? 'Query Parameters' : 'Headers', style: valueStyle)]),
          ],
        );
      case AuthType.bearer:
        return Table(
          columnWidths: const {0: FixedColumnWidth(100), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [Text('Type:', style: keyStyle), Text('Bearer Token', style: valueStyle)]),
            TableRow(children: [Text('Token:', style: keyStyle), Text(auth.bearerToken.isNotEmpty ? '••••••••' : '(Empty)', style: valueStyle)]),
          ],
        );
      case AuthType.basic:
        return Table(
          columnWidths: const {0: FixedColumnWidth(100), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [Text('Type:', style: keyStyle), Text('Basic Auth', style: valueStyle)]),
            TableRow(children: [Text('Username:', style: keyStyle), Text(auth.basicUsername.isNotEmpty ? auth.basicUsername : '(Empty)', style: valueStyle)]),
            TableRow(children: [Text('Password:', style: keyStyle), Text(auth.basicPassword.isNotEmpty ? '••••••••' : '(Empty)', style: valueStyle)]),
          ],
        );
      case AuthType.oauth1:
        return Table(
          columnWidths: const {0: FixedColumnWidth(120), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [Text('Type:', style: keyStyle), Text('OAuth 1.0', style: valueStyle)]),
            TableRow(children: [Text('Consumer Key:', style: keyStyle), Text(auth.oauth1ConsumerKey.isNotEmpty ? auth.oauth1ConsumerKey : '(Empty)', style: valueStyle)]),
            TableRow(children: [Text('Signature:', style: keyStyle), Text(auth.oauth1SignatureMethod, style: valueStyle)]),
          ],
        );
      case AuthType.oauth2:
        return Table(
          columnWidths: const {0: FixedColumnWidth(120), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [Text('Type:', style: keyStyle), Text('OAuth 2.0', style: valueStyle)]),
            TableRow(children: [Text('Access Token:', style: keyStyle), Text(auth.oauth2AccessToken.isNotEmpty ? '••••••••' : '(Empty)', style: valueStyle)]),
            TableRow(children: [Text('Grant Type:', style: keyStyle), Text(auth.oauth2GrantType, style: valueStyle)]),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField({
    required String label,
    required InterpolatedTextController controller,
    required String hint,
    required void Function(String) onChanged,
    required bool isDark,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppColors.slate500.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: isDark ? AppColors.slate900.withValues(alpha: 0.4) : AppColors.slate100.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.slate900.withValues(alpha: 0.4) : AppColors.slate100.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
