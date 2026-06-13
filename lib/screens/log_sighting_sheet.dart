import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/seed.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Opens the two-step "log a bird" flow. Optionally preselects a species
/// (e.g. when launched from a bird's detail page).
Future<void> showLogSightingSheet(BuildContext context, {Bird? preselected}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _LogSheet(preselected: preselected),
  );
}

class _LogSheet extends StatefulWidget {
  const _LogSheet({this.preselected});

  final Bird? preselected;

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  Bird? _bird;
  String _query = '';
  int _placeIndex = 0;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bird = widget.preselected;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      // Tap anywhere outside a field to dismiss the keyboard.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: _bird == null ? _buildSpeciesPicker() : _buildDetails(),
        ),
      ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Step 1 — pick the species.
  // -------------------------------------------------------------------
  Widget _buildSpeciesPicker() {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    // Empty → featured birds; typing → search the entire eBird catalog.
    final birds = _query.trim().isEmpty
        ? (List<Bird>.of(app.birds)..sort((a, b) => a.name.compareTo(b.name)))
        : app.searchCatalog(_query);

    return Column(
      key: const ValueKey('picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: BcColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
          child: Text('Who did you spot?', style: text.displaySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Pick a species to log your sighting', style: text.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: app.catalogLoaded
                  ? 'Search all ${app.catalogCount} species…'
                  : 'Search birds…',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: BcColors.muted),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            itemCount: birds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final bird = birds[i];
              final seen = app.seenByMe(bird.id);
              return Semantics(
                button: true,
                label: 'Select ${bird.name}, ${bird.rarity.label}, '
                    '${bird.points} points${seen ? '' : ', would be a lifer'}',
                child: GestureDetector(
                  onTap: () {
                    Haptic.confirm();
                    setState(() => _bird = bird);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          BirdImage(bird: bird, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bird.name, style: text.titleMedium),
                                const SizedBox(height: 1),
                                Text(bird.family, style: text.bodySmall),
                              ],
                            ),
                          ),
                          if (!seen)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: BcColors.gold.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('LIFER',
                                  style: text.labelSmall
                                      ?.copyWith(color: BcColors.gold)),
                            ),
                          Text('+${bird.points}',
                              style: text.titleMedium
                                  ?.copyWith(color: BcColors.cherry)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Step 2 — where, when, notes.
  // -------------------------------------------------------------------
  Widget _buildDetails() {
    final text = Theme.of(context).textTheme;
    final bird = _bird!;

    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: BcColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
          child: Row(
            children: [
              if (widget.preselected == null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Change species',
                  onPressed: () {
                    Haptic.tick();
                    setState(() => _bird = null);
                  },
                ),
              const SizedBox(width: 4),
              BirdImage(bird: bird, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bird.name, style: text.headlineSmall),
                    RarityChip(rarity: bird.rarity, compact: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            children: [
              Text('WHERE WAS IT?', style: text.labelSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < Seed.hotspots.length; i++)
                    ChoiceChip(
                      label: Text(Seed.hotspots[i].$1),
                      selected: _placeIndex == i,
                      onSelected: (_) {
                        Haptic.tick();
                        setState(() => _placeIndex = i);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('FIELD NOTES (OPTIONAL)', style: text.labelSmall),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Singing from a high branch, gorgeous light…',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BcColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: BcColors.inkSoft),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Logged for right now at the chosen spot. GPS and photo '
                        'capture arrive with the camera update.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: BcColors.cherry),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text('Log sighting · +${bird.points} pts'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final app = context.read<AppState>();
    final (place, point) = Seed.hotspots[_placeIndex];
    final reward = await app.logSighting(
      bird: _bird!,
      point: point,
      place: place,
      note: _noteController.text,
    );
    if (!mounted) return;
    Haptic.celebrate();
    // Capture the navigator before popping: the sheet's own context dies
    // with the pop, but the navigator's context lives on for the dialog.
    final navigator = Navigator.of(context);
    navigator.pop();
    showDialog<void>(
      context: navigator.context,
      builder: (_) => _CelebrationDialog(reward: reward),
    );
  }
}

/// The reward moment: points, lifer status, and any badges just unlocked.
class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.reward});

  final LogReward reward;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: BcColors.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BirdImage(
                bird: reward.bird,
                size: 96,
                borderRadius: BorderRadius.circular(48),
              ),
              const SizedBox(height: 16),
              if (reward.isLifer)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: BcColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('✦ LIFER — first time ever!',
                      style: text.labelMedium?.copyWith(color: BcColors.gold)),
                ),
              Text(reward.bird.name,
                  style: text.displaySmall, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('+${reward.points} points',
                  style: text.headlineSmall?.copyWith(color: BcColors.cherry)),
              if (reward.newBadges.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 14),
                Text('BADGE${reward.newBadges.length > 1 ? 'S' : ''} UNLOCKED',
                    style: text.labelSmall),
                const SizedBox(height: 10),
                for (final b in reward.newBadges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(b.icon, size: 20, color: BcColors.leaf),
                        const SizedBox(width: 8),
                        Text(b.name, style: text.titleMedium),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Haptic.tick();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Keep birding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
