// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

// eBooking app smoke test.
//
// The app is web-coupled (`package:web` in app.dart — same-origin
// query parsing), so this runs on the chrome platform (the flutter
// lane's pubspec `web:` probe). `HbookShell.initState` bootstraps the
// runtime context from the BFF; with no BFF reachable under the test
// harness that fails and the shell renders its deterministic offline
// fallback scaffold — the smoke assertion (the dash pattern: the app
// builds and settles offline).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebooking/app.dart';

void main() {
  testWidgets('HbookApp builds and renders the offline fallback', (
    tester,
  ) async {
    await tester.pumpWidget(const HbookApp());
    // Let the bootstrap fetch fail (offline) and the state settle.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MaterialApp), findsOneWidget);
    // The offline fallback scaffold — no BFF reachable under the test
    // harness, the bootstrap error page renders deterministically.
    expect(find.textContaining('eBooking unavailable:'), findsOneWidget);
  });
}
