import 'package:apapane/models/story/story_generation_config.dart';
import 'package:flutter/material.dart';

class StorySetupSheet extends StatefulWidget {
  const StorySetupSheet({
    super.key,
    required this.initialMode,
    required this.initialOptions,
    required this.onPreview,
  });

  final StoryMode initialMode;
  final StoryOptions initialOptions;
  final Future<void> Function(StoryMode mode, StoryOptions options) onPreview;

  @override
  State<StorySetupSheet> createState() => _StorySetupSheetState();
}

class _StorySetupSheetState extends State<StorySetupSheet> {
  late StoryMode _mode;
  late StoryTone _tone;
  late StoryEndingStyle _endingStyle;
  late StoryWorldType _worldType;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _tone = widget.initialOptions.tone;
    _endingStyle = widget.initialOptions.endingStyle;
    _worldType = widget.initialOptions.worldType;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'どんな長さにする？',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...StoryMode.values.map(_buildModeCard),
            const SizedBox(height: 14),
            const Text(
              'おはなしの味つけ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildChoiceRow<StoryTone>(
              values: StoryTone.values,
              selected: _tone,
              label: (value) => value.label,
              onSelected: (value) => setState(() => _tone = value),
            ),
            const SizedBox(height: 8),
            _buildChoiceRow<StoryEndingStyle>(
              values: StoryEndingStyle.values,
              selected: _endingStyle,
              label: (value) => value.label,
              onSelected: (value) => setState(() => _endingStyle = value),
            ),
            const SizedBox(height: 8),
            _buildChoiceRow<StoryWorldType>(
              values: StoryWorldType.values,
              selected: _worldType,
              label: (value) => value.label,
              onSelected: (value) => setState(() => _worldType = value),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_stories),
                label: const Text('あらすじを作る'),
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.onPreview(
                    _mode,
                    StoryOptions(
                      tone: _tone,
                      endingStyle: _endingStyle,
                      worldType: _worldType,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(StoryMode mode) {
    final selected = mode == _mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _mode = mode),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F6EC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? const Color(0xFF2E9D57) : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF2E9D57) : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (mode.isRecommended) ...[
                          const SizedBox(width: 8),
                          const _Badge(text: 'おすすめ'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${mode.pageCount}ページ / ${mode.coinCost}コイン'),
                    Text(mode.shortDescription),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceRow<T>({
    required List<T> values,
    required T selected,
    required String Function(T value) label,
    required ValueChanged<T> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(label(value)),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF2E9D57),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
