// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Guest checkout (anonymous).
///
/// Guest info form, special requests, payment guarantee,
/// cancellation policy, "Complete Booking" button.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../bff_client.dart';
import '../models.dart';
import 'booking_confirmation_page.dart';

// CheckoutData is imported from ../models.dart.

class GuestCheckoutPage extends StatefulWidget {
  const GuestCheckoutPage(
      {super.key, required this.client, required this.data});

  final BffClient client;
  final CheckoutData data;

  @override
  State<GuestCheckoutPage> createState() => _GuestCheckoutPageState();
}

class _GuestCheckoutPageState extends State<GuestCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController(text: 'United States');
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _specialRequests = TextEditingController();
  String _estimatedArrival = '15:00';
  bool _agree = false;
  bool _submitting = false;

  final _arrivalTimes = <String>[
    'Flexible',
    'Before 12:00',
    '12:00 - 14:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
    'After 18:00',
  ];

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _country.dispose();
    _cardNumber.dispose();
    _cardName.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _specialRequests.dispose();
    super.dispose();
  }

  bool get _isAdvancePurchase =>
      widget.data.ratePlan.ratePlanName.toLowerCase().contains('advance');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // Tokenize card via Payments (mock - real implementation calls /proxy/payments/v1/tokens).
      final token =
          'tok_${_cardNumber.text.replaceAll(' ', '').substring(0, 4)}';

      final reservation = ReservationCreate(
        arrivalDate: widget.data.request.arrivalDate,
        departureDate: widget.data.request.departureDate,
        numberOfRooms: widget.data.request.numberOfRooms,
        numberOfAdults: widget.data.request.numberOfAdults,
        numberOfChildren: widget.data.request.numberOfChildren,
        roomTypeId: widget.data.roomTypeId,
        ratePlanId: widget.data.ratePlan.ratePlanCode,
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
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          country: _country.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(
            client: widget.client,
            reservation: result,
            data: widget.data,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Booking summary ─────────────────────────────────────────
            _SummaryCard(data: widget.data),
            const SizedBox(height: 20),

            // ── Guest info ──────────────────────────────────────────────
            _sectionTitle(context, 'Guest Information'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _textField(_firstName, 'First name *',
                        validator: _required)),
                const SizedBox(width: 12),
                Expanded(
                    child: _textField(_lastName, 'Last name *',
                        validator: _required)),
              ],
            ),
            const SizedBox(height: 12),
            _textField(_email, 'Email *',
                validator: _emailValidator,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: _textField(_phone, 'Phone *',
                        validator: _required,
                        keyboardType: TextInputType.phone)),
                const SizedBox(width: 12),
                Expanded(
                    flex: 3,
                    child: _textField(_country, 'Country *',
                        validator: _required)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _estimatedArrival,
              decoration:
                  const InputDecoration(labelText: 'Estimated arrival time'),
              items: _arrivalTimes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _estimatedArrival = v ?? 'Flexible'),
            ),
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

            // ── Payment guarantee ────────────────────────────────────────
            _sectionTitle(context, 'Payment Guarantee'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isAdvancePurchase
                    ? Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.3)
                    : Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                      _isAdvancePurchase
                          ? Icons.warning_amber
                          : Icons.lock_outline,
                      color: _isAdvancePurchase
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAdvancePurchase
                          ? 'Advance purchase - your card will be charged now.'
                          : 'Your card will not be charged. Payment is due at the hotel.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _textField(_cardName, 'Name on card *', validator: _required),
            const SizedBox(height: 12),
            _textField(_cardNumber, 'Card number *',
                validator: _cardValidator, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _textField(_expiry, 'MM/YY *',
                        validator: _expiryValidator)),
                const SizedBox(width: 12),
                Expanded(
                    child: _textField(_cvv, 'CVV *',
                        validator: _cvvValidator,
                        keyboardType: TextInputType.number,
                        obscure: true)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Cancellation policy ──────────────────────────────────────
            _sectionTitle(context, 'Cancellation Policy'),
            const SizedBox(height: 8),
            Text(
              _isAdvancePurchase
                  ? 'This rate is non-refundable. Cancellation or changes will result in full charge of the stay.'
                  : 'Free cancellation up to 48 hours before arrival. After that, the first night will be charged.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // ── Agree & submit ───────────────────────────────────────────
            CheckboxListTile(
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              title:
                  const Text('I agree to the terms and cancellation policy.'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Booking'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(BuildContext context, String text) => Text(text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600));

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscure,
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim()))
      return 'Enter a valid email';
    return null;
  }

  String? _cardValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 13) return 'Enter a valid card number';
    return null;
  }

  String? _expiryValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v.trim())) return 'MM/YY';
    return null;
  }

  String? _cvvValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 3) return '3 - 4 digits';
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Booking summary card (shared)
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});
  final CheckoutData data;

  String get _sym => _symbolFor(data.currency);
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
                    '${DateFormat('MMM d').format(data.request.arrivalDate)} - ${DateFormat('MMM d').format(data.request.departureDate)}'),
                const SizedBox(width: 8),
                Text('· ${data.nights} night${data.nights != 1 ? "s" : ""}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text(
                    '${data.request.numberOfAdults + data.request.numberOfChildren} guests · ${data.request.numberOfRooms} room${data.request.numberOfRooms != 1 ? "s" : ""}'),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.ratePlan.ratePlanName,
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(_money(data.ratePlan.totalAmount)),
              ],
            ),
            ...data.packages.map((p) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.packageName,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(_money(p.perStay ? p.price : p.price * data.nights),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(_money(data.totalAmount),
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
