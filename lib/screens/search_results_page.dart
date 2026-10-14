// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Search results page.
///
/// Room-type cards with images, rates, amenities; filters (price, features);
/// sort by price.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';
import 'room_detail_page.dart';

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({
    super.key,
    required this.client,
    required this.propertyCode,
    required this.propertyName,
    required this.request,
    this.promoCode,
    this.metasearch,
  });

  final BffClient client;
  final String propertyCode;
  final String propertyName;
  final AvailabilityRequest request;
  final String? promoCode;

  /// Metasearch UTM attribution captured at the landing URL
  /// (ebooking/DESIGN.md §2) — threaded to the booking payload.
  final MetasearchContext? metasearch;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<SearchResult>> _future;
  List<SearchResult>? _allResults;
  final _filters = _SearchFilters();
  _SortOption _sort = _SortOption.recommended;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SearchResult>> _load() async {
    final avail = await widget.client.searchAvailability(
      widget.propertyCode,
      widget.request,
    );
    final results = <SearchResult>[];

    // Try to enrich with room-type detail/images in parallel.
    final roomTypes = <String, RoomType>{};
    try {
      final rtList = await widget.client.getRoomTypes(widget.propertyCode);
      for (final rt in rtList) {
        roomTypes[rt.roomTypeCode] = rt;
      }
    } catch (_) {
      // Non-fatal — show availability without enrichment.
    }

    for (final art in avail.roomTypes) {
      results.add(SearchResult(
        availability: art,
        roomTypeDetail: roomTypes[art.roomType],
        imageUrl: _imageForRoomType(art.roomType),
      ));
    }
    _allResults = results;
    return results;
  }

  String _imageForRoomType(String code) {
    const map = <String, String>{
      'KING': 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&h=500&fit=crop',
      'SUITE': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&h=500&fit=crop',
      'FAMILY': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&h=500&fit=crop',
      'QUEEN': 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&h=500&fit=crop',
    };
    return map[code.toUpperCase()] ??
        'https://images.unsplash.com/photo-1566073771259-6a8506098ce5?w=800&h=500&fit=crop';
  }

  List<SearchResult> get _filtered {
    var list = _allResults ?? [];
    if (_filters.maxPrice != null) {
      list = list.where((r) => r.lowestTotal <= _filters.maxPrice!).toList();
    }
    if (_filters.requiredFeatures.isNotEmpty) {
      list = list.where((r) {
        final features = r.roomTypeDetail?.features ?? const <String>[];
        return _filters.requiredFeatures.every((f) => features.contains(f));
      }).toList();
    }
    if (_filters.refundableOnly) {
      list = list.where((r) => r.availability.ratePlans.any((rp) =>
          (rp.restrictions == null || !rp.restrictions!.closedToArrival) &&
          rp.ratePlanName.toLowerCase().contains('breakfast'))).toList();
    }

    switch (_sort) {
      case _SortOption.priceLowHigh:
        list = List.from(list)..sort((a, b) => a.lowestTotal.compareTo(b.lowestTotal));
      case _SortOption.priceHighLow:
        list = List.from(list)..sort((a, b) => b.lowestTotal.compareTo(a.lowestTotal));
      case _SortOption.recommended:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter',
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date / guests bar ─────────────────────────────────────────
          _DateGuestBar(request: widget.request),
          // ── Sort chips ──────────────────────────────────────────────
          _SortBar(
            current: _sort,
            onChanged: (s) => setState(() => _sort = s),
          ),
          // ── Results list ────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _allResults = null;
                setState(() => _future = _load());
                await _future;
              },
              child: FutureBuilder<List<SearchResult>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorView(
                      error: snapshot.error!,
                      onRetry: () => setState(() => _future = _load()),
                    );
                  }
                  if (_allResults == null) return const SizedBox();
                  final list = _filtered;
                  if (list.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) => _RoomTypeCard(
                      result: list[i],
                      nights: _nights,
                      onSelect: () => _openDetail(list[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _nights {
    return widget.request.departureDate.difference(widget.request.arrivalDate).inDays;
  }

  void _openDetail(SearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomDetailPage(
          client: widget.client,
          propertyCode: widget.propertyCode,
          propertyName: widget.propertyName,
          result: result,
          request: widget.request,
          nights: _nights,
          promoCode: widget.promoCode,
          metasearch: widget.metasearch,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => _FilterSheet(
        filters: _filters,
        onChanged: () => setState(() {}),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Date / guests bar
// ═══════════════════════════════════════════════════════════════════════════

class _DateGuestBar extends StatelessWidget {
  const _DateGuestBar({required this.request});
  final AvailabilityRequest request;

  @override
  Widget build(BuildContext context) {
    final nights = request.departureDate.difference(request.arrivalDate).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, size: 18),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('MMM d').format(request.arrivalDate)} — ${DateFormat('MMM d').format(request.departureDate)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 8),
          Text('· $nights night${nights != 1 ? "s" : ""}', style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          const Icon(Icons.people_outline, size: 18),
          const SizedBox(width: 4),
          Text(
            '${request.numberOfAdults + request.numberOfChildren} guests · ${request.numberOfRooms} room${request.numberOfRooms != 1 ? "s" : ""}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sort bar
// ═══════════════════════════════════════════════════════════════════════════

enum _SortOption { recommended, priceLowHigh, priceHighLow }

class _SortBar extends StatelessWidget {
  const _SortBar({required this.current, required this.onChanged});
  final _SortOption current;
  final ValueChanged<_SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Sort by:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Recommended'), selected: current == _SortOption.recommended, onSelected: (_) => onChanged(_SortOption.recommended)),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Price ↑'), selected: current == _SortOption.priceLowHigh, onSelected: (_) => onChanged(_SortOption.priceLowHigh)),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Price ↓'), selected: current == _SortOption.priceHighLow, onSelected: (_) => onChanged(_SortOption.priceHighLow)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Room type card
// ═══════════════════════════════════════════════════════════════════════════

class _RoomTypeCard extends StatelessWidget {
  const _RoomTypeCard({required this.result, required this.nights, required this.onSelect});
  final SearchResult result;
  final int nights;
  final VoidCallback onSelect;

  String _money(double amt) {
    final fmt = NumberFormat.currency(name: result.currency, symbol: _symbolFor(result.currency));
    return fmt.format(amt);
  }

  @override
  Widget build(BuildContext context) {
    final rt = result.roomTypeDetail;
    final title = rt?.roomTypeName ?? result.availability.roomTypeDescription;
    final avail = result.availability.availableRooms;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              result.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.hotel, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600)),
                    ),
                    if (avail <= 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Only $avail left',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (rt?.bedType != null)
                  Text('${rt!.bedType} · Sleeps ${rt.maxOccupancy}',
                      style: Theme.of(context).textTheme.bodySmall),
                if (rt != null && rt.features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: rt.features.take(4).map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Starting from',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '${_money(result.lowestNightly)}/night',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        Text('${_money(result.lowestTotal)} total · $nights night${nights != 1 ? "s" : ""}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    FilledButton(onPressed: onSelect, child: const Text('Select Room')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _symbolFor(String code) {
  switch (code) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return '$code ';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Filter sheet
// ═══════════════════════════════════════════════════════════════════════════

class _SearchFilters {
  double? maxPrice;
  final Set<String> requiredFeatures = {};
  bool refundableOnly = false;
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filters, required this.onChanged});
  final _SearchFilters filters;
  final VoidCallback onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _allFeatures = <String>['WiFi', 'Ocean View', 'Balcony', 'King Bed', 'AC', 'Minibar'];

  @override
  Widget build(BuildContext context) {
    final f = widget.filters;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Max price (total)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Column(
              children: [
                Slider(
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  value: (f.maxPrice ?? 2000).clamp(100, 2000),
                  label: '\$${(f.maxPrice ?? 2000).round()}',
                  onChanged: (v) => setState(() => f.maxPrice = v >= 2000 ? null : v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('\$100'),
                    Text(f.maxPrice == null ? 'Any' : '\$${f.maxPrice!.round()}'),
                    const Text('\$2000+'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Room features', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allFeatures.map((feat) {
                final selected = f.requiredFeatures.contains(feat);
                return FilterChip(
                  label: Text(feat),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        f.requiredFeatures.add(feat);
                      } else {
                        f.requiredFeatures.remove(feat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Refundable rates only'),
              value: f.refundableOnly,
              onChanged: (v) => setState(() => f.refundableOnly = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      f.maxPrice = null;
                      f.requiredFeatures.clear();
                      f.refundableOnly = false;
                    });
                  },
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    widget.onChanged();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error / Empty
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is BffException ? (error as BffException).message : error.toString();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Unable to load results', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('No rooms available for the selected dates.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Try adjusting your dates or removing filters.',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}