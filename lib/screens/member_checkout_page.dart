// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Member checkout (signed-in).
///
/// Pre-filled details, saved payments, loyalty points preview,
/// member rates, faster one-click booking.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';
import 'booking_confirmation_page.dart';

class MemberCheckoutPage extends StatefulWidget {
  const MemberCheckoutPage(
      {super.key, required this.client, required this.data});

  final BffClient client;
  final CheckoutData data;

  @override
  State<MemberCheckoutPage> createState() => _MemberCheckoutPageState();
}

class _MemberCheckoutPageState extends State<MemberCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _specialRequests = TextEditingController();
  int? _selectedPaymentId;
  bool _submitting = false;

  // Mock member profile (in production fetched from Loyalty via BFF).
  final _member = _Member(
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane.doe@email.com',
    phone: '+1-555-0100',
    tier: 'Gold',
    memberNumber: 'GLD-00123456',
    pointsBalance: 18500,
  );

  late final List<_SavedPayment> _savedPayments;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: _member.firstName);
    _lastName = TextEditingController(text: _member.lastName);
    _email = TextEditingController(text: _member.email);
    _phone = TextEditingController(text: _member.phone);
    _savedPayments = const [
      _SavedPayment(id: 1, brand: 'Visa', last4: '4242', expiry: '08/27'),
      _SavedPayment(id: 2, brand: 'Mastercard', last4: '5555', expiry: '03/26'),
    ];
    _selectedPaymentId = 1;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _specialRequests.dispose();
    super.dispose();
  }

  /// Estimated points to earn (1 point per \$1 spent, Gold earns 1.25×).
  int get _pointsToEarn {
    final base = widget.data.totalAmount.round();
    return _member.tier == 'Gold' ? (base * 1.25).round() : base;
  }

  /// Member rate discount (Gold = 10%).
  double get _memberDiscount {
    if (_member.tier == 'Gold') return widget.data.ratePlan.totalAmount * 0.10;
    return 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final selectedCard =
          _savedPayments.firstWhere((p) => p.id == _selectedPaymentId);
      final token =
          'tok_${selectedCard.brand.toLowerCase()}_${selectedCard.last4}';

      final reservation = ReservationCreate(
        arrivalDate: widget.data.request.arrivalDate,
        departureDate: widget.data.request.departureDate,
        numberOfRooms: widget.data.request.numberOfRooms,
        numberOfAdults: widget.data.request.numberOfAdults,
        numberOfChildren: widget.data.request.numberOfChildren,
        roomTypeId: widget.data.roomTypeId,
        ratePlanId: widget.data.ratePlan.ratePlanCode,
        guestProfileId: _member.memberNumber,
        paymentMethod: 'CREDIT_CARD',
        guaranteeCode: 'CC_GUARANTEE',
        creditCardToken: token,
        packages: widget.data.packages,
        specialRequests:
            _specialRequests.text.isEmpty ? null : _specialRequests.text,
        promoCode: widget.data.promoCode,
        metasearch: widget.data.metasearch,
      );

      final result = await widget.client.createReservation(
        widget.data.propertyCode,
        reservation,
        guestInfo: GuestInfo(
          firstName: _firstName?.text.trim() ?? '',
          lastName: _lastName?.text.trim() ?? '',
          email: _email?.text.trim() ?? '',
          phone: _phone?.text.trim() ?? '',
          country: 'pre-filled',
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(
            client: widget.client,
            reservation: result,
            data: widget.data,
            pointsEarned: _pointsToEarn,
            isMember: true,
          ),
        ),
      );
    } on BffException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sym = _symbolFor(widget.data.currency);
    return Scaffold(
      appBar: AppBar(title: const Text('Member Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Member banner ───────────────────────────────────────────
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading:
                    const CircleAvatar(child: Icon(Icons.workspace_premium)),
                title: Text('${_member.tier} Member · ${_member.memberNumber}'),
                subtitle: Text(
                    '${NumberFormat.decimalPattern().format(_member.pointsBalance)} points available'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${NumberFormat.decimalPattern().format(_pointsToEarn)} pts',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Booking summary ─────────────────────────────────────────
            _SummaryCard(
                data: widget.data,
                memberDiscount: _memberDiscount,
                currency: widget.data.currency),
            const SizedBox(height: 20),

            // ── Guest details (pre-filled) ───────────────────────────────
            _sectionTitle(context, 'Guest Details'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _field(_firstName, 'First name *',
                        validator: _required)),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        _field(_lastName, 'Last name *', validator: _required)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_email, 'Email *',
                validator: _emailValidator,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_phone, 'Phone *',
                validator: _required, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialRequests,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Special requests (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // ── Saved payments ────────────────────────────────────────────
            _sectionTitle(context, 'Saved Payment Methods'),
            const SizedBox(height: 8),
            ..._savedPayments.map((p) => RadioListTile<int>(
                  value: p.id,
                  groupValue: _selectedPaymentId,
                  onChanged: (v) => setState(() => _selectedPaymentId = v),
                  title: Text('${p.brand} •••• ${p.last4}'),
                  subtitle: Text('Expires ${p.expiry}'),
                  secondary: const Icon(Icons.credit_card),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new card — coming soon')),
                );
              },
              icon: const Icon(Icons.add_card),
              label: const Text('Add new card'),
            ),
            const SizedBox(height: 24),

            // ── Loyalty preview ───────────────────────────────────────────
            _sectionTitle(context, 'Loyalty Preview'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row(context, 'Member discount (10%)',
                        '-$sym${_memberDiscount.toStringAsFixed(2)}'),
                    _row(context, 'Points earned this stay',
                        '+${NumberFormat.decimalPattern().format(_pointsToEarn)} pts'),
                    _row(context, 'New balance after stay',
                        '${NumberFormat.decimalPattern().format(_member.pointsBalance + _pointsToEarn)} pts'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt),
                label: Text(_submitting ? 'Booking...' : 'Complete Booking'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600));

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: validator,
        keyboardType: keyboardType,
      );

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim()))
      return 'Enter a valid email';
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════════

class _Member {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String tier;
  final String memberNumber;
  final int pointsBalance;

  const _Member({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.tier,
    required this.memberNumber,
    required this.pointsBalance,
  });
}

class _SavedPayment {
  final int id;
  final String brand;
  final String last4;
  final String expiry;

  const _SavedPayment({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Summary card
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.data, this.memberDiscount = 0, required this.currency});
  final CheckoutData data;
  final double memberDiscount;
  final String currency;

  String get _sym => _symbolFor(currency);
  String _money(double amt) => '$_sym${amt.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.roomTypeName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                    '${DateFormat('MMM d').format(data.request.arrivalDate)} — ${DateFormat('MMM d').format(data.request.departureDate)}'),
                const SizedBox(width: 8),
                Text('· ${data.nights} night${data.nights != 1 ? "s" : ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.ratePlan.ratePlanName),
                Text(_money(data.ratePlan.totalAmount)),
              ],
            ),
            if (memberDiscount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Member discount',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                  Text('-${_money(memberDiscount)}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(_money(data.totalAmount - memberDiscount),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
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
