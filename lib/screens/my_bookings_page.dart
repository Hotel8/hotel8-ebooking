// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// My Bookings.
///
/// Upcoming / past reservations, modify / cancel.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({
    super.key,
    required this.client,
    this.propertyCode = 'DEMO',
    this.guestProfileId,
  });

  final BffClient client;
  final String propertyCode;
  final String? guestProfileId;

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Reservation>> _future;
  List<Reservation>? _all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Reservation>> _load() async {
    final list = await widget.client.getReservations(
      propertyId: widget.propertyCode,
      guestProfileId: widget.guestProfileId,
    );
    _all = list;
    return list;
  }

  List<Reservation> get _upcoming =>
      _all
          ?.where((r) =>
              r.status.isUpcoming &&
              r.arrivalDate
                  .isAfter(DateTime.now().subtract(const Duration(days: 1))))
          .toList() ??
      const [];

  List<Reservation> get _past =>
      _all
          ?.where((r) =>
              !r.status.isUpcoming || r.arrivalDate.isBefore(DateTime.now()))
          .toList() ??
      const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final msg = snapshot.error is BffException
                ? (snapshot.error as BffException).message
                : snapshot.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Unable to load bookings'),
                    const SizedBox(height: 8),
                    Text(msg,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (_all == null || _all!.isEmpty) {
            return _EmptyBookings(
                onRefresh: () async => setState(() => _future = _load()));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                reservations: _upcoming,
                upcoming: true,
                onRefresh: () async {
                  _all = null;
                  setState(() => _future = _load());
                  await _future;
                },
                onCancel: (r) => _confirmCancel(context, r),
                onModify: (r) => _showModifyOptions(context, r),
              ),
              _BookingList(
                reservations: _past,
                upcoming: false,
                onRefresh: () async {
                  _all = null;
                  setState(() => _future = _load());
                  await _future;
                },
                onCancel: null,
                onModify: null,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text('Cancel reservation ${r.confirmationNumber}? '
            'This action may be subject to cancellation fees.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.client.cancelReservation(widget.propertyCode, r.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled.')),
        );
        setState(() => _future = _load());
      }
    } on BffException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancel failed: ${e.message}')),
        );
      }
    }
  }

  void _showModifyOptions(BuildContext context, Reservation r) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Modify Dates'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Date modification - coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Modify Guest Details'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guest details - coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('View / Print Confirmation'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Confirmation: ${r.confirmationNumber}')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Cancel Booking',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmCancel(context, r);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Booking list
// ═══════════════════════════════════════════════════════════════════════════

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.reservations,
    required this.upcoming,
    required this.onRefresh,
    this.onCancel,
    this.onModify,
  });

  final List<Reservation> reservations;
  final bool upcoming;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Reservation)? onCancel;
  final void Function(Reservation)? onModify;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.hotel,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            upcoming ? 'No upcoming bookings.' : 'No past bookings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _BookingCard(
          reservation: reservations[i],
          upcoming: upcoming,
          onCancel: onCancel,
          onModify: onModify,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.reservation,
    required this.upcoming,
    this.onCancel,
    this.onModify,
  });

  final Reservation reservation;
  final bool upcoming;
  final Future<void> Function(Reservation)? onCancel;
  final void Function(Reservation)? onModify;

  String get _sym => _symbolFor(reservation.currencyCode);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reservation.roomTypeName ?? 'Room',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                _StatusChip(status: reservation.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '#${reservation.confirmationNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                    '${DateFormat('MMM d').format(reservation.arrivalDate)} - ${DateFormat('MMM d, yyyy').format(reservation.departureDate)}'),
                const SizedBox(width: 8),
                Text(
                    '· ${reservation.numberOfNights} night${reservation.numberOfNights != 1 ? "s" : ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                    '${reservation.numberOfAdults + reservation.numberOfChildren} guests · ${reservation.numberOfRooms} room${reservation.numberOfRooms != 1 ? "s" : ""}'),
                const Spacer(),
                Text('$_sym${reservation.rateAmount.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            if (reservation.specialRequests != null &&
                reservation.specialRequests!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        'Special requests: ${reservation.specialRequests!}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            if (upcoming && (onCancel != null || onModify != null)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onModify != null)
                    TextButton(
                        onPressed: () => onModify!(reservation),
                        child: const Text('Manage')),
                  if (onCancel != null)
                    TextButton(
                      onPressed: () => onCancel!(reservation),
                      style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReservationStatus.reserved ||
      ReservationStatus.dueIn =>
        Theme.of(context).colorScheme.primary,
      ReservationStatus.checkedIn => Theme.of(context).colorScheme.tertiary,
      ReservationStatus.checkedOut => Theme.of(context).colorScheme.outline,
      ReservationStatus.cancelled ||
      ReservationStatus.noShow =>
        Theme.of(context).colorScheme.error,
      ReservationStatus.waitlist => Theme.of(context).colorScheme.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status.label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.luggage,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No bookings yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Start your next trip by searching for a hotel.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: () {
                onRefresh();
              },
              child: const Text('Refresh')),
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
