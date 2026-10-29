// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Home / Landing page.
///
/// Hero image, search bar (dates, guests, promo code), property highlights.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';
import 'search_results_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.client,
    this.propertyCode = 'DEMO',
    this.propertyName = 'The Grand Hotel',
  });

  final BffClient client;
  final String propertyCode;
  final String propertyName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  final _promoController = TextEditingController();
  PromoCodeResult? _promoResult;

  final _highlights = const <_Highlight>[
    _Highlight(icon: Icons.pool, label: 'Pool & Spa'),
    _Highlight(icon: Icons.restaurant, label: 'Fine Dining'),
    _Highlight(icon: Icons.fitness_center, label: 'Fitness Centre'),
    _Highlight(icon: Icons.wifi, label: 'Free Wi-Fi'),
    _Highlight(icon: Icons.local_parking, label: 'Valet Parking'),
    _Highlight(icon: Icons.beach_access, label: 'Ocean View'),
  ];

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckIn() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      _checkIn = date;
      if (_checkOut != null &&
          _checkOut!.isBefore(date.add(const Duration(days: 1)))) {
        _checkOut = date.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickCheckOut() async {
    final first = _checkIn?.add(const Duration(days: 1)) ??
        DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() => _checkOut = date);
  }

  void _doSearch() {
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select check-in and check-out dates.')),
      );
      return;
    }
    final request = AvailabilityRequest(
      arrivalDate: _checkIn!,
      departureDate: _checkOut!,
      numberOfAdults: _adults,
      numberOfChildren: _children,
      numberOfRooms: _rooms,
      promoCode:
          _promoController.text.isEmpty ? null : _promoController.text.trim(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          client: widget.client,
          propertyCode: widget.propertyCode,
          propertyName: widget.propertyName,
          request: request,
          promoCode: request.promoCode,
        ),
      ),
    );
  }

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoResult = null);
      return;
    }
    try {
      final result =
          await widget.client.validatePromoCode(widget.propertyCode, code);
      setState(() => _promoResult = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.valid
                ? 'Promo code applied${result.discountPercent != null ? ' (${result.discountPercent}% off)' : ''}'
                : 'Invalid promo code'),
          ),
        );
      }
    } on BffException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo validation failed: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Hero(
              propertyName: widget.propertyName,
              child: _SearchBar(
                checkIn: _checkIn,
                checkOut: _checkOut,
                adults: _adults,
                children: _children,
                rooms: _rooms,
                promoController: _promoController,
                promoResult: _promoResult,
                onPickCheckIn: _pickCheckIn,
                onPickCheckOut: _pickCheckOut,
                onAdults: (v) => setState(() => _adults = v),
                onChildren: (v) => setState(() => _children = v),
                onRooms: (v) => setState(() => _rooms = v),
                onValidatePromo: _validatePromo,
                onSearch: _doSearch,
              ),
            ),
          ),

          // ── Highlights ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Property Highlights',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate(
                _highlights.map((h) => _HighlightChip(h)).toList(),
              ),
            ),
          ),

          // ── Featured rooms ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Featured Rooms',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _featuredRooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) =>
                    _FeaturedRoomCard(_featuredRooms[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Hero
// ═══════════════════════════════════════════════════════════════════════════

class _Hero extends StatelessWidget {
  const _Hero({required this.propertyName, required this.child});

  final String propertyName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1566073771259-6a8506098ce5?w=1200&h=600&fit=crop',
          height: 380,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 380,
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        Container(
          height: 380,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.55)
              ],
            ),
          ),
        ),
        Positioned(
          top: 56,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                propertyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Book your perfect stay - best rate guaranteed',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: child,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search bar
// ═══════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.promoController,
    required this.promoResult,
    required this.onPickCheckIn,
    required this.onPickCheckOut,
    required this.onAdults,
    required this.onChildren,
    required this.onRooms,
    required this.onValidatePromo,
    required this.onSearch,
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final int rooms;
  final TextEditingController promoController;
  final PromoCodeResult? promoResult;
  final VoidCallback onPickCheckIn;
  final VoidCallback onPickCheckOut;
  final ValueChanged<int> onAdults;
  final ValueChanged<int> onChildren;
  final ValueChanged<int> onRooms;
  final VoidCallback onValidatePromo;
  final VoidCallback onSearch;

  static String _fmt(DateTime? d) =>
      d == null ? 'Add date' : DateFormat('MMM d').format(d);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Check-in',
                    value: _fmt(checkIn),
                    onTap: onPickCheckIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Check-out',
                    value: _fmt(checkOut),
                    onTap: onPickCheckOut,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Counter(
                      label: 'Adults',
                      value: adults,
                      min: 1,
                      max: 10,
                      onChanged: onAdults),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Counter(
                      label: 'Children',
                      value: children,
                      min: 0,
                      max: 10,
                      onChanged: onChildren),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Counter(
                      label: 'Rooms',
                      value: rooms,
                      min: 1,
                      max: 5,
                      onChanged: onRooms),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promoController,
              decoration: InputDecoration(
                labelText: 'Promo / Corporate code',
                prefixIcon: const Icon(Icons.local_offer_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Validate',
                  onPressed: onValidatePromo,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: promoResult != null && !promoResult!.valid
                    ? 'Invalid code'
                    : null,
              ),
              onEditingComplete: onValidatePromo,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search Availability'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(value, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            visualDensity: VisualDensity.compact,
          ),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Highlights
// ═══════════════════════════════════════════════════════════════════════════

class _Highlight {
  final IconData icon;
  final String label;
  const _Highlight({required this.icon, required this.label});
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip(this.h);
  final _Highlight h;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(h.icon,
                size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(h.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Featured rooms (static placeholder content)
// ═══════════════════════════════════════════════════════════════════════════

class _FeaturedRoom {
  final String name;
  final String from;
  final String image;
  const _FeaturedRoom(
      {required this.name, required this.from, required this.image});
}

const _featuredRooms = <_FeaturedRoom>[
  _FeaturedRoom(
    name: 'Deluxe King',
    from: 'from \$199/night',
    image:
        'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop',
  ),
  _FeaturedRoom(
    name: 'Ocean Suite',
    from: 'from \$349/night',
    image:
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&h=400&fit=crop',
  ),
  _FeaturedRoom(
    name: 'Family Room',
    from: 'from \$249/night',
    image:
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=600&h=400&fit=crop',
  ),
  _FeaturedRoom(
    name: 'Executive Queen',
    from: 'from \$179/night',
    image:
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600&h=400&fit=crop',
  ),
];

class _FeaturedRoomCard extends StatelessWidget {
  const _FeaturedRoomCard(this.room);
  final _FeaturedRoom room;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                room.image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(room.from, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
