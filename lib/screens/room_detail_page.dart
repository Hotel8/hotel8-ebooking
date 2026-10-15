// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Room detail page.
///
/// Image gallery, description, amenities, rate plan comparison, package
/// add-ons, live price summary, "Book Now" button.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';
import 'guest_checkout_page.dart';
import 'member_checkout_page.dart';

// CheckoutData is defined in ../models.dart and re-exported here for
// convenience — the checkout & confirmation pages import it from models.

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({
    super.key,
    required this.client,
    required this.propertyCode,
    required this.propertyName,
    required this.result,
    required this.request,
    required this.nights,
    this.promoCode,
    this.metasearch,
    this.isMember = false,
  });

  final BffClient client;
  final String propertyCode;
  final String propertyName;
  final SearchResult result;
  final AvailabilityRequest request;
  final int nights;
  final String? promoCode;

  /// Metasearch UTM attribution (ebooking/DESIGN.md §2) threaded to booking.
  final MetasearchContext? metasearch;
  final bool isMember;

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final _gallery = <String>[];
  final _selectedPackages = <Package>{};
  AvailableRatePlan? _selectedRate;
  List<Package>? _availablePackages;
  bool _loadingPackages = true;

  static const _galleryImages = <String>[
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=900&h=600&fit=crop',
    'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=900&h=600&fit=crop',
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900&h=600&fit=crop',
    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=900&h=600&fit=crop',
  ];

  @override
  void initState() {
    super.initState();
    _gallery.addAll(_galleryImages);
    if (widget.result.availability.ratePlans.isNotEmpty) {
      _selectedRate = widget.result.availability.ratePlans.first;
    }
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final pkgs = await widget.client.getPackages(widget.propertyCode);
      setState(() {
        _availablePackages = pkgs;
        _loadingPackages = false;
      });
    } catch (_) {
      // Fall back to default add-ons.
      setState(() {
        _availablePackages = const [
          Package(
              packageCode: 'BREAKFAST',
              packageName: 'Breakfast',
              price: 30,
              perStay: false),
          Package(
              packageCode: 'PARKING',
              packageName: 'Parking',
              price: 25,
              perStay: false),
          Package(
              packageCode: 'SPA',
              packageName: 'Spa Credit',
              price: 50,
              perStay: true),
          Package(
              packageCode: 'AIRPORT',
              packageName: 'Airport Transfer',
              price: 60,
              perStay: true),
        ];
        _loadingPackages = false;
      });
    }
  }

  double get _packageTotal {
    double sum = 0;
    for (final p in _selectedPackages) {
      sum += p.perStay ? p.price : p.price * widget.nights;
    }
    return sum;
  }

  double get _totalAmount => (_selectedRate?.totalAmount ?? 0) + _packageTotal;

  String get _currency => _selectedRate?.currencyCode ?? widget.result.currency;

  String _money(double amt) {
    final fmt =
        NumberFormat.currency(name: _currency, symbol: _symbolFor(_currency));
    return fmt.format(amt);
  }

  @override
  Widget build(BuildContext context) {
    final rt = widget.result.roomTypeDetail;
    final title =
        rt?.roomTypeName ?? widget.result.availability.roomTypeDescription;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title),
              background: _gallery.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer)
                  : Image.network(_gallery.first, fit: BoxFit.cover),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Image gallery ────────────────────────────────────────────
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gallery.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_gallery[i],
                      width: 160, height: 120, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Room overview ────────────────────────────────────────────
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            if (rt != null)
              Wrap(
                spacing: 16,
                children: [
                  _spec(Icons.bed, rt.bedType ?? 'Standard bed'),
                  _spec(Icons.people, 'Sleeps ${rt.maxOccupancy}'),
                  _spec(Icons.smoke_free,
                      rt.isSmoking ? 'Smoking' : 'Non-smoking'),
                ],
              ),
            const SizedBox(height: 16),
            if (rt?.description != null ||
                widget.result.availability.roomTypeDescription.isNotEmpty)
              Text(
                rt?.description ??
                    widget.result.availability.roomTypeDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 16),

            // ── Amenities ────────────────────────────────────────────────
            if (rt != null && rt.features.isNotEmpty) ...[
              Text('Amenities',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rt.features
                    .map((f) => Chip(
                          avatar: const Icon(Icons.check, size: 16),
                          label: Text(f),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── Rate plan comparison ────────────────────────────────────
            Text('Rate Plans',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.result.availability.ratePlans.map((rp) => _RatePlanTile(
                  rate: rp,
                  nights: widget.nights,
                  selected: _selectedRate == rp,
                  onSelect: () => setState(() => _selectedRate = rp),
                )),
            const SizedBox(height: 24),

            // ── Package add-ons ──────────────────────────────────────────
            Text('Add-ons & Packages',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loadingPackages)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ..._availablePackages!.map((p) => _PackageTile(
                    package: p,
                    nights: widget.nights,
                    selected: _selectedPackages.contains(p),
                    onToggle: () => setState(() {
                      if (_selectedPackages.contains(p)) {
                        _selectedPackages.remove(p);
                      } else {
                        _selectedPackages.add(p);
                      }
                    }),
                  )),
            const SizedBox(height: 24),

            // ── Price summary ────────────────────────────────────────────
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_selectedRate != null) ...[
                      _PriceRow(
                        label:
                            'Room rate · ${widget.nights} night${widget.nights != 1 ? "s" : ""}',
                        value: _money(_selectedRate!.totalAmount),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ..._selectedPackages.map((p) => _PriceRow(
                          label:
                              '${p.packageName} ${p.perStay ? "(per stay)" : "(${widget.nights}×)"}',
                          value: _money(
                              p.perStay ? p.price : p.price * widget.nights),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total (excl. taxes)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(_money(_totalAmount),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Book button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _selectedRate == null ? null : _proceedToCheckout,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Book Now'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  void _proceedToCheckout() {
    if (_selectedRate == null) return;
    final checkout = CheckoutData(
      propertyName: widget.propertyName,
      propertyCode: widget.propertyCode,
      request: widget.request,
      nights: widget.nights,
      roomTypeName: widget.result.roomTypeDetail?.roomTypeName ??
          widget.result.availability.roomTypeDescription,
      roomTypeCode: widget.result.roomTypeDetail?.roomTypeCode ??
          widget.result.availability.roomType,
      roomTypeId: widget.result.roomTypeDetail?.id ??
          widget.result.availability.roomType,
      ratePlan: _selectedRate!,
      packages: _selectedPackages.toList(),
      promoCode: widget.promoCode,
      metasearch: widget.metasearch,
      totalAmount: _totalAmount,
      currency: _currency,
    );
    final page = widget.isMember
        ? MemberCheckoutPage(client: widget.client, data: checkout)
        : GuestCheckoutPage(client: widget.client, data: checkout);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Rate plan tile
// ═══════════════════════════════════════════════════════════════════════════

class _RatePlanTile extends StatelessWidget {
  const _RatePlanTile({
    required this.rate,
    required this.nights,
    required this.selected,
    required this.onSelect,
  });

  final AvailableRatePlan rate;
  final int nights;
  final bool selected;
  final VoidCallback onSelect;

  String get _sym => _symbolFor(rate.currencyCode);
  String _money(double amt) => '$_sym${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final isNonRefundable =
        rate.restrictions != null && rate.restrictions!.minLos > 7;
    return Card(
      color: selected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rate.ratePlanName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_money(rate.averageNightlyRate)}/night',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('Total ${_money(rate.totalAmount)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                        isNonRefundable ? 'Non-refundable' : 'Free cancel 48h'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(isNonRefundable ? 'Pay now' : 'Pay at hotel'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Package tile
// ═══════════════════════════════════════════════════════════════════════════

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.nights,
    required this.selected,
    required this.onToggle,
  });

  final Package package;
  final int nights;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cost = package.perStay ? package.price : package.price * nights;
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onToggle(),
      title: Text(package.packageName),
      subtitle: Text(package.perStay
          ? '\$${package.price.toStringAsFixed(0)} per stay'
          : '\$${package.price.toStringAsFixed(0)}/night (\$${cost.toStringAsFixed(0)} total)'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
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
