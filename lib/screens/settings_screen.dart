import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/appointments_controller.dart';
import '../services/github_sync_service.dart';
import '../services/storage_service.dart';
import '../services/wifi_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  final _tokenCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: 'appointments_backup.json');

  final _ssidCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSyncingWifi = false;
  bool _isUploading = false;
  bool _isDownloading = false;
  bool _obscureToken = true;
  bool _obscureWifiPassword = true;
  bool _rememberWifi = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadWifiSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.loadSyncSettings();
    setState(() {
      _tokenCtrl.text = settings['token'] ?? '';
      _ownerCtrl.text = settings['owner'] ?? '';
      _repoCtrl.text = settings['repo'] ?? '';
      _pathCtrl.text = settings['path'] ?? 'appointments_backup.json';
    });
  }

  Future<void> _loadWifiSettings() async {
    final wifi = await _storage.loadWifiCredentials();
    if (!mounted) return;
    setState(() {
      _ssidCtrl.text = wifi['ssid'] ?? '';
      _passwordCtrl.text = wifi['password'] ?? '';
    });
  }

  Future<void> _persistSettings() async {
    await _storage.saveSyncSettings(
      token: _tokenCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      repo: _repoCtrl.text.trim(),
      path: _pathCtrl.text.trim(),
    );
  }

  GitHubSyncService? _buildService() {
    if (_tokenCtrl.text.trim().isEmpty ||
        _ownerCtrl.text.trim().isEmpty ||
        _repoCtrl.text.trim().isEmpty ||
        _pathCtrl.text.trim().isEmpty) {
      _showSnack('נא למלא את כל שדות הסנכרון (טוקן, בעלים, ריפו, נתיב)');
      return null;
    }
    return GitHubSyncService(
      token: _tokenCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      repo: _repoCtrl.text.trim(),
      path: _pathCtrl.text.trim(),
    );
  }

  Future<void> _upload() async {
    final service = _buildService();
    if (service == null) return;
    await _persistSettings();

    setState(() => _isUploading = true);
    try {
      final appointments = context.read<AppointmentsController>().appointments;
      await service.uploadAppointments(appointments);
      _showSnack('הגיבוי הועלה בהצלחה ל-GitHub ✓');
    } catch (e) {
      _showSnack('שגיאה בגיבוי: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _download() async {
    final service = _buildService();
    if (service == null) return;
    await _persistSettings();

    setState(() => _isDownloading = true);
    try {
      final remote = await service.downloadAppointments();
      if (!mounted) return;
      await context.read<AppointmentsController>().mergeFromRemote(remote);
      _showSnack('שוחזרו ${remote.length} תורים מ-GitHub ✓');
    } catch (e) {
      _showSnack('שגיאה בשחזור: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _connectWifi() async {
    setState(() => _isSyncingWifi = true);
    final connected = await WifiService.connectAndSync(
      ssid: _ssidCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (_rememberWifi) {
      await _storage.saveWifiCredentials(
        ssid: _ssidCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } else {
      await _storage.clearWifiCredentials();
    }
    if (mounted) {
      setState(() => _isSyncingWifi = false);
      _showSnack(connected ? 'החיבור לרשת הצליח' : 'שגיאה בחיבור לרשת');
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _ownerCtrl.dispose();
    _repoCtrl.dispose();
    _pathCtrl.dispose();
    _ssidCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות וסנכרון')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'גיבוי ושחזור ב-GitHub',
            icon: Icons.cloud_sync_outlined,
            children: [
              const Text(
                'שומר עותק של כל התורים בקובץ JSON בריפו פרטי משלכם. '
                'מומלץ להשתמש בריפו Private ובטוקן עם הרשאת repo בלבד.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenCtrl,
                obscureText: _obscureToken,
                decoration: InputDecoration(
                  labelText: 'Personal Access Token',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureToken
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureToken = !_obscureToken),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ownerCtrl,
                decoration: const InputDecoration(labelText: 'בעל הריפו (Username)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _repoCtrl,
                decoration: const InputDecoration(labelText: 'שם הריפו'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pathCtrl,
                decoration: const InputDecoration(labelText: 'נתיב קובץ הגיבוי'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : _download,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_download_outlined),
                      label: const Text('שחזור'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _upload,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('גיבוי כעת'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'חיבור לרשת Wi-Fi של הסטודיו',
            icon: Icons.wifi,
            children: [
              TextField(
                controller: _ssidCtrl,
                decoration: const InputDecoration(labelText: 'שם רשת (SSID)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscureWifiPassword,
                decoration: InputDecoration(
                  labelText: 'סיסמת רשת',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureWifiPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(
                        () => _obscureWifiPassword = !_obscureWifiPassword),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _rememberWifi,
                onChanged: (value) =>
                    setState(() => _rememberWifi = value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: const Text('זכור פרטי רשת זו במכשיר'),
                subtitle: const Text(
                  'נשמר מקומית בלבד, כדי שלא תצטרכו להזין שוב בפעם הבאה',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncingWifi ? null : _connectWifi,
                      icon: _isSyncingWifi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('התחבר לרשת'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'שכח פרטי רשת שמורים',
                    onPressed: () async {
                      await _storage.clearWifiCredentials();
                      if (!mounted) return;
                      setState(() {
                        _ssidCtrl.clear();
                        _passwordCtrl.clear();
                        _rememberWifi = false;
                      });
                      _showSnack('פרטי הרשת השמורים נמחקו');
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
