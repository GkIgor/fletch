import 'package:flutter/material.dart';
import 'package:fletch/models/http_method.dart';
import 'package:fletch/models/http_request.dart';
import 'package:fletch/providers/request_provider.dart';
import 'package:fletch/theme/app_colors.dart';
import 'package:fletch/widgets/key_value_editor.dart';
import 'package:fletch/widgets/body_editor.dart';
import 'package:fletch/widgets/response_viewer.dart';
import 'package:fletch/widgets/interpolated_text_controller.dart';
import 'package:fletch/providers/workspace_provider.dart';
import 'package:provider/provider.dart';
import 'package:fletch/models/http_auth.dart';

class RequestEditor extends StatefulWidget {
  final HttpRequest request;

  const RequestEditor({super.key, required this.request});

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor>
    with SingleTickerProviderStateMixin {
  late InterpolatedTextController _urlController;
  late TabController _tabController;
  late HttpMethod _method;
  bool _isFavorite = false;

  // Auth text controllers
  late TextEditingController _apiKeyKeyController;
  late TextEditingController _apiKeyValueController;
  late TextEditingController _bearerTokenController;
  late TextEditingController _basicUsernameController;
  late TextEditingController _basicPasswordController;
  late TextEditingController _oauth1ConsumerKeyController;
  late TextEditingController _oauth1ConsumerSecretController;
  late TextEditingController _oauth1TokenController;
  late TextEditingController _oauth1TokenSecretController;
  late TextEditingController _oauth2AccessTokenController;
  late TextEditingController _oauth2TokenUrlController;
  late TextEditingController _oauth2ClientIdController;
  late TextEditingController _oauth2ClientSecretController;
  late TextEditingController _oauth2ScopeController;
  late TextEditingController _oauth2UsernameController;
  late TextEditingController _oauth2PasswordController;

  // Visual options
  String _apiKeyAddTo = 'header';
  String _oauth1SignatureMethod = 'HMAC-SHA1';
  String _oauth2GrantType = 'client_credentials';
  bool _isPasswordVisible = false;
  bool _isOauthFetching = false;

  @override
  void initState() {
    super.initState();
    _urlController = InterpolatedTextController(text: widget.request.url);
    _method = widget.request.method;
    _tabController = TabController(length: 4, vsync: this);

    final auth = widget.request.auth;
    _apiKeyKeyController = TextEditingController(text: auth.apiKeyKey);
    _apiKeyValueController = TextEditingController(text: auth.apiKeyValue);
    _bearerTokenController = TextEditingController(text: auth.bearerToken);
    _basicUsernameController = TextEditingController(text: auth.basicUsername);
    _basicPasswordController = TextEditingController(text: auth.basicPassword);
    _oauth1ConsumerKeyController = TextEditingController(text: auth.oauth1ConsumerKey);
    _oauth1ConsumerSecretController = TextEditingController(text: auth.oauth1ConsumerSecret);
    _oauth1TokenController = TextEditingController(text: auth.oauth1Token);
    _oauth1TokenSecretController = TextEditingController(text: auth.oauth1TokenSecret);
    _oauth2AccessTokenController = TextEditingController(text: auth.oauth2AccessToken);
    _oauth2TokenUrlController = TextEditingController(text: auth.oauth2TokenUrl);
    _oauth2ClientIdController = TextEditingController(text: auth.oauth2ClientId);
    _oauth2ClientSecretController = TextEditingController(text: auth.oauth2ClientSecret);
    _oauth2ScopeController = TextEditingController(text: auth.oauth2Scope);
    _oauth2UsernameController = TextEditingController(text: auth.oauth2Username);
    _oauth2PasswordController = TextEditingController(text: auth.oauth2Password);

    _apiKeyAddTo = auth.apiKeyAddTo;
    _oauth1SignatureMethod = auth.oauth1SignatureMethod;
    _oauth2GrantType = auth.oauth2GrantType;
  }

  @override
  void didUpdateWidget(RequestEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _urlController.text = widget.request.url;
      _method = widget.request.method;

      final auth = widget.request.auth;
      _updateAuthControllers(auth);
      _apiKeyAddTo = auth.apiKeyAddTo;
      _oauth1SignatureMethod = auth.oauth1SignatureMethod;
      _oauth2GrantType = auth.oauth2GrantType;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();

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

  void _updateAuthControllers(HttpAuth auth) {
    _apiKeyKeyController.text = auth.apiKeyKey;
    _apiKeyValueController.text = auth.apiKeyValue;
    _bearerTokenController.text = auth.bearerToken;
    _basicUsernameController.text = auth.basicUsername;
    _basicPasswordController.text = auth.basicPassword;
    _oauth1ConsumerKeyController.text = auth.oauth1ConsumerKey;
    _oauth1ConsumerSecretController.text = auth.oauth1ConsumerSecret;
    _oauth1TokenController.text = auth.oauth1Token;
    _oauth1TokenSecretController.text = auth.oauth1TokenSecret;
    _oauth2AccessTokenController.text = auth.oauth2AccessToken;
    _oauth2TokenUrlController.text = auth.oauth2TokenUrl;
    _oauth2ClientIdController.text = auth.oauth2ClientId;
    _oauth2ClientSecretController.text = auth.oauth2ClientSecret;
    _oauth2ScopeController.text = auth.oauth2Scope;
    _oauth2UsernameController.text = auth.oauth2Username;
    _oauth2PasswordController.text = auth.oauth2Password;
  }

  void _onSave({
    Map<String, String>? params,
    Map<String, String>? headers,
    String? body,
    BodyType? bodyType,
    HttpAuth? auth,
  }) {
    final updatedRequest = widget.request.copyWith(
      url: _urlController.text,
      method: _method,
      queryParams: params ?? widget.request.queryParams,
      headers: headers ?? widget.request.headers,
      body: body ?? widget.request.body,
      bodyType: bodyType ?? widget.request.bodyType,
      auth: auth ?? widget.request.auth,
    );
    Provider.of<RequestProvider>(
      context,
      listen: false,
    ).updateSelectedRequest(updatedRequest);
  }

  void _saveAuth() {
    final auth = widget.request.auth.copyWith(
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
    _onSave(auth: auth);
  }

  Future<void> _fetchOAuth2Token(RequestProvider requestProvider) async {
    setState(() => _isOauthFetching = true);

    // Get active variables for interpolation in fetch call
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required void Function(String) onChanged,
    required bool isDark,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
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
                color: AppColors.slate400.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              isDense: true,
              suffixIcon: suffixIcon,
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
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthTab(bool isDark) {
    final auth = widget.request.auth;
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
              Container(
                width: 180,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AuthType>(
                    value: auth.type,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    items: const [
                      DropdownMenuItem(value: AuthType.none, child: Text('No Auth', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: AuthType.apiKey, child: Text('API Key', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: AuthType.bearer, child: Text('Bearer Token', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: AuthType.basic, child: Text('Basic Auth', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: AuthType.oauth1, child: Text('OAuth 1.0', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: AuthType.oauth2, child: Text('OAuth 2.0', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (AuthType? value) {
                      if (value != null) {
                        final updatedAuth = widget.request.auth.copyWith(type: value);
                        _onSave(auth: updatedAuth);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          _buildAuthForm(auth, requestProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildAuthForm(HttpAuth auth, RequestProvider requestProvider, bool isDark) {
    switch (auth.type) {
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
              obscureText: !_isPasswordVisible,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.slate400,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
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
              label: 'Access Token',
              controller: _oauth1TokenController,
              hint: 'Access Token',
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
              hint: 'Access Token value (or fetch using credentials below)',
              maxLines: 3,
              onChanged: (_) => _saveAuth(),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Text(
              'Configure Token Fetching',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill the parameters below to request a new token from your authorization server.',
              style: TextStyle(
                fontSize: 12,
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
              label: 'Access Token URL',
              controller: _oauth2TokenUrlController,
              hint: 'e.g. https://auth.example.com/oauth/token',
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
              label: 'Scope',
              controller: _oauth2ScopeController,
              hint: 'Scope (optional)',
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
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isOauthFetching ? null : () => _fetchOAuth2Token(requestProvider),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No Authentication required for this request.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildResponsePanel(RequestProvider requestProvider, bool isDark) {
    if (requestProvider.isLoading) {
      return Container(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sending Request...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (requestProvider.currentResponse != null) {
      return ResponseViewer(response: requestProvider.currentResponse!);
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestProvider = Provider.of<RequestProvider>(context);

    final activeHeadersCount = widget.request.headers.entries
        .where((e) => e.key.trim().isNotEmpty && e.value.trim().isNotEmpty)
        .length;

    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Action Bar: [URL BAR] [SEND] [SAVE]
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Row(
                  children: [
                    // URL Bar (Expanded)
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Method Selector
                            Container(
                              width: isNarrow ? 75 : 90,
                              padding: EdgeInsets.only(left: isNarrow ? 8 : 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<HttpMethod>(
                                  value: _method,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                                  dropdownColor: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  items: HttpMethod.values.map((method) {
                                    return DropdownMenuItem(
                                      value: method,
                                      child: Text(
                                        method.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _getMethodColor(method),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _method = value);
                                      _onSave();
                                    }
                                  },
                                ),
                              ),
                            ),

                            VerticalDivider(
                              width: 24,
                              thickness: 1,
                              indent: 12,
                              endIndent: 12,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),

                            // URL Input
                            Expanded(
                              child: TextField(
                                controller: _urlController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'https://api.example.com/v1/resource',
                                  hintStyle: TextStyle(
                                    color: AppColors.slate400.withValues(alpha: 0.5),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                ),
                                onChanged: (_) => _onSave(),
                              ),
                            ),

                            // Favorite Icon
                            IconButton(
                              onPressed: () {
                                setState(() => _isFavorite = !_isFavorite);
                              },
                              icon: Icon(
                                _isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 20,
                                color: _isFavorite
                                    ? Colors.amber
                                    : AppColors.slate400,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Send Button
                    ElevatedButton(
                      onPressed: () {
                        _onSave();
                        final currentReq = Provider.of<RequestProvider>(
                          context,
                          listen: false,
                        ).selectedRequest;
                        if (currentReq != null) {
                          final wsProvider = Provider.of<WorkspaceProvider>(context, listen: false);
                          final activeEnv = wsProvider.activeEnvironment;
                          final Map<String, String> variables = activeEnv?.variables.map((k, v) => MapEntry(k, v.value)) ?? {};

                          Provider.of<RequestProvider>(
                            context,
                            listen: false,
                          ).executeRequest(currentReq, variables: variables);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 20),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: isNarrow
                          ? const Icon(Icons.send_rounded, size: 16)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.send_rounded, size: 16),
                              ],
                            ),
                    ),

                    const SizedBox(width: 4),

                    // Save Button
                    IconButton(
                      onPressed: () => _onSave(),
                      icon: Icon(
                        Icons.save_outlined,
                        size: 22,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      tooltip: 'Save',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(46, 46),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(
            height: 1,
            thickness: 1,
          ),

          // Split Content (Left = Request tabs/editors, Right = Response)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left side: Request Configuration
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tabs
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.slate500,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          tabs: [
                            const Tab(text: 'Query'),
                            Tab(
                              text:
                                  'Headers${activeHeadersCount > 0 ? " $activeHeadersCount" : ""}',
                            ),
                            const Tab(text: 'Auth'),
                            const Tab(text: 'Body'),
                          ],
                        ),
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                      ),

                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            KeyValueEditor(
                              key: ValueKey('params_${widget.request.id}'),
                              initialValues: widget.request.queryParams,
                              onChanged: (params) => _onSave(params: params),
                              keyHint: 'Parameter',
                            ),
                            KeyValueEditor(
                              key: ValueKey('headers_${widget.request.id}'),
                              initialValues: widget.request.headers,
                              onChanged: (headers) => _onSave(headers: headers),
                              keyHint: 'Header',
                            ),
                            _buildAuthTab(isDark),
                            BodyEditor(
                              key: ValueKey('body_${widget.request.id}'),
                              request: widget.request,
                              onChanged: (updatedRequest) {
                                Provider.of<RequestProvider>(
                                  context,
                                  listen: false,
                                ).updateSelectedRequest(updatedRequest);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side: Response Panel (if active or has response)
                if (requestProvider.isLoading ||
                    requestProvider.currentResponse != null) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildResponsePanel(requestProvider, isDark),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return AppColors.methodGet;
      case HttpMethod.post:
        return AppColors.methodPost;
      case HttpMethod.put:
        return AppColors.methodPut;
      case HttpMethod.delete:
        return AppColors.methodDelete;
      case HttpMethod.patch:
        return AppColors.methodPatch;
    }
  }
}
