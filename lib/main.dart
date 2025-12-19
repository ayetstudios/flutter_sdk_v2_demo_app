import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayet_sdk_v2/ayet_sdk_v2.dart';

import 'ayet_config.dart';

// ==================== Colors ====================

class AyetColors {
  static const Color navy = Color(0xFF233649);
  static const Color orange = Color(0xFFF58F00);
  static const Color purple = Color(0xFF635DFF);

  // Light theme
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F2F5);

  // Dark theme
  static const Color primaryDark = Color(0xFF8B9CAD);
  static const Color secondaryDark = Color(0xFFFFB74D);
  static const Color tertiaryDark = Color(0xFF9C98FF);
  static const Color backgroundDark = Color(0xFF121820);
  static const Color surfaceDark = Color(0xFF1E2530);
  static const Color surfaceVariantDark = Color(0xFF2A3441);
}

// ==================== Theme ====================

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AyetColors.navy,
      secondary: AyetColors.orange,
      tertiary: AyetColors.purple,
      surface: AyetColors.surfaceLight,
      surfaceContainerHighest: AyetColors.surfaceVariantLight,
    ),
    scaffoldBackgroundColor: AyetColors.backgroundLight,
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AyetColors.primaryDark,
      secondary: AyetColors.secondaryDark,
      tertiary: AyetColors.tertiaryDark,
      surface: AyetColors.surfaceDark,
      surfaceContainerHighest: AyetColors.surfaceVariantDark,
    ),
    scaffoldBackgroundColor: AyetColors.backgroundDark,
  );
}

// ==================== Main App ====================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayet SDK Demo',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: const AyetDemoApp(),
    );
  }
}

class AyetDemoApp extends StatefulWidget {
  const AyetDemoApp({super.key});

  @override
  State<AyetDemoApp> createState() => _AyetDemoAppState();
}

class _AyetDemoAppState extends State<AyetDemoApp> {
  final _ayetSdk = AyetSdkV2();
  String _externalId = '';
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExternalId();
  }

  Future<void> _loadExternalId() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('external_id');

    if (savedId == null) {
      savedId = 'user_${Random().nextInt(900000) + 100000}';
      await prefs.setString('external_id', savedId);
    }

    setState(() {
      _externalId = savedId!;
      _isLoading = false;
    });

    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    if (_isInitialized) return;

    await _ayetSdk.setDebug(true);
    await _ayetSdk.setFullscreenMode(true);
    await _ayetSdk.init(
      placementId: AyetConfig.placementId,
      externalIdentifier: _externalId,
    );
    await _ayetSdk.setGender(AyetConfig.defaultGender);
    await _ayetSdk.setAge(AyetConfig.defaultAge);
    await _ayetSdk.setTrackingCustom1(AyetConfig.defaultCustom1);

    _isInitialized = true;
  }

  Future<void> _updateExternalId(String newId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('external_id', newId);

    setState(() {
      _externalId = newId;
    });

    // Re-initialize SDK with new ID
    await _ayetSdk.init(
      placementId: AyetConfig.placementId,
      externalIdentifier: newId,
    );
    await _ayetSdk.setGender(AyetConfig.defaultGender);
    await _ayetSdk.setAge(AyetConfig.defaultAge);
    await _ayetSdk.setTrackingCustom1(AyetConfig.defaultCustom1);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('External ID updated')));
    }
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: _externalId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit External ID',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The SDK will be re-initialized with the new identifier.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'External Identifier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newId = controller.text.trim();
              if (newId.isNotEmpty) {
                Navigator.pop(context);
                _updateExternalId(newId);
              }
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              _HeaderSection(),

              const SizedBox(height: 24),

              // External ID Card
              _ExternalIdCard(
                externalId: _externalId,
                onEditTap: _showEditDialog,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ActionButton(
                      text: 'Show Offerwall',
                      icon: Icons.list,
                      color: AyetColors.orange,
                      onTap: () =>
                          _ayetSdk.showOfferwall(AyetConfig.adslotOfferwall),
                    ),
                    const SizedBox(height: 16),
                    _ActionButton(
                      text: 'Show Surveywall',
                      icon: Icons.check_circle,
                      color: AyetColors.purple,
                      onTap: () =>
                          _ayetSdk.showSurveywall(AyetConfig.adslotSurveywall),
                    ),
                    const SizedBox(height: 16),
                    _ActionButton(
                      text: 'Reward Status',
                      icon: Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => _ayetSdk.showRewardStatus(),
                    ),
                    const SizedBox(height: 24),
                    _GetOffersButton(ayetSdk: _ayetSdk),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Footer Info
              _FooterInfo(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Widgets ====================

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(204),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 140,
              height: 70,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'SDK Demo',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalIdCard extends StatelessWidget {
  final String externalId;
  final VoidCallback onEditTap;

  const _ExternalIdCard({required this.externalId, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'External Identifier',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      externalId,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditTap,
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GetOffersButton extends StatefulWidget {
  final AyetSdkV2 ayetSdk;

  const _GetOffersButton({required this.ayetSdk});

  @override
  State<_GetOffersButton> createState() => _GetOffersButtonState();
}

class _GetOffersButtonState extends State<_GetOffersButton> {
  bool _isLoading = false;

  Future<void> _getOffers() async {
    setState(() => _isLoading = true);

    try {
      final offersJson = await widget.ayetSdk.getOffers(AyetConfig.adslotFeed);

      if (!mounted) return;

      if (offersJson != null) {
        debugPrint('Offers received: $offersJson');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offers received! Check debug console for details'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to get offers')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getOffers,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const Text(
                  'Loading...',
                  key: ValueKey('loading'),
                  style: TextStyle(fontWeight: FontWeight.w500),
                )
              : const Text(
                  'Get Offers (API)',
                  key: ValueKey('idle'),
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
        ),
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final genderText = switch (AyetConfig.defaultGender) {
      AyetGender.male => 'Male',
      AyetGender.female => 'Female',
      AyetGender.nonBinary => 'Non-Binary',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Gender: $genderText • Age: ${AyetConfig.defaultAge}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
