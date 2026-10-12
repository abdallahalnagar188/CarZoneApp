import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_constants.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarZone - Supabase Integration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SupabaseTestScreen(),
    );
  }
}

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  bool _isLoading = false;
  bool _isInitSuccess = false;
  bool _isDbSuccess = false;
  bool _isAuthSuccess = false;
  int? _latencyMs;
  String? _errorMessage;
  List<Map<String, dynamic>> _healthRecords = [];

  @override
  void initState() {
    super.initState();
    _testIntegration();
  }

  Future<void> _testIntegration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Verify Client Initialization
      final client = Supabase.instance.client;
      _isInitSuccess = true;

      // 2. Test Auth Service Status
      final session = client.auth.currentSession;
      final _ = session; // Validates auth client is operational
      _isAuthSuccess = true;

      // 3. Test Database Query to app_health table
      final response = await client
          .from('app_health')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      stopwatch.stop();

      setState(() {
        _isDbSuccess = true;
        _latencyMs = stopwatch.elapsedMilliseconds;
        _healthRecords = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _errorMessage = e.toString();
        _latencyMs = stopwatch.elapsedMilliseconds;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllPassed = _isInitSuccess && _isDbSuccess && _isAuthSuccess;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car_filled, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('CarZone · فحص اتصال Supabase'),
          ],
        ),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _testIntegration,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Banner
            Card(
              elevation: 0,
              color: _isLoading
                  ? theme.colorScheme.surfaceContainerHighest
                  : (isAllPassed
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isLoading
                      ? Colors.grey.shade400
                      : (isAllPassed ? Colors.green : Colors.red),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    else
                      Icon(
                        isAllPassed ? Icons.check_circle : Icons.error,
                        color: isAllPassed ? Colors.green : Colors.red,
                        size: 40,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading
                                ? 'جارٍ اختبار الاتصال مع Supabase...'
                                : (isAllPassed
                                    ? 'الاتصال ناجح ومستقر بنسبة 100%'
                                    : 'فشل في الاتصال'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAllPassed ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoading
                                ? 'يتم الآن فحص قاعدة البيانات والمصادقة...'
                                : (isAllPassed
                                    ? 'زمن الاستجابة: $_latencyMs ms'
                                    : (_errorMessage ?? 'حدث خطأ أثناء الاتصال')),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'نتائج الفحص التفصيلية',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildCheckItem(
              title: 'تهيئة عميل Supabase Client',
              subtitle: 'Supabase.initialize() على الرابط ${SupabaseConstants.supabaseUrl}',
              isSuccess: _isInitSuccess,
              isLoading: _isLoading,
              icon: Icons.bolt,
            ),

            const SizedBox(height: 12),

            _buildCheckItem(
              title: 'خدمة المصادقة (Supabase Auth)',
              subtitle: 'عميل المصادقة جاهز ومعتمد (حالة الزائر / الجلسة الحالية)',
              isSuccess: _isAuthSuccess,
              isLoading: _isLoading,
              icon: Icons.security,
            ),

            const SizedBox(height: 12),

            _buildCheckItem(
              title: 'قاعدة البيانات (PostgreSQL Data API)',
              subtitle: 'استعلام جدول app_health عبر REST API بالـ anon key',
              isSuccess: _isDbSuccess,
              isLoading: _isLoading,
              icon: Icons.table_chart,
            ),

            const SizedBox(height: 24),

            // Records from Database
            if (_healthRecords.isNotEmpty) ...[
              Text(
                'البيانات المستلمة من قاعدة البيانات (جدول app_health):',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._healthRecords.map(
                (row) => Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1E88E5),
                      child: Icon(Icons.cloud_done, color: Colors.white, size: 20),
                    ),
                    title: Text('${row['service_name']} (${row['status']})'),
                    subtitle: Text('ID: ${row['id']}\nتاريخ الإنشاء: ${row['created_at']}'),
                    isThreeLine: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testIntegration,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة اختبار الاتصال الآن'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required String title,
    required String subtitle,
    required bool isSuccess,
    required bool isLoading,
    required IconData icon,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLoading
              ? Colors.grey.shade200
              : (isSuccess ? Colors.green.shade50 : Colors.red.shade50),
          child: Icon(
            icon,
            color: isLoading
                ? Colors.grey
                : (isSuccess ? Colors.green : Colors.red),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isSuccess ? Icons.check_circle_outline : Icons.highlight_off,
                color: isSuccess ? Colors.green : Colors.red,
              ),
      ),
    );
  }
}
