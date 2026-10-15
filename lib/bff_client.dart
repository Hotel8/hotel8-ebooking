// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Hbook BFF client.
///
/// Thin HTTP client that calls the BFF proxy endpoints (see
/// `ebooking/DESIGN.md` §4) which in turn
/// delegate to PMS / Payments / Loyalty. All requests go through the BFF
/// server-side token guardian — Hbook never talks to a backend directly.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models.dart';

class BffClient {
  BffClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? _resolveBaseUrl(),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  /// Resolve the BFF base URL. In production this is the property-scoped
  /// BFF domain (e.g. `https://bff.book.thegrandhotel.pms.sentin8.dev`).
  /// For local development fall back to the `HBOOK_BFF_BASE_URL` env var or
  /// `http://localhost:8080`.
  static String _resolveBaseUrl() {
    const env = String.fromEnvironment(
      'HBOOK_BFF_BASE_URL',
      defaultValue: '',
    );
    if (env.isNotEmpty) return env;

    if (kIsWeb) {
      // Same-origin: BFF served alongside the Flutter web app.
      return '';
    }
    return 'http://localhost:8080';
  }

  String _path(String p) => '$_baseUrl$p';

  /// Generic JSON GET — used by the bootstrap property-registry lookup.
  Future<Map<String, dynamic>> getRawJson(String path) async => _getJson(path);

  Future<Map<String, dynamic>> _getJson(String path) async {
    final resp =
        await _httpClient.get(Uri.parse(_path(path)), headers: _headers());
    return _handle(resp);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resp = await _httpClient.post(
      Uri.parse(_path(path)),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  Future<Map<String, dynamic>> _putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resp = await _httpClient.put(
      Uri.parse(_path(path)),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(resp);
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _handle(http.Response resp) async {
    final body = resp.body.isEmpty ? '{}' : resp.body;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    String message;
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      message =
          decoded['message'] as String? ?? decoded['error'] as String? ?? body;
    } catch (_) {
      message = body;
    }
    throw BffException(resp.statusCode, message);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Availability
  // ═════════════════════════════════════════════════════════════════════════

  /// `POST /proxy/hotel8-pms/v1/properties/{propertyId}/availability`
  ///
  /// [propertyId] resolves from the runtime context (`ebooking/DESIGN.md` §2).
  Future<AvailabilityResponse> searchAvailability(
    String propertyId,
    AvailabilityRequest request,
  ) async {
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/availability',
      request.toJson(),
    );
    return AvailabilityResponse.fromJson(json);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Property content
  // ═════════════════════════════════════════════════════════════════════════

  /// `GET /proxy/pms/.../content`
  Future<Property> getProperty(String propertyCode) async {
    final json =
        await _getJson('/proxy/pms/par/v1/properties/$propertyCode/content');
    return Property.fromJson(json);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Room types
  // ═════════════════════════════════════════════════════════════════════════

  /// `GET /proxy/hotel8-pms/v1/properties/{propertyId}/room-types`
  Future<List<RoomType>> getRoomTypes(String propertyId) async {
    final json = await _getJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/room-types',
    );
    final list = json['room_types'] as List<dynamic>? ??
        json['data'] as List<dynamic>? ??
        [];
    return list
        .map((e) => RoomType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /proxy/pms/par/v1/roomTypes/{code}`
  Future<RoomType> getRoomType(String propertyCode, String roomTypeCode) async {
    final json = await _getJson(
      '/proxy/pms/par/v1/properties/$propertyCode/roomTypes/$roomTypeCode',
    );
    return RoomType.fromJson(json);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Rate plans & packages
  // ═════════════════════════════════════════════════════════════════════════

  /// `GET /proxy/hotel8-pms/v1/properties/{propertyId}/rate-plans`
  Future<List<RatePlan>> getRatePlans(String propertyId) async {
    final json = await _getJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/rate-plans',
    );
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => RatePlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /proxy/hotel8-pms/v1/properties/{propertyId}/packages`
  Future<List<Package>> getPackages(String propertyId) async {
    final json = await _getJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/packages',
    );
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => Package.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Reservations
  // ═════════════════════════════════════════════════════════════════════════

  /// `POST /proxy/hotel8-pms/v1/properties/{propertyId}/profiles` +
  /// `POST .../reservations` — the anonymous-guest flow ensures a profile
  /// (booking-with-profile), the reservation carries it.
  Future<Reservation> createReservation(
    String propertyId,
    ReservationCreate reservation, {
    GuestInfo? guestInfo,
  }) async {
    var body = reservation.toJson();
    if (guestInfo != null && reservation.guestProfileId == null) {
      final profile = await ensureGuestProfile(propertyId, guestInfo);
      body['guest_profile_id'] = profile.id;
    }
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/reservations',
      body,
    );
    return Reservation.fromJson(json);
  }

  /// `GET /proxy/hotel8-pms/v1/properties/{propertyId}/reservations`
  Future<List<Reservation>> getReservations({
    required String propertyId,
    String? guestProfileId,
    String? confirmationNumber,
  }) async {
    final qs = <String>[];
    if (guestProfileId != null) qs.add('guest_profile_id=$guestProfileId');
    if (confirmationNumber != null) qs.add('confirmation=$confirmationNumber');
    final query = qs.isEmpty ? '' : '?${qs.join('&')}';
    final json = await _getJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/reservations$query',
    );
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /proxy/hotel8-pms/v1/properties/{propertyId}/profiles` — ensure
  /// the booker's guest profile exists (property-scoped CRM row).
  Future<GuestProfileResult> ensureGuestProfile(
    String propertyId,
    GuestInfo info,
  ) async {
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/profiles',
      {
        'profile_type': 'GUEST',
        'first_name': info.firstName,
        'last_name': info.lastName,
        'email': info.email,
        'phone': info.phone,
      },
    );
    return GuestProfileResult.fromJson(json);
  }

  /// `POST /proxy/hotel8-pms/v1/properties/{propertyId}/reservations/{id}/cancel`
  Future<void> cancelReservation(
      String propertyId, String reservationId) async {
    await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId'
      '/reservations/$reservationId/cancel',
      {},
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Promo codes & gift vouchers
  // ═════════════════════════════════════════════════════════════════════════

  /// `POST /proxy/hotel8-pms/v1/properties/{propertyId}/promo/validate`
  Future<PromoCodeResult> validatePromoCode(
    String propertyId,
    String promoCode,
  ) async {
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/promo/validate',
      {'promo_code': promoCode},
    );
    return PromoCodeResult.fromJson(json);
  }

  /// `POST .../vouchers/validate` — balance + expiry check, no commitment.
  Future<VoucherResult> validateVoucher(
    String propertyId,
    String voucherNumber,
  ) async {
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/vouchers/validate',
      {'voucher_number': voucherNumber},
    );
    return VoucherResult.fromJson(json);
  }

  /// `POST .../vouchers/redeem` — applies [amount] (partial redemption).
  Future<VoucherResult> redeemVoucher(
    String propertyId,
    String voucherNumber,
    double amount,
  ) async {
    final json = await _postJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/vouchers/redeem',
      {
        'voucher_number': voucherNumber,
        'amount': amount.toStringAsFixed(2),
      },
    );
    return VoucherResult.fromJson(json);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Loyalty — sign up during booking (instant member-rate join)
  // ═════════════════════════════════════════════════════════════════════════

  /// `POST /proxy/hotel8-loyalty/v1/members` — one-click enrolment with the
  /// booking-form name/email; the response member number rides the
  /// confirmation email.
  Future<LoyaltyEnrolment> joinLoyalty(
    String programId,
    GuestInfo info,
  ) async {
    final json = await _postJson('/proxy/hotel8-loyalty/v1/members', {
      'program_id': programId,
      'first_name': info.firstName,
      'last_name': info.lastName,
      'email': info.email,
    });
    return LoyaltyEnrolment.fromJson(json);
  }

  /// `GET /proxy/hotel8-pms/v1/properties/{propertyId}/guarantee-policies` —
  /// the checkout renders the property's guarantee terms before commitment.
  Future<List<Map<String, dynamic>>> getGuaranteePolicies(
      String propertyId) async {
    final json = await _getJson(
      '/proxy/hotel8-pms/v1/properties/$propertyId/guarantee-policies',
    );
    return ((json['items'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
  }

  void close() => _httpClient.close();
}

class BffException implements Exception {
  final int statusCode;
  final String message;
  const BffException(this.statusCode, this.message);

  @override
  String toString() => 'BffException($statusCode): $message';
}
