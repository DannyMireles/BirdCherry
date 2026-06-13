import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'aviary_view.dart';
import 'bird_detail_screen.dart';

/// The species database: search, filter by rarity or region, browse all birds.
class BirdpediaScreen extends StatefulWidget {
  const BirdpediaScreen({super.key});

  @override
  State<BirdpediaScreen> createState() => _BirdpediaScreenState();
}

enum _PediaTab { aviary, guide }

class _BirdpediaScreenState extends State<BirdpediaScreen> {
  // Defaults to the aviary — your living collection greets you first.
  // (BC_START_GUIDE opens straight to the Guide for demos/screenshots.)
  _PediaTab _tab = const bool.fromEnvironment('BC_START_GUIDE')
      ? _PediaTab.guide
      : _PediaTab.aviary;
  String _query = '';
  Rarity? _rarity;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final collectedCount = app.lifeListOf(app.me.id).length;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Birdpedia', style: text.displayMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Text(
              _tab == _PediaTab.aviary
                  ? 'Your aviary · $collectedCount collected'
                  : app.catalogLoaded
                      ? 'Browse all ${_compact(app.catalogCount)} species · ${app.birds.length} featured'
                      : 'Loading the full guide…',
              style: text.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SegmentedToggle(
              tab: _tab,
              onChanged: (t) {
                Haptic.tick();
                setState(() => _tab = t);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _tab == _PediaTab.aviary
                ? const AviaryView()
                : _buildGuide(app, text),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide(AppState app, TextTheme text) {
    final searching = _query.trim().isNotEmpty;

    // Empty search → the WHOLE catalog (featured first, then every eBird
    // species), browsable in a lazy grid. Typing → search across all of it.
    List<Bird> birds = searching ? app.searchCatalog(_query) : app.catalogBrowse;
    if (_rarity != null) {
      birds = birds.where((b) => b.rarity == _rarity).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: app.catalogLoaded
                  ? 'Search all ${_compact(app.catalogCount)} species…'
                  : 'Search by name, family, or Latin…',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: BcColors.muted),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            scrollDirection: Axis.horizontal,
            children: [
              _chip('All', _rarity == null, () {
                setState(() => _rarity = null);
              }),
              const SizedBox(width: 8),
              for (final r in Rarity.values) ...[
                _chip(r.label, _rarity == r, () {
                  setState(() => _rarity = _rarity == r ? null : r);
                }, dot: rarityColor(r)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: birds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 40, color: BcColors.muted),
                      const SizedBox(height: 8),
                      Text('No birds match', style: text.titleMedium),
                      const SizedBox(height: 4),
                      Text('Try a different search or filter',
                          style: text.bodySmall),
                    ],
                  ),
                )
              : GridView.builder(
                  // Scrolling the grid dismisses the keyboard.
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: birds.length,
                  itemBuilder: (context, i) => _BirdGridCard(
                    bird: birds[i],
                    seen: app.seenByMe(birds[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  // 17400 -> "17,400"
  String _compact(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? dot}) {
    return ChoiceChip(
      avatar: dot == null
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: selected ? Colors.white : dot, shape: BoxShape.circle),
            ),
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        Haptic.tick();
        onTap();
      },
    );
  }
}

/// Pill toggle between the Aviary (your collection) and the Guide (database).
class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.tab, required this.onChanged});

  final _PediaTab tab;
  final ValueChanged<_PediaTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BcColors.cream,
        borderRadius: BorderRadius.circular(99),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segment(context, 'Aviary', _PediaTab.aviary),
          _segment(context, 'Guide', _PediaTab.guide),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, _PediaTab value) {
    final selected = tab == value;
    final fg = selected ? Colors.white : BcColors.inkSoft;
    final icon = value == _PediaTab.aviary
        ? BirdGlyph(size: 18, color: fg)
        : Icon(Icons.menu_book_rounded, size: 17, color: fg);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label tab',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? BcColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : BcColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BirdGridCard extends StatelessWidget {
  const _BirdGridCard({required this.bird, required this.seen});

  final Bird bird;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          '${bird.name}, ${bird.scientificName}, ${bird.rarity.label}${seen ? ', on your life list' : ''}',
      child: GestureDetector(
        onTap: () {
          Haptic.tap();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BirdDetailScreen(bird: bird)));
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'bird-image-${bird.id}',
                      child: BirdImage(bird: bird, borderRadius: BorderRadius.zero),
                    ),
                    if (seen)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: BcColors.leaf, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                child: Text(bird.name,
                    style: text.titleSmall?.copyWith(color: BcColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: rarityColor(bird.rarity),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(bird.rarity.label, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
