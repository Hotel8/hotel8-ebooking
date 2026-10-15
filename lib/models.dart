// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

/// Hbook data models.
///
/// Simple Dart classes mirroring the PMS contract shapes (see
/// `crates/pms-contracts/src/lib.rs`) and the BFF proxy surface
/// (see `ebooking/DESIGN.md` §4).

// ═══════════════════════════════════════════════════════════════════════════
// Property
// ═══════════════════════════════════════════════════════════════════════════

class Address {
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const Address({
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressLine1: json['address_line1'] as String?,
        addressLine2: json['address_line2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        postalCode: json['postal_code'] as String?,
        country: json['country'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
      };

  String get oneLine => [
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
}

class Property {
  final String id;
  final String chainId;
  final String propertyCode;
  final String propertyName;
  final String timezone;
  final String currencyCode;
  final List<String> languages;
  final Address? address;
  final String? phone;
  final String? email;

  const Property({
    required this.id,
    required this.chainId,
    required this.propertyCode,
    required this.propertyName,
    required this.timezone,
    required this.currencyCode,
    required this.languages,
    this.address,
    this.phone,
    this.email,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as String,
        chainId: json['chain_id'] as String,
        propertyCode: json['property_code'] as String,
        propertyName: json['property_name'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        currencyCode: json['currency_code'] as String? ?? 'USD',
        languages:
            (json['languages'] as List<dynamic>?)?.cast<String>() ?? const [],
        address: json['address'] != null
            ? Address.fromJson(json['address'] as Map<String, dynamic>)
            : null,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'chain_id': chainId,
        'property_code': propertyCode,
        'property_name': propertyName,
        'timezone': timezone,
        'currency_code': currencyCode,
        'languages': languages,
        'address': address?.toJson(),
        'phone': phone,
        'email': email,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Room Type
// ═══════════════════════════════════════════════════════════════════════════

class RoomType {
  final String id;
  final String propertyId;
  final String roomTypeCode;
  final String roomTypeName;
  final String? description;
  final int maxOccupancy;
  final String? bedType;
  final bool isSmoking;
  final List<String> features;

  const RoomType({
    required this.id,
    required this.propertyId,
    required this.roomTypeCode,
    required this.roomTypeName,
    this.description,
    required this.maxOccupancy,
    this.bedType,
    required this.isSmoking,
    required this.features,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) => RoomType(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        roomTypeCode: json['room_type_code'] as String,
        roomTypeName: json['room_type_name'] as String,
        description: json['description'] as String?,
        maxOccupancy: (json['max_occupancy'] as num?)?.toInt() ?? 2,
        bedType: json['bed_type'] as String?,
        isSmoking: json['is_smoking'] as bool? ?? false,
        features:
            (json['features'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'room_type_code': roomTypeCode,
        'room_type_name': roomTypeName,
        'description': description,
        'max_occupancy': maxOccupancy,
        'bed_type': bedType,
        'is_smoking': isSmoking,
        'features': features,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Rate Plan
// ═══════════════════════════════════════════════════════════════════════════

class RatePlan {
  final String id;
  final String propertyId;
  final String ratePlanCode;
  final String ratePlanName;
  final String? rateCategory;
  final String? description;
  final String currencyCode;
  final bool isActive;
  final int? minLos;
  final int? maxLos;
  final String? cancellationPolicy;
  final String? depositPolicy;
  final String? guaranteePolicy;

  const RatePlan({
    required this.id,
    required this.propertyId,
    required this.ratePlanCode,
    required this.ratePlanName,
    this.rateCategory,
    this.description,
    required this.currencyCode,
    required this.isActive,
    this.minLos,
    this.maxLos,
    this.cancellationPolicy,
    this.depositPolicy,
    this.guaranteePolicy,
  });

  factory RatePlan.fromJson(Map<String, dynamic> json) => RatePlan(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        ratePlanCode: json['rate_plan_code'] as String,
        ratePlanName: json['rate_plan_name'] as String,
        rateCategory: json['rate_category'] as String?,
        description: json['description'] as String?,
        currencyCode: json['currency_code'] as String? ?? 'USD',
        isActive: json['is_active'] as bool? ?? true,
        minLos: (json['min_los'] as num?)?.toInt(),
        maxLos: (json['max_los'] as num?)?.toInt(),
        cancellationPolicy: json['cancellation_policy'] as String?,
        depositPolicy: json['deposit_policy'] as String?,
        guaranteePolicy: json['guarantee_policy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'rate_plan_code': ratePlanCode,
        'rate_plan_name': ratePlanName,
        'rate_category': rateCategory,
        'description': description,
        'currency_code': currencyCode,
        'is_active': isActive,
        'min_los': minLos,
        'max_los': maxLos,
        'cancellation_policy': cancellationPolicy,
        'deposit_policy': depositPolicy,
        'guarantee_policy': guaranteePolicy,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Packages / Add-ons
// ═══════════════════════════════════════════════════════════════════════════

class Package {
  final String packageCode;
  final String packageName;
  final int quantity;
  final double price;
  final bool perStay;

  const Package({
    required this.packageCode,
    required this.packageName,
    this.quantity = 1,
    required this.price,
    this.perStay = false,
  });

  factory Package.fromJson(Map<String, dynamic> json) => Package(
        packageCode: json['package_code'] as String,
        packageName: json['package_name'] as String,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        perStay: json['per_stay'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'package_code': packageCode,
        'package_name': packageName,
        'quantity': quantity,
        'price': price,
        'per_stay': perStay,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Availability Search
// ═══════════════════════════════════════════════════════════════════════════

class AvailabilityRequest {
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int numberOfAdults;
  final int numberOfChildren;
  final int numberOfRooms;
  final String? roomType;
  final String? ratePlanCode;
  final String? promoCode;

  const AvailabilityRequest({
    required this.arrivalDate,
    required this.departureDate,
    this.numberOfAdults = 2,
    this.numberOfChildren = 0,
    this.numberOfRooms = 1,
    this.roomType,
    this.ratePlanCode,
    this.promoCode,
  });

  Map<String, dynamic> toJson() => {
        'arrival_date': _dateStr(arrivalDate),
        'departure_date': _dateStr(departureDate),
        'number_of_adults': numberOfAdults,
        'number_of_children': numberOfChildren,
        'number_of_rooms': numberOfRooms,
        'room_type': roomType,
        'rate_plan_code': ratePlanCode,
        'promo_code': promoCode,
      };
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class RateRestrictions {
  final bool closedToArrival;
  final bool closedToDeparture;
  final int minLos;
  final int maxLos;

  const RateRestrictions({
    this.closedToArrival = false,
    this.closedToDeparture = false,
    this.minLos = 1,
    this.maxLos = 28,
  });

  factory RateRestrictions.fromJson(Map<String, dynamic> json) =>
      RateRestrictions(
        closedToArrival: json['closed_to_arrival'] as bool? ?? false,
        closedToDeparture: json['closed_to_departure'] as bool? ?? false,
        minLos: (json['min_los'] as num?)?.toInt() ?? 1,
        maxLos: (json['max_los'] as num?)?.toInt() ?? 28,
      );
}

class AvailableRatePlan {
  final String ratePlanCode;
  final String ratePlanName;
  final double totalAmount;
  final double averageNightlyRate;
  final String currencyCode;
  final bool isAvailable;
  final RateRestrictions? restrictions;

  const AvailableRatePlan({
    required this.ratePlanCode,
    required this.ratePlanName,
    required this.totalAmount,
    required this.averageNightlyRate,
    required this.currencyCode,
    required this.isAvailable,
    this.restrictions,
  });

  factory AvailableRatePlan.fromJson(Map<String, dynamic> json) =>
      AvailableRatePlan(
        ratePlanCode: json['rate_plan_code'] as String,
        ratePlanName: json['rate_plan_name'] as String? ?? '',
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        averageNightlyRate:
            (json['average_nightly_rate'] as num?)?.toDouble() ?? 0.0,
        currencyCode: json['currency_code'] as String? ?? 'USD',
        isAvailable: json['is_available'] as bool? ?? true,
        restrictions: json['restrictions'] != null
            ? RateRestrictions.fromJson(
                json['restrictions'] as Map<String, dynamic>)
            : null,
      );
}

class AvailableRoomType {
  final String roomType;
  final String roomTypeDescription;
  final int availableRooms;
  final int totalRooms;
  final List<AvailableRatePlan> ratePlans;

  const AvailableRoomType({
    required this.roomType,
    required this.roomTypeDescription,
    required this.availableRooms,
    required this.totalRooms,
    required this.ratePlans,
  });

  factory AvailableRoomType.fromJson(Map<String, dynamic> json) =>
      AvailableRoomType(
        roomType: json['room_type'] as String,
        roomTypeDescription: json['room_type_description'] as String? ?? '',
        availableRooms: (json['available_rooms'] as num?)?.toInt() ?? 0,
        totalRooms: (json['total_rooms'] as num?)?.toInt() ?? 0,
        ratePlans: (json['rate_plans'] as List<dynamic>?)
                ?.map((e) =>
                    AvailableRatePlan.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class AvailabilityResponse {
  final String propertyCode;
  final String chainCode;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int numberOfNights;
  final List<AvailableRoomType> roomTypes;

  const AvailabilityResponse({
    required this.propertyCode,
    required this.chainCode,
    required this.arrivalDate,
    required this.departureDate,
    required this.numberOfNights,
    required this.roomTypes,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponse(
      propertyCode: json['property_code'] as String? ?? '',
      chainCode: json['chain_code'] as String? ?? '',
      arrivalDate: DateTime.tryParse(json['arrival_date'] as String? ?? '') ??
          DateTime.now(),
      departureDate:
          DateTime.tryParse(json['departure_date'] as String? ?? '') ??
              DateTime.now(),
      numberOfNights: (json['number_of_nights'] as num?)?.toInt() ?? 1,
      roomTypes: (json['room_types'] as List<dynamic>?)
              ?.map(
                  (e) => AvailableRoomType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Aggregate used by the search results screen — combines the PMS
/// availability room-type row with optional property/room-type content.
class SearchResult {
  final AvailableRoomType availability;
  final RoomType? roomTypeDetail;
  final String? imageUrl;

  const SearchResult({
    required this.availability,
    this.roomTypeDetail,
    this.imageUrl,
  });

  /// Lowest available total across rate plans.
  double get lowestTotal {
    if (availability.ratePlans.isEmpty) return 0;
    return availability.ratePlans
        .where((r) => r.isAvailable)
        .map((r) => r.totalAmount)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Lowest average nightly rate across rate plans.
  double get lowestNightly {
    if (availability.ratePlans.isEmpty) return 0;
    return availability.ratePlans
        .where((r) => r.isAvailable)
        .map((r) => r.averageNightlyRate)
        .reduce((a, b) => a < b ? a : b);
  }

  String get currency => availability.ratePlans.isEmpty
      ? 'USD'
      : availability.ratePlans.first.currencyCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// Reservation
// ═══════════════════════════════════════════════════════════════════════════

enum ReservationStatus {
  reserved,
  dueIn,
  checkedIn,
  checkedOut,
  cancelled,
  noShow,
  waitlist;

  static ReservationStatus fromString(String s) {
    final n = s.toLowerCase().replaceAll('_', '');
    return ReservationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == n,
      // PMS res_status: CONFIRMED maps to reserved (booked, not arrived).
      orElse: () => n == 'confirmed'
          ? ReservationStatus.reserved
          : ReservationStatus.reserved,
    );
  }

  String get label {
    switch (this) {
      case ReservationStatus.reserved:
        return 'Reserved';
      case ReservationStatus.dueIn:
        return 'Due In';
      case ReservationStatus.checkedIn:
        return 'Checked In';
      case ReservationStatus.checkedOut:
        return 'Checked Out';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.noShow:
        return 'No Show';
      case ReservationStatus.waitlist:
        return 'Waitlist';
    }
  }

  bool get isUpcoming =>
      this == ReservationStatus.reserved || this == ReservationStatus.dueIn;
}

class Reservation {
  final String id;
  final String confirmationNumber;
  final ReservationStatus status;
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int numberOfNights;
  final int numberOfRooms;
  final int numberOfAdults;
  final int numberOfChildren;
  final String roomTypeId;
  final String ratePlanId;
  final double rateAmount;
  final String currencyCode;
  final String? roomTypeName;
  final String? ratePlanName;
  final String? specialRequests;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.confirmationNumber,
    required this.status,
    required this.arrivalDate,
    required this.departureDate,
    required this.numberOfNights,
    required this.numberOfRooms,
    required this.numberOfAdults,
    required this.numberOfChildren,
    required this.roomTypeId,
    required this.ratePlanId,
    required this.rateAmount,
    required this.currencyCode,
    this.roomTypeName,
    this.ratePlanName,
    this.specialRequests,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as String,
        confirmationNumber: json['confirmation_number'] as String? ?? '',
        status: ReservationStatus.fromString(
            json['status'] as String? ?? 'RESERVED'),
        arrivalDate: DateTime.tryParse(json['arrival_date'] as String? ?? '') ??
            DateTime.now(),
        departureDate:
            DateTime.tryParse(json['departure_date'] as String? ?? '') ??
                DateTime.now(),
        numberOfNights: (json['number_of_nights'] as num?)?.toInt() ?? 1,
        numberOfRooms: (json['number_of_rooms'] as num?)?.toInt() ?? 1,
        numberOfAdults: (json['number_of_adults'] as num?)?.toInt() ?? 1,
        numberOfChildren: (json['number_of_children'] as num?)?.toInt() ?? 0,
        roomTypeId: json['room_type_id'] as String? ?? '',
        ratePlanId: json['rate_plan_id'] as String? ?? '',
        rateAmount: (json['rate_amount'] as num?)?.toDouble() ?? 0.0,
        currencyCode: json['currency_code'] as String? ?? 'USD',
        roomTypeName: json['room_type_name'] as String?,
        ratePlanName: json['rate_plan_name'] as String?,
        specialRequests: json['special_requests'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ReservationCreate {
  final DateTime arrivalDate;
  final DateTime departureDate;
  final int numberOfRooms;
  final int numberOfAdults;
  final int numberOfChildren;
  final String roomTypeId;
  final String ratePlanId;
  final String? guestProfileId;
  final String? paymentMethod;
  final String? guaranteeCode;
  final String? creditCardToken;
  final List<Package> packages;
  final String? specialRequests;
  final String? promoCode;
  final MetasearchContext? metasearch;

  const ReservationCreate({
    required this.arrivalDate,
    required this.departureDate,
    this.numberOfRooms = 1,
    required this.numberOfAdults,
    this.numberOfChildren = 0,
    required this.roomTypeId,
    required this.ratePlanId,
    this.guestProfileId,
    this.paymentMethod,
    this.guaranteeCode,
    this.creditCardToken,
    this.packages = const [],
    this.specialRequests,
    this.promoCode,
    this.metasearch,
  });

  Map<String, dynamic> toJson() => {
        'arrival_date': _dateStr(arrivalDate),
        'departure_date': _dateStr(departureDate),
        'number_of_rooms': numberOfRooms,
        'number_of_adults': numberOfAdults,
        'number_of_children': numberOfChildren,
        'room_type_id': roomTypeId,
        'rate_plan_id': ratePlanId,
        'guest_profile_id': guestProfileId,
        'payment_method': paymentMethod,
        'guarantee_code': guaranteeCode,
        'credit_card_token': creditCardToken,
        'packages': packages.map((p) => p.toJson()).toList(),
        'special_requests': specialRequests,
        'promo_code': promoCode,
        if (metasearch != null) ...metasearch!.toBookingFields(),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Guest info (checkout form)
// ═══════════════════════════════════════════════════════════════════════════

class GuestInfo {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String country;
  final String? estimatedArrival;
  final String? specialRequests;

  const GuestInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.country,
    this.estimatedArrival,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'country': country,
        'estimated_arrival': estimatedArrival,
        'special_requests': specialRequests,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Promo code validation
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// Checkout payload (passed from room detail → checkout → confirmation)
// ═══════════════════════════════════════════════════════════════════════════

class CheckoutData {
  final String propertyName;
  final String propertyCode;
  final AvailabilityRequest request;
  final int nights;
  final String roomTypeName;
  final String roomTypeCode;
  final String roomTypeId;
  final AvailableRatePlan ratePlan;
  final List<Package> packages;
  final String? promoCode;
  final MetasearchContext? metasearch;
  final double totalAmount;
  final String currency;

  const CheckoutData({
    required this.propertyName,
    required this.propertyCode,
    required this.request,
    required this.nights,
    required this.roomTypeName,
    required this.roomTypeCode,
    required this.roomTypeId,
    required this.ratePlan,
    required this.packages,
    this.promoCode,
    this.metasearch,
    required this.totalAmount,
    required this.currency,
  });
}

class PromoCodeResult {
  final bool valid;
  final String? message;
  final double? discountPercent;
  final String? ratePlanCode;

  const PromoCodeResult({
    required this.valid,
    this.message,
    this.discountPercent,
    this.ratePlanCode,
  });

  factory PromoCodeResult.fromJson(Map<String, dynamic> json) =>
      PromoCodeResult(
        valid: json['valid'] as bool? ?? false,
        message: json['message'] as String?,
        discountPercent: (json['discount_percent'] as num?)?.toDouble(),
        ratePlanCode: json['rate_plan_code'] as String?,
      );
}

/// Guest profile ensured before booking (PMS CRM `GUEST` profile row).
class GuestProfileResult {
  final String id;
  final String? loyaltyNumber;

  const GuestProfileResult({required this.id, this.loyaltyNumber});

  factory GuestProfileResult.fromJson(Map<String, dynamic> json) =>
      GuestProfileResult(
        id: json['id'] as String,
        loyaltyNumber: json['loyalty_number'] as String?,
      );
}

/// Gift-voucher validation/redemption outcome (PMS cashiering).
class VoucherResult {
  final bool valid;
  final String voucherNumber;
  final double? balance;
  final double? redeemedAmount;
  final double? remainingBalance;
  final String? currencyCode;
  final String? error;

  const VoucherResult({
    required this.valid,
    required this.voucherNumber,
    this.balance,
    this.redeemedAmount,
    this.remainingBalance,
    this.currencyCode,
    this.error,
  });

  factory VoucherResult.fromJson(Map<String, dynamic> json) => VoucherResult(
        valid: json['valid'] as bool? ?? true,
        voucherNumber: json['voucher_number'] as String? ?? '',
        balance: (json['balance'] as String?)?.parseDoubleOrJson,
        redeemedAmount: (json['redeemed_amount'] as String?)?.parseDoubleOrJson,
        remainingBalance:
            (json['remaining_balance'] as String?)?.parseDoubleOrJson,
        currencyCode: json['currency_code'] as String?,
        error: json['error'] as String?,
      );
}

extension _DoubleParse on String? {
  /// Voucher amounts arrive as decimal strings (SQL numeric); JSON numbers
  /// are tolerated for forward/backward compatibility.
  double? get parseDoubleOrJson {
    final s = this;
    if (s == null) return null;
    return double.tryParse(s);
  }
}

/// Loyalty enrolment result (hotel8-loyalty member row).
class LoyaltyEnrolment {
  final String id;
  final String memberNumber;
  final int pointsBalance;

  const LoyaltyEnrolment({
    required this.id,
    required this.memberNumber,
    required this.pointsBalance,
  });

  factory LoyaltyEnrolment.fromJson(Map<String, dynamic> json) =>
      LoyaltyEnrolment(
        id: json['id'] as String,
        memberNumber: json['member_number'] as String? ?? '',
        pointsBalance: (json['points_balance'] as num?)?.toInt() ?? 0,
      );
}

/// Metasearch deep-link context captured from the landing URL
/// (ebooking/DESIGN.md §2). Meta ad links carry rate identity (`rate_plan`,
/// `room_type`) plus UTM attribution; the funnel pre-fills the search and
/// threads the attribution into the booking payload so confirmation
/// attributes the stay to the ad channel.
class MetasearchContext {
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? ratePlanCode;
  final String? roomTypeCode;

  const MetasearchContext({
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.ratePlanCode,
    this.roomTypeCode,
  });

  bool get hasAttribution =>
      utmSource != null || utmMedium != null || utmCampaign != null;

  /// Parse from the browser URL's query parameters (`web.window.location`).
  factory MetasearchContext.fromQuery(Map<String, String> query) =>
      MetasearchContext(
        utmSource: _blank(query['utm_source']),
        utmMedium: _blank(query['utm_medium']),
        utmCampaign: _blank(query['utm_campaign']),
        utmContent: _blank(query['utm_content']),
        ratePlanCode: _blank(query['rate_plan']),
        roomTypeCode: _blank(query['room_type']),
      );

  Map<String, String> toBookingFields() => {
        if (utmSource != null) 'utm_source': utmSource!,
        if (utmMedium != null) 'utm_medium': utmMedium!,
        if (utmCampaign != null) 'utm_campaign': utmCampaign!,
        if (utmContent != null) 'utm_content': utmContent!,
      };

  static String? _blank(String? v) => (v == null || v.isEmpty) ? null : v;
}
