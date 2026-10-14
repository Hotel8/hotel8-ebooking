// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

// eBooking app smoke test.
//
// Pumps the real root widget (`HbookApp`) and asserts the guest-facing
// shell renders: the bottom navigation (Home / Search / My Bookings /
// Profile) is present. No network calls are made — the home page builds
// its form UI without fetching (search is user-triggered).

import 'package:flutter_test/flutter_test.dart';

import 'package:ebooking/app.dart';

void main() {
  testWidgets('HbookApp renders guest shell with bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const HbookApp());
    // Let pending frames settle; the app makes no network calls on the
    // home tab.
    await tester.pump(const Duration(milliseconds: 100));

    // Bottom navigation destinations render.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('My Bookings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
