// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Hotel8:EBooking
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'package:sentin8/sentin8.dart';

import 'bff_client.dart';
import 'models.dart';
import 'screens/home_page.dart';
import 'screens/my_bookings_page.dart';
import 'screens/search_results_page.dart';

class HbookApp extends StatelessWidget {
  const HbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hbook - Hotel Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HbookShell(),
    );
  }
}

/// Shell with a bottom navigation bar: Home, Search, My Bookings, Profile.
class HbookShell extends StatefulWidget {
  const HbookShell({super.key});

  @override
  State<HbookShell> createState() => _HbookShellState();
}

class _HbookShellState extends State<HbookShell> {
  int _index = 0;
  AppRuntimeContext? _runtimeContext;
  BffClient? _client;
  Property? _property;
  List<Property> _properties = const [];
  MetasearchContext? _metaContext;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Same-origin bootstrap - the TLS proxy injects the X-Sentin8-* host
      // headers the runtime context resolves from (ebooking/DESIGN.md §2).
      final ctx = await fetchRuntimeContext(appBaseUrl: '');
      final client = BffClient(baseUrl: ctx.bffBaseUrl);
      // Metasearch deep-link context: rate identity + UTM attribution from
      // the landing URL (ebooking/DESIGN.md §2 - Meta deep-link traffic).
      final meta = MetasearchContext.fromQuery(_queryParameters());
      // The property registry read: environments hosting multiple properties
      // start the funnel at the property picker (multi-property landing,
      // ebooking/DESIGN.md §2); a single-property env lands directly.
      List<Property> props = const [];
      try {
        props = await _propertiesForEnv(client, ctx.environmentId);
      } on BffException {
        // Landing content is optional - the funnel still works with the
        // raw property id.
      }
      setState(() {
        _runtimeContext = ctx;
        _client = client;
        _properties = props;
        _property = props.length == 1 ? props.first : null;
        _metaContext = meta;
      });
    } catch (e) {
      setState(() => _bootstrapError = e.toString());
    }
  }

  /// Current URL query parameters (web build; `web.window.location.search`).
  static Map<String, String> _queryParameters() {
    final search = web.window.location.search;
    if (search.isEmpty) return const {};
    final qs = search.startsWith('?') ? search.substring(1) : search;
    final out = <String, String>{};
    for (final pair in qs.split('&')) {
      if (pair.isEmpty) continue;
      final eq = pair.indexOf('=');
      final k = eq < 0 ? pair : pair.substring(0, eq);
      final v = eq < 0 ? '' : Uri.decodeQueryComponent(pair.substring(eq + 1));
      out[k] = v;
    }
    return out;
  }

  /// `GET /proxy/hotel8-pms/v1/properties` - the property registry, filtered
  /// to the app environment (PMS list route).
  Future<List<Property>> _propertiesForEnv(
      BffClient client, String envId) async {
    final json = await client.getRawJson('/proxy/hotel8-pms/v1/properties');
    final list = (json['items'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (_bootstrapError != null) {
      return Scaffold(
        body: Center(child: Text('eBooking unavailable: $_bootstrapError')),
      );
    }
    if (client == null || _runtimeContext == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Multi-property landing: no property selected yet and the environment
    // hosts several - show the property picker instead of the funnel shell.
    if (_property == null && _properties.length > 1) {
      return _PropertyPickerPage(
        properties: _properties,
        instanceName: _runtimeContext!.instanceName,
        onSelected: (p) => setState(() {
          _property = p;
          _index = 0;
        }),
      );
    }
    final propertyId = _property?.id ?? _runtimeContext!.environmentId;
    final propertyName =
        _property?.propertyName ?? _runtimeContext!.instanceName;
    final meta = _metaContext;
    final pages = <Widget>[
      HomePage(
        client: client,
        propertyCode: propertyId,
        propertyName: propertyName,
      ),
      _SearchTab(
        client: client,
        propertyCode: propertyId,
        propertyName: propertyName,
        metasearch: meta,
      ),
      MyBookingsPage(
        client: client,
        propertyCode: propertyId,
      ),
      const _ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'My Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// The "Search" tab - a compact search form that pushes the search results
/// page when the user taps "Search Availability".
class _SearchTab extends StatefulWidget {
  const _SearchTab({
    required this.client,
    required this.propertyCode,
    required this.propertyName,
    this.metasearch,
  });

  final BffClient client;
  final String propertyCode;
  final String propertyName;

  /// Metasearch deep-link context (UTM + rate identity) captured at
  /// bootstrap; arrival via a meta ad pre-fills these on the search form.
  final MetasearchContext? metasearch;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  int _rooms = 1;
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Metasearch deep-link pre-fill (ebooking/DESIGN.md §2): the ad's rate
    // identity pre-selects the search inputs; UTM fields ride to booking.
    final meta = widget.metasearch;
    if (meta?.ratePlanCode != null) _promoController.text = meta!.ratePlanCode!;
    if (meta?.hasAttribution ?? false) _utm = meta!.toBookingFields();
  }

  Map<String, String> _utm = const {};

  Future<void> _pickDate(bool isCheckIn) async {
    final today = DateTime.now();
    final first = isCheckIn
        ? today
        : (_checkIn?.add(const Duration(days: 1)) ??
            today.add(const Duration(days: 1)));
    final date = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = date;
        if (_checkOut == null ||
            _checkOut!.isBefore(date.add(const Duration(days: 1)))) {
          _checkOut = date.add(const Duration(days: 1));
        }
      } else {
        _checkOut = date;
      }
    });
  }

  void _search() {
    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select check-in and check-out dates.')),
      );
      return;
    }
    final request = AvailabilityRequest(
      arrivalDate: _checkIn!,
      departureDate: _checkOut!,
      numberOfAdults: _adults,
      numberOfChildren: _children,
      numberOfRooms: _rooms,
      roomType: widget.metasearch?.roomTypeCode,
      promoCode:
          _promoController.text.isEmpty ? null : _promoController.text.trim(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          client: widget.client,
          propertyCode: widget.propertyCode,
          propertyName: widget.propertyName,
          request: request,
          promoCode: request.promoCode,
          metasearch: _utm.isEmpty
              ? null
              : MetasearchContext(
                  utmSource: _utm['utm_source'],
                  utmMedium: _utm['utm_medium'],
                  utmCampaign: _utm['utm_campaign'],
                  utmContent: _utm['utm_content'],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Hotels')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_checkIn != null
                        ? '${_checkIn!.day}/${_checkIn!.month}/${_checkIn!.year}'
                        : 'Check-in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_checkOut != null
                        ? '${_checkOut!.day}/${_checkOut!.month}/${_checkOut!.year}'
                        : 'Check-out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _adults,
                    decoration: const InputDecoration(labelText: 'Adults'),
                    items: List.generate(10, (i) => i + 1)
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text('$g')))
                        .toList(),
                    onChanged: (v) => setState(() => _adults = v ?? 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _children,
                    decoration: const InputDecoration(labelText: 'Children'),
                    items: List.generate(10, (i) => i)
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text('$g')))
                        .toList(),
                    onChanged: (v) => setState(() => _children = v ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _rooms,
                    decoration: const InputDecoration(labelText: 'Rooms'),
                    items: List.generate(5, (i) => i + 1)
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text('$g')))
                        .toList(),
                    onChanged: (v) => setState(() => _rooms = v ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promoController,
              decoration: const InputDecoration(
                labelText: 'Promo / Corporate code (optional)',
                prefixIcon: Icon(Icons.local_offer_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Search Availability'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Property picker for multi-property organizations (ebooking/DESIGN.md §2
/// multi-property landing): the funnel starts here when the environment hosts
/// several properties; search/booking carry the selected property.
class _PropertyPickerPage extends StatelessWidget {
  const _PropertyPickerPage({
    required this.properties,
    required this.instanceName,
    required this.onSelected,
  });

  final List<Property> properties;
  final String instanceName;
  final ValueChanged<Property> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Choose your hotel - $instanceName')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in properties)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.hotel),
                title: Text(p.propertyName),
                subtitle: Text(p.address?.city ?? p.propertyCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelected(p),
              ),
            ),
          if (properties.isEmpty)
            Text('No properties are available in this environment yet.',
                style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Placeholder profile page - in production shows member info, settings,
/// sign-in / sign-out.
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Sign in for faster booking and loyalty rewards',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: () {}, child: const Text('Sign In')),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () {}, child: const Text('Create an account')),
          ],
        ),
      ),
    );
  }
}
