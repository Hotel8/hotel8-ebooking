# Hotel8:eBooking - Business Requirements & Functionality

> Audience: product owners, business analysts, and anyone evaluating what
> Hotel8:eBooking **does for the business**. For architecture read `README.md`;
> for wire-level detail read `DESIGN.md`.

## 1. Business Purpose

- Give each property a **direct, commission-free booking channel** under the
  hotel's own brand, replacing third-party booking engines.
- Convert metasears/OTA referral traffic (Hotel8:Meta deep links) into
  first-party bookings with full rate accuracy.
- Grow the loyalty program by letting guests join at booking time and
  instantly receive member rates.
- Maximize booking revenue through rate-plan comparison, packages/add-ons,
  promo and corporate codes - without leaking negotiated rates to the public.

## 2. Business Scope (What the Service Provides)

| Capability | Provided by eBooking |
|---|---|
| Availability search (dates, occupancy, promo code) |search funnel |
| Room type browsing with imagery and amenities |detail pages |
| Rate plan comparison (BAR, packages, advance purchase) |detail page table |
| Package/add-on selection with live price total |detail + checkout |
| Anonymous guest checkout (no account) |guest checkout |
| Signed-in member checkout (pre-filled, points preview) |member checkout |
| Loyalty sign-up during booking |one-click enrolment (`POST /v1/members` on hotel8-loyalty via BFF) |
| Gift voucher redemption |validate + redeem (`POST .../vouchers/{validate,redeem}` on hotel8-pms cashiering) |
| Booking confirmation with reference number ||
| My Bookings: view/cancel own reservations ||
| Promo code validation ||
| Multi-property org landing / cross-property search |property picker when the environment hosts several; org-wide availability (`GET /v1/availability`) |
| SEO surface (Schema.org JSON-LD, OG tags, descriptive title) |in the Flutter web shell (`web/index.html`); SSR/sitemaps ride the web-serving layer |
| In-stay services (key, room service, chat) |delegated - Hotel8:eGuest |
| Payment acceptance |delegated - Bill8:Payments via BFF |
| OTA/distribution |delegated - Hotel8:Distrib |
| Staff PMS operations |delegated - Hotel8:ePMS |

## 3. Business Capabilities

### Direct booking funnel

| Capability | Business rule |
|---|---|
| Guest checkout | A guest without an account can complete a booking using only contact details plus a payment guarantee; the card is tokenized server-side and not charged unless the rate plan is advance-purchase. |
| Member checkout | A signed-in member books with profile pre-fill and sees loyalty points to be earned; member-only rates apply automatically. |
| Rate comparison | Room detail always shows the available rate plans side by side (price, cancellation, inclusions) before commitment - the guest sees the total, not just the nightly rate. |
| Packages & add-ons | Add-ons (breakfast, parking, spa, transfer) are priced per stay and included in the live total. |
| Promo code | A promo code is validated and priced against live PMS rate plans before the booking is created; invalid codes never apply silently. |
| Cancellation | A guest can cancel their own reservation; the result honors the rate plan's cancellation policy downstream in PMS. |

### Booking management

| Capability | Business rule |
|---|---|
| My Bookings | Signed-in guests see upcoming and past reservations, with cancel and confirmation re-print. |
| Confirmation | Booking completes with a confirmation number and summary suitable for printing/add-to-calendar. |

## 4. Business Events (Outbound)

eBooking is a client and emits no domain events of its own. The guest actions
it triggers produce these events **in Hotel8:PMS** (see `services/pms/DESIGN.md`):

| Business moment | Event (emitted by PMS) |
|---|---|
| Booking made | `pms.reservation.created` family events |
| Booking cancelled | `pms.reservation.cancelled` family events |

**Inbound:** none - the app consumes no platform events.

## 5. Business Rules & Invariants

1. Every booking flows through the BFF; the app cannot reach PMS, Loyalty or
   Payments directly.
2. A guest without an account can book; identity is optional, not mandatory.
3. Negotiated/corporate rates are never displayed in the public funnel.
4. Displayed totals are advisory; the PMS price at reservation creation is
   authoritative.
5. A promo or voucher code must validate against live PMS data before it
   affects a price.
6. Card details are tokenized server-side; the app never sees or stores card
   data.
7. Cancellation honors the rate plan's policy as enforced by PMS - the UI
   never overrides a policy decision.

## 6. Target-User Roles & Use Cases

| Persona | What they do with eBooking |
|---|---|
| Anonymous guest | Searches dates, compares rooms/rates, books with contact details + payment guarantee, receives confirmation. |
| Loyalty member | Signs in, books with member rates and points preview, manages bookings. |
| Marketing/Revenue manager | Configures hero content, promo codes, and rate display rules through the property's PMS admin surface (hotel8:pms admin RFW pages). |
| Metasearch visitor | Lands from a Hotel8:Meta deep link and converts on the same rate seen in the ad. |

## 7. KPIs / Success Criteria

- **Conversion rate** of search → booking on the direct channel.
- **Direct-channel share** of total reservations (vs OTA), and metasearch
  click → booking conversion for Hotel8:Meta traffic.
- **Loyalty enrolments** completed during booking; member-rate bookings share.
- **Rate accuracy** - displayed rates match PMS charge at check-in (100%).
- **Page performance** - search results render interactively well below the
  three-second budget on mid-range mobile devices over 4G.

## 8. Dependencies & Reliance on Other Services

| Reliance | For |
|---|---|
| Hotel8:PMS | Availability, rates, packages, reservations, promo validation, cancellation policy |
| Sentin8:BFF | All transport, session custody, tenant resolution |
| Sentin8:Auth (customer env) | Member sign-in/sign-up (via BFF) |
| Bill8:Payments | Card guarantee/deposit tokenization (via BFF) |
| Hotel8:Loyalty | Member rates, enrolment, points preview (via BFF) |
| Sentin8:Post | Confirmation email/SMS (triggered server-side) |
| Sentin8:App | Listing, runtime context, DCR bootstrap |
| Hotel8:Meta | Deep-link traffic with UTM context |

## 9. Acceptance Criteria

1. A guest can complete a booking end-to-end without creating an account.
2. A signed-in member sees member rates and points-to-earn before committing.
3. Room detail shows all sellable rate plans with total price and
   cancellation terms before "Book Now".
4. An invalid promo/voucher code is rejected before the booking is created -
   never silently dropped at settlement.
5. Booking confirmation displays a confirmation number and full summary.
6. A guest can cancel an eligible booking from My Bookings and see the
   updated status.
7. All booking traffic is confined to `/proxy/*` calls - no direct backend
   endpoints appear in client networking traces.

## 10. Open Business Questions

- Should the booking engine support full payment-at-booking (not just
  guarantee) for advance-purchase rates straight in the funnel, and under
  which settlement terms?
- Who owns SEO/SSR - the app build or a server-rendered companion - and does
  Schema.org markup live in the app or the web serving layer?
- Multi-property organizations: is one eBooking instance per property the
  norm, with the org landing page aggregating them?

---

**Architecture & Design:** hotel8:ebooking and its underlying concepts were designed by [Hamid Jahanzad](https://www.linkedin.com/in/hamidjahanzad/).
