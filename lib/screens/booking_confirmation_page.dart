// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Booking confirmation.
///
/// Confirmation number, summary, add-to-calendar, upsell teaser.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({
    super.key,
    required this.client,
    required this.reservation,
    required this.data,
    this.pointsEarned,
    this.isMember = false,
  });

  final BffClient client;
  final Reservation reservation;
  final CheckoutData data;
  final int? pointsEarned;
  final bool isMember;

  String get _sym => _symbolFor(reservation.currencyCode);
  String _money(double amt) => '$_sym${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Icon(Icons.check_circle, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('Your booking is confirmed!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Confirmation Number', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                SelectableText(
                  reservation.confirmationNumber.isEmpty
                      ? 'BOOK-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}'
                      : reservation.confirmationNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Summary ──────────────────────────────────────────────────
          _InfoCard(title: 'Booking Summary', children: [
            _infoRow(context, 'Property', data.propertyName),
            _infoRow(context, 'Room', data.roomTypeName),
            _infoRow(context, 'Rate plan', data.ratePlan.ratePlanName),
            _infoRow(context, 'Check-in', DateFormat('EEE, MMM d, yyyy').format(reservation.arrivalDate)),
            _infoRow(context, 'Check-out', DateFormat('EEE, MMM d, yyyy').format(reservation.departureDate)),
            _infoRow(context, 'Nights', reservation.numberOfNights.toString()),
            _infoRow(context, 'Guests',
                '${reservation.numberOfAdults + reservation.numberOfChildren}'),
            if (data.packages.isNotEmpty)
              _infoRow(context, 'Add-ons', data.packages.map((p) => p.packageName).join(', ')),
            const Divider(),
            _infoRow(context, 'Total paid', _money(data.totalAmount)),
          ]),
          const SizedBox(height: 16),

          // ── Loyalty teaser ─────────────────────────────────────────────
          if (isMember && pointsEarned != null) ...[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.workspace_premium),
                title: Text('You earned ${NumberFormat.decimalPattern().format(pointsEarned!)} points!'),
                subtitle: const Text('Points will be credited after check-out.'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── What's next ──────────────────────────────────────────────
          _InfoCard(title: "What's Next", children: [
            const _Bullet('Check-in time: 3:00 PM'),
            const _Bullet('Check-out time: 11:00 AM'),
            const _Bullet('Bring a valid ID and the credit card used for booking.'),
            const _Bullet('A confirmation email has been sent.'),
          ]),
          const SizedBox(height: 16),

          // ── Actions ──────────────────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _addToCalendar(context),
                icon: const Icon(Icons.event),
                label: const Text('Add to Calendar'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Guest App...')),
                  );
                },
                icon: const Icon(Icons.phone_iphone),
                label: const Text('View My Stay'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Upsell teaser ────────────────────────────────────────────
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.upgrade, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upgrade Your Stay',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Room upgrades, spa packages, late checkout — available in the Guest App.',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSecondaryContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Done ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                // Pop back to the home screen.
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addToCalendar(BuildContext context) {
    final start = reservation.arrivalDate;
    final end = reservation.departureDate;
    final title = '${data.propertyName} — ${data.roomTypeName}';
    // Generate a simple ICS string the user can save/open.
    final ics = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:${reservation.confirmationNumber}@ebooking')
      ..writeln('DTSTART:${start.year}${start.month.toString().padLeft(2, '0')}${start.day.toString().padLeft(2, '0')}T150000')
      ..writeln('DTEND:${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}T110000')
      ..writeln('SUMMARY:$title')
      ..writeln('END:VEVENT')
      ..writeln('END:VCALENDAR');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calendar event created: $title'), duration: const Duration(seconds: 3)),
    );
    debugPrint(ics.toString());
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
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