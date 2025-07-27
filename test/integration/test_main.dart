import 'package:flutter/material.dart';

void testMain() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirlineConnect Test',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: TestAuthScreen(),
      routes: {'/main': (context) => TestMainScreen()},
    );
  }
}

/// Simplified authentication screen for testing
class TestAuthScreen extends StatefulWidget {
  const TestAuthScreen({super.key});

  @override
  State createState() => _TestAuthScreenState();
}

class _TestAuthScreenState extends State<TestAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberNumberController = TextEditingController(text: 'AA123456');
  final _nameSuffixController = TextEditingController(text: '1234');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AirlineConnect'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('會員登入', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 32),

              // Member Number Field
              TextFormField(
                controller: _memberNumberController,
                decoration: InputDecoration(
                  labelText: '會員號碼',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '請輸入會員號碼';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Name Suffix Field
              TextFormField(
                controller: _nameSuffixController,
                decoration: InputDecoration(
                  labelText: '姓名末碼',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '請輸入姓名末碼';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('驗證中...'),
                          ],
                        )
                      : Text(
                          '登入驗證',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate authentication delay
    await Future.delayed(Duration(milliseconds: 500));

    final memberNumber = _memberNumberController.text.trim();
    final nameSuffix = _nameSuffixController.text.trim();

    // Demo credentials validation
    if (memberNumber == 'AA123456' && nameSuffix == '1234') {
      // Success - navigate to main screen
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Failure - show error
      setState(() {
        _errorMessage = '驗證失敗：會員號碼或姓名末碼不正確';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _memberNumberController.dispose();
    _nameSuffixController.dispose();
    super.dispose();
  }
}

/// Simplified main screen for testing
class TestMainScreen extends StatefulWidget {
  const TestMainScreen({super.key});

  @override
  State createState() => _TestMainScreenState();
}

class _TestMainScreenState extends State<TestMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AirlineConnect'),
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Boarding Pass Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.airplane_ticket, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text('登機證功能', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),

          // Scanner Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('掃描器功能', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),

          // Member Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('會員功能', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.airplane_ticket),
            label: '登機證',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: '掃描器',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '會員'),
        ],
      ),
    );
  }
}
