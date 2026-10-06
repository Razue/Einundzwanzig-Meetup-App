# Deckel — run a tab, pay the difference once

A payment protocol for groups, on Nostr. Proposal for "Most Based Payment Protocol", bitcoin++ Berlin 2026.
Status: implemented in the Einundzwanzig Meetup App (branch `feat/deckel`); the kind numbers are provisional.

## The gap

Bitcoin wallets pay one debt at a time. Groups do not work like that. At a table, one person buys the beer, the next one the pizza, a third the taxi. Paid one by one, that evening is six payments. What the group actually owes each other is two.

Banks have always known this: they net first and move only the difference. Wallets have no notion of it, because netting needs something a single wallet does not have — a shared record of who paid what for whom.

Deckel is that record, and the rule that turns it into the fewest payments.

| | Without netting | With Deckel |
|---|---|---|
| Three rounds among three people | 6 payments, 18,400 sats moved | 2 payments, 3,400 sats moved |
| A owes B 5,000, B owes C 5,000, C owes A 3,000 | 3 payments, 13,000 sats | 1 payment, 2,000 sats |

In the second row B pays nothing — and needs no balance at all.

## Five events

A tab is just an identifier. It is printed as a QR code on the coaster: `21d:1:<id>:<name, base64url>`.
Every event carries it in its `d` tag.

| Event | Kind | Signed by | Tags | Says |
|---|---|---|---|---|
| Seat | 30251 (addressable) | the member | `d`, `name` | "I sit at this table." |
| Round | 1251 | whoever paid | `d`, `amount` (sats, total), `p` per sharer; content = what for | "I paid this for these people." |
| Closing | 1252 | any member | `d`, `e` per round | "These rounds are settled now." |
| Receipt | 1253 | whoever got paid | `d`, `e` (closing), `p` (payer), `once`, `amount`, `rail` | "I received my money." |
| Bet | 1254 | the member | `d`, `e` (an oracle's question), `side` (`yes`/`no`), `amount` | "I take this side for this much." |

Who pays whom is in no event. Every device computes it from the rounds of the closing and arrives at the same list.

## Rules

1. **Only who sat down can owe.** A round's share counts only for sharers who published a seat. The payer must be seated too.
2. **A round is split evenly** among its sharers, rounded down. The remainder stays with the payer.
3. **A round belongs to the first closing that names it** (earliest `created_at`, then lowest id). Rounds published later are on the next sheet. The same coaster can be used again and again.
4. **Netting is deterministic.** Balance per member = paid for others − own shares. The largest debtor pays the largest creditor until one of them is even; ties are broken by pubkey. At most (members − 1) payments.
5. **A bet is a handshake, not a locked pot.** Two bets on the same question, for the same amount, one on yes and one on no, by two different members, belong together — earliest first. The question is an oracle's commitment (kind 30237: a strike, a closing time, the hashes of two secrets). When the oracle reveals the secret of the outcome (kind 30238) and it matches the committed hash, the loser owes the winner the amount. That debt is a round on the sheet like any other and is netted with the rest. A bet made after the question closed does not count.
6. **Each payment has one key:** `once = sha256(closing id ‖ ":" ‖ payer ‖ ":" ‖ receiver)`.
7. **Only the receiver's receipt counts.** A payment is done when the receiver signed a receipt with its `once`.

## Paying exactly once

The payer's device keeps a ledger keyed by `once`. The first "pay" takes a token for the amount out of the wallet and stores it under the key. Every later "pay" — a second tap, a restart, another screen — returns the same token and takes nothing out of the wallet again. The receiver can redeem that token once; the mint refuses a second time.

In the reference implementation the token is a Cashu token, shown as a QR code across the table. The receiver's device checks the token's amount against the payment *before* redeeming, redeems, and signs the receipt.

The protocol does not care about the rail. `rail` in the receipt says how the money arrived: `cashu` for a redeemed token, `hand` for anything else — cash, a Lightning payment from another wallet, an Ark payment.

## What this does not solve

- **A bet on the tab is not trustless.** Nothing is locked; the loser can refuse to pay, as with any round. The locked version of the same bet, on the same oracle, is the pot on Arkade (`handschlag/`).
- **Devices must hear the same oracle.** A device that has not seen the reveal yet computes a sheet without the bet.
- **Nobody is forced to pay.** The lever is reputation: an open tab is public. In the Einundzwanzig app that reputation already exists (meetup badges, trust score).
- **A payer can claim a round nobody drank.** Everyone at the table sees every round the moment it is written; a member who disagrees does not pay. Rounds a member has to countersign would be stricter and slower.
- **Tabs are public.** Who owes whom is readable on the relay. Fine at a meetup, not for everything.
- **Everyone needs one relay in common** that accepts these kinds from unknown keys. Many do, some do not (see `tool/deckel/relay_check.dart`).
- **Cashu means trusting a mint**, and the receiver has to accept the payer's mint.
- **One crash window:** if the app dies after the wallet created the token and before the ledger stored it, that token is lost.
- **Novelty is unverified.** I have not searched for prior work on debt netting over Nostr.
- **The kind numbers** are not registered anywhere.

## Where rounds like this happen

The table at the pub is one case. The same four events fit wherever a group pays in rounds and settles later:

- **Splitting a bill, a flat, a trip** — one pays, all share.
- **Game nights and prediction pools** — every hand of Skat or poker, every matchday is a round; a season ends in one payment per person.
- **The tally sheet** in a hackerspace, a clubhouse, an office kitchen — tick all month, settle once.
- **Organisers** fronting room, pizza and stickers for the same meetup.
- **Merchants in a circular economy** who buy from each other: netting lets them settle with little liquidity — whoever is owed as much as they owe pays nothing.

## Reference implementation

| Part | File | Tests |
|---|---|---|
| Netting | `lib/services/deckel/deckel_netting.dart` | `test/deckel_netting_test.dart`, incl. 200 random evenings |
| Events, rules, QR | `lib/services/deckel/deckel_events.dart` | `test/deckel_events_test.dart` |
| Relays, signing | `lib/services/deckel/deckel_backend.dart` | `tool/deckel/relay_check.dart` (a whole evening over real relays) |
| Pay once | `lib/services/deckel/deckel_ledger.dart` | `test/deckel_table_test.dart`, `test_network/deckel_testnut_test.dart` (real mint, play sats) |
| Oracle, bets | `lib/services/deckel/deckel_oracle.dart` | `test/deckel_bet_test.dart`, `test_network/deckel_oracle_test.dart` (the live oracle) |
| Voice commands | `lib/services/deckel/deckel_command.dart` | `test/deckel_command_test.dart` |
| Screen | `lib/screens/deckel_screen.dart` | `test/deckel_screen_test.dart` |
