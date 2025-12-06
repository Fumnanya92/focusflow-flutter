import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/challenge_provider.dart';

class PhoneDownSetupScreen extends StatefulWidget {
  const PhoneDownSetupScreen({super.key});

  @override
  State<PhoneDownSetupScreen> createState() => _PhoneDownSetupScreenState();
}

class _PhoneDownSetupScreenState extends State<PhoneDownSetupScreen> {
  int _selectedDuration = 10; // minutes
  final List<TextEditingController> _participantControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addParticipantField() {
    setState(() {
      _participantControllers.add(TextEditingController());
    });
  }

  Future<void> _createChallenge() async {
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    
    // Create challenge
    await challengeProvider.createChallenge(
      'Phone-Down Challenge',
      _selectedDuration,
    );

    // Add participants
    for (var controller in _participantControllers) {
      if (controller.text.trim().isNotEmpty) {
        await challengeProvider.addParticipant(controller.text.trim());
      }
    }

    if (mounted) {
      context.go('/challenge-active');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone-Down Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Create a Challenge',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'See who can stay phone-free the longest!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Duration Section
                    Text(
                      'Challenge Duration',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),

                    // Duration Display
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLarge),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha((0.3 * 255).round()),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_selectedDuration',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'minutes',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMedium),

                    // Duration Presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DurationButton(
                          label: '5 min',
                          value: 5,
                          isSelected: _selectedDuration == 5,
                          onTap: () {
                            setState(() {
                              _selectedDuration = 5;
                            });
                          },
                        ),
                        _DurationButton(
                          label: '10 min',
                          value: 10,
                          isSelected: _selectedDuration == 10,
                          onTap: () {
                            setState(() {
                              _selectedDuration = 10;
                            });
                          },
                        ),
                        _DurationButton(
                          label: '30 min',
                          value: 30,
                          isSelected: _selectedDuration == 30,
                          onTap: () {
                            setState(() {
                              _selectedDuration = 30;
                            });
                          },
                        ),
                        _DurationButton(
                          label: '60 min',
                          value: 60,
                          isSelected: _selectedDuration == 60,
                          onTap: () {
                            setState(() {
                              _selectedDuration = 60;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceXLarge),

                    // Participants Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participants',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton.icon(
                          onPressed: _addParticipantField,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),

                    // Participant Fields
                    ..._participantControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: 'Participant ${index + 1} name',
                                  prefixIcon: const Icon(Icons.person),
                                ),
                              ),
                            ),
                            if (_participantControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () {
                                  setState(() {
                                    _participantControllers.removeAt(index);
                                  });
                                },
                                color: AppTheme.error,
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppTheme.spaceMedium),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          Expanded(
                            child: Text(
                              'Place your phones face down. If anyone picks up their phone, they\'re out!',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createChallenge,
                  child: const Text('Start Challenge'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.backgroundDark : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
