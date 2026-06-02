// ============================================
// PATCH 03: reputation_layers_widget.dart
// KOMPLETT NEUE VERSION — Verständliche UX
// ============================================
//
// ÄNDERUNG: Komplettes Redesign des Multi-Layer-Widgets
// für sofortige Verständlichkeit.
//
// VORHER:
//   - Technische Darstellung (Score-Zahlen, Layer-Gewichtung)
//   - User muss verstehen was "25% Social" bedeutet
//   - Keine Handlungsempfehlung
//
// JETZT:
//   1. VERTRAUENS-AMPEL oben: Rot/Gelb/Grün mit einem Satz
//   2. Jeder Layer hat ein klares "Was bedeutet das?" Label
//   3. Fehlende Layer zeigen "Warum das wichtig ist"
//   4. Konkrete Handlungsempfehlung am Ende
//
// ERSETZE: Die komplette Datei
//   lib/widgets/reputation_layers_widget.dart
//
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/social_graph_service.dart';
import '../services/zap_verification_service.dart';
import '../services/nip05_service.dart';

class ReputationLayersWidget extends StatelessWidget {
  // Layer 1: Physisch (aus Reputation-Event)
  final int? badgeCount;
  final int? boundBadges;
  final int? meetupCount;
  final int? signerCount;
  final double? meetupScore;
  final String? since;

  // Layer 2: Lightning/Zaps
  final ZapStats? zapStats;
  final bool humanityVerified;

  // Layer 3: Sozial
  final SocialAnalysis? socialAnalysis;

  // Layer 4: Identität
  final Nip05Result? nip05;
  final int? platformProofCount;
  final Map<String, dynamic>? platformProofs;
  final int? accountAgeDays;

  // Gesamtscore
  final double? totalScore;

  const ReputationLayersWidget({
    super.key,
    this.badgeCount,
    this.boundBadges,
    this.meetupCount,
    this.signerCount,
    this.meetupScore,
    this.since,
    this.zapStats,
    this.humanityVerified = false,
    this.socialAnalysis,
    this.nip05,
    this.platformProofCount,
    this.platformProofs,
    this.accountAgeDays,
    this.totalScore,
  });

  // =============================================
  // SCORES BERECHNEN
  // =============================================

  double? get _physicalScore {
    if (badgeCount == null || badgeCount == 0) return null;
    double score = 0;
    score += (badgeCount! / (badgeCount! + 5)) * 3.0;
    if (meetupCount != null) score += (meetupCount! / (meetupCount! + 3)) * 2.0;
    if (signerCount != null) score += (signerCount! / (signerCount! + 3)) * 2.0;
    if (boundBadges != null && badgeCount! > 0) {
      score += (boundBadges! / badgeCount!) * 1.0;
    }
    return score.clamp(0.0, 8.0);
  }

  double? get _identityScore {
    double score = 0;
    if (nip05 != null && nip05!.valid) {
      score += Nip05Service.score(nip05!);
    }
    if (platformProofCount != null && platformProofCount! > 0) {
      score += (platformProofCount! * 0.3).clamp(0.0, 0.5);
    }
    if (accountAgeDays != null && accountAgeDays! > 30) {
      score += 0.5;
    }
    return score > 0 ? score.clamp(0.0, 2.0) : null;
  }

  // =============================================
  // VERTRAUENS-STUFE BERECHNEN
  // =============================================

  /// Wie viele der 4 Layer sind aktiv (Score > 0)?
  int get _activeLayerCount {
    int count = 0;
    if (_physicalScore != null && _physicalScore! > 0) count++;
    if (zapStats != null && zapStats!.totalCount > 0 || humanityVerified) count++;
    if (socialAnalysis != null && socialAnalysis!.socialScore > 0) count++;
    if (_identityScore != null && _identityScore! > 0) count++;
    return count;
  }

  /// Gesamt-Score (gewichtet)
  double get _combinedScore {
    final physical = (_physicalScore ?? 0) * 0.4;
    final lightning = (zapStats?.lightningScore ?? 0) * 0.25;
    final social = (socialAnalysis?.socialScore ?? 0) * 0.25;
    final identity = (_identityScore ?? 0) * 0.1;
    return (physical + lightning + social + identity).clamp(0.0, 10.0);
  }

  /// Vertrauens-Stufe als Ampel
  _TrustSignal _trustSignalOf(BuildContext context) {
    final t = AppLocalizations.of(context);
    final layers = _activeLayerCount;
    final score = _combinedScore;

    // Nur Badges, nichts anderes → Warnung
    if (layers <= 1 && score < 3.0) {
      return _TrustSignal(
        color: Colors.red.shade400,
        icon: Icons.warning_amber_rounded,
        label: t.rlWeakLabel,
        explanation: t.rlWeakExpl,
        actionHint: t.rlWeakAdvice,
      );
    }

    if (layers <= 1) {
      return _TrustSignal(
        color: Colors.orange,
        icon: Icons.info_outline,
        label: t.rlLimitedLabel,
        explanation: t.rlLimitedExpl,
        actionHint: t.rlLimitedAdvice,
      );
    }

    if (layers == 2 && score < 4.0) {
      return _TrustSignal(
        color: Colors.amber,
        icon: Icons.shield_outlined,
        label: t.rlBuildingLabel,
        explanation: t.rlBuildingExpl,
        actionHint: t.rlBuildingAdvice,
      );
    }

    if (layers >= 3 && score >= 4.0) {
      return _TrustSignal(
        color: Colors.green,
        icon: Icons.verified_user,
        label: t.rlConnectedLabel,
        explanation: t.rlConnectedExpl,
        actionHint: t.rlConnectedAdvice,
      );
    }

    if (layers >= 3 || score >= 5.0) {
      return _TrustSignal(
        color: Colors.green.shade300,
        icon: Icons.shield,
        label: t.rlSolidLabel,
        explanation: t.rlSolidExpl,
        actionHint: t.rlSolidAdvice,
      );
    }

    return _TrustSignal(
      color: Colors.amber,
      icon: Icons.shield_outlined,
      label: t.rlBuildingLabel,
      explanation: t.rlDefaultExpl,
      actionHint: t.rlDefaultAdvice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final signal = _trustSignalOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =============================================
        // VERTRAUENS-AMPEL — Das Erste was man sieht
        // =============================================
        _buildTrustSignalCard(context, signal),

        const SizedBox(height: 16),

        // =============================================
        // DIE 4 BEWEIS-LAYER
        // =============================================
        _buildPhysicalLayer(context),
        const SizedBox(height: 10),
        _buildLightningLayer(context),
        const SizedBox(height: 10),
        _buildSocialLayer(context),
        const SizedBox(height: 10),
        _buildIdentityLayer(context),

        // =============================================
        // HANDLUNGSEMPFEHLUNG
        // =============================================
        if (signal.actionHint.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildActionHint(signal),
        ],
      ],
    );
  }

  // =============================================
  // VERTRAUENS-AMPEL CARD
  // =============================================

  Widget _buildTrustSignalCard(BuildContext context, _TrustSignal signal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: signal.color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Ampel-Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: signal.color.withOpacity(0.15),
              border: Border.all(color: signal.color.withOpacity(0.3)),
            ),
            child: Icon(signal.icon, color: signal.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stufe + Layer-Count
                Row(
                  children: [
                    Text(
                      signal.label.toUpperCase(),
                      style: TextStyle(
                        color: signal.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context).rlProofsOfFour(_activeLayerCount),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  signal.explanation,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // LAYER 1: PHYSISCHER BEWEIS (Meetup-Badges)
  // =============================================

  Widget _buildPhysicalLayer(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasData = _physicalScore != null && _physicalScore! > 0;
    final bool hasDiversity = (signerCount ?? 0) >= 2;
    final bool hasBound = boundBadges != null && badgeCount != null && boundBadges == badgeCount;

    return _buildLayerCard(
      context,
      icon: Icons.nfc,
      color: cOrange,
      title: t.rlMeetupProofs,
      hasData: hasData,
      // Was bedeutet das?
      meaningWhenPresent: hasDiversity
          ? t.rlMeetupGood
          : badgeCount != null && badgeCount! > 0
              ? t.rlPhysGoodDiversity(signerCount ?? 1)
              : null,
      meaningWhenMissing: t.rlMeetupNone,
      details: hasData
          ? [
              _LayerDetail(
                label: t.rlBadgeCount(badgeCount ?? 0),
                sublabel: hasBound
                    ? t.rlAllBound
                    : t.rlBoundOf(boundBadges ?? 0, badgeCount ?? 0),
                positive: hasBound,
              ),
              _LayerDetail(
                label: t.rlDiffMeetups(meetupCount ?? 0),
                sublabel: (meetupCount ?? 0) >= 3
                    ? t.rlGoodSpread
                    : t.rlLowSpread,
                positive: (meetupCount ?? 0) >= 2,
              ),
              _LayerDetail(
                label: t.rlOrganizers(signerCount ?? 0),
                sublabel: hasDiversity
                    ? t.rlConfirmedByDiff
                    : t.rlOneOrgOnly,
                positive: hasDiversity,
              ),
              if (since != null && since!.isNotEmpty)
                _LayerDetail(
                  label: t.rlMemberSince(since!),
                  sublabel: t.rlDaysCount(accountAgeDays ?? 0),
                  positive: (accountAgeDays ?? 0) > 60,
                ),
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 2: LIGHTNING-BEWEIS
  // =============================================

  Widget _buildLightningLayer(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasZaps = zapStats != null && zapStats!.totalCount > 0;
    final hasData = hasZaps || humanityVerified;

    return _buildLayerCard(
      context,
      icon: Icons.bolt,
      color: Colors.amber,
      title: t.rlLightningProof,
      hasData: hasData,
      meaningWhenPresent: humanityVerified && hasZaps
          ? t.rlLnBoth
          : humanityVerified
              ? t.rlLnPaid
              : t.rlLnActiveOnly,
      meaningWhenMissing: t.rlLnNone,
      details: hasData
          ? [
              if (humanityVerified)
                _LayerDetail(
                  label: t.rlHumanVerified,
                  sublabel: t.rlRealLnPayment,
                  positive: true,
                ),
              if (hasZaps) ...[
                _LayerDetail(
                  label: t.rlZapsSent(zapStats!.sentCount),
                  sublabel: t.rlToRecipients(zapStats!.uniqueRecipientCount),
                  positive: zapStats!.uniqueRecipientCount > 3,
                ),
                _LayerDetail(
                  label: t.rlZapsReceived(zapStats!.receivedCount),
                  sublabel: t.rlFromSenders(zapStats!.uniqueSenderCount),
                  positive: zapStats!.receivedCount > 0,
                ),
                if (zapStats!.activeMonths > 0)
                  _LayerDetail(
                    label: t.rlMonthsActive(zapStats!.activeMonths),
                    sublabel: zapStats!.activityLabel,
                    positive: zapStats!.activeMonths >= 3,
                  ),
              ],
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 3: SOZIALER BEWEIS
  // =============================================

  Widget _buildSocialLayer(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasData = socialAnalysis != null && socialAnalysis!.socialScore > 0;
    final sa = socialAnalysis;

    String? meaning;
    if (sa != null) {
      if (sa.isMutual && sa.commonContactCount > 3) {
        meaning = t.rlSocMutualMany;
      } else if (sa.isMutual) {
        meaning = t.rlSocMutual;
      } else if (sa.commonContactCount > 5) {
        meaning = t.rlSocCommon;
      } else if (sa.iFollow || sa.followsMe) {
        meaning = t.rlSocOneSided;
      } else if (sa.orgFollowerCount > 0) {
        meaning = t.rlSocOrgFollow;
      }
    }

    return _buildLayerCard(
      context,
      icon: Icons.hub,
      color: cCyan,
      title: t.rlSocialTitle,
      hasData: hasData,
      meaningWhenPresent: meaning ?? t.rlSocDefault,
      meaningWhenMissing: t.rlSocNone,
      details: sa != null
          ? [
              // Direkte Verbindung
              _LayerDetail(
                label: sa.isMutual
                    ? t.rlMutualFollow
                    : sa.iFollow
                        ? t.rlYouFollow
                        : sa.followsMe
                            ? t.rlFollowsYou
                            : t.rlNoFollow,
                sublabel: sa.isMutual
                    ? t.rlKnowOnNostr
                    : t.rlNoDirectConn,
                positive: sa.isMutual || sa.iFollow || sa.followsMe,
              ),
              // Gemeinsame Kontakte
              _LayerDetail(
                label: t.rlCommonContacts(sa.commonContactCount),
                sublabel: sa.commonContactCount > 5
                    ? t.rlSameNetwork
                    : sa.commonContactCount > 0
                        ? t.rlSomeOverlap
                        : t.rlSeparateNetworks,
                positive: sa.commonContactCount > 0,
              ),
              // Organisator-Follows
              if (sa.orgFollowerCount > 0)
                _LayerDetail(
                  label: t.rlOrgsFollow(sa.orgFollowerCount),
                  sublabel: t.rlEndorsement,
                  positive: true,
                ),
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 4: IDENTITÄTS-BEWEIS
  // =============================================

  Widget _buildIdentityLayer(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasNip05 = nip05 != null && nip05!.valid;
    final hasPlatforms = (platformProofCount ?? 0) > 0 ||
        (platformProofs != null && platformProofs!.isNotEmpty);
    final hasData = hasNip05 || hasPlatforms;

    return _buildLayerCard(
      context,
      icon: Icons.fingerprint,
      color: Colors.purple,
      title: t.rlIdentityTitle,
      hasData: hasData,
      meaningWhenPresent: hasNip05
          ? (hasPlatforms ? t.rlIdNip05Plat : t.rlIdNip05Only)
          : t.rlIdPlatOnly,
      meaningWhenMissing: t.rlIdNone,
      details: [
        if (hasNip05)
          _LayerDetail(
            label: nip05!.nip05,
            sublabel: nip05!.domainLabel,
            positive: true,
          ),
        if (platformProofs != null && platformProofs!.isNotEmpty)
          ...platformProofs!.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>? ?? {};
            final username = data['username'] as String? ?? '';
            return _LayerDetail(
              label: '${_platformLabel(entry.key)}${username.isNotEmpty ? ': @$username' : ''}',
              sublabel: t.rlLinked,
              positive: true,
            );
          }),
        if (!hasNip05 && !hasPlatforms)
          _LayerDetail(
            label: t.rlNoIdentification,
            sublabel: t.rlAnonymous,
            positive: false,
          ),
      ],
    );
  }

  // =============================================
  // HANDLUNGSEMPFEHLUNG
  // =============================================

  Widget _buildActionHint(_TrustSignal signal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: signal.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signal.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: signal.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              signal.actionHint,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // GENERISCHER LAYER-CARD BUILDER
  // =============================================

  Widget _buildLayerCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required bool hasData,
    String? meaningWhenPresent,
    required String meaningWhenMissing,
    required List<_LayerDetail> details,
  }) {
    final meaning = hasData ? meaningWhenPresent : meaningWhenMissing;

    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasData ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.dark(primary: color),
        ),
        child: ExpansionTile(
          // Layer-Header
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(hasData ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: hasData ? color : Colors.grey, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: hasData ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Status-Chip: ✓ oder ✗
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasData
                      ? color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasData ? AppLocalizations.of(context).rlActiveShort : AppLocalizations.of(context).rlMissingShort,
                  style: TextStyle(
                    color: hasData ? color : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Kurze Erklärung immer sichtbar
          subtitle: meaning != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    meaning,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          // Details im Aufklapp-Bereich
          children: details.isNotEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: details.map((d) => _buildDetailRow(d, color)).toList(),
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  // =============================================
  // DETAIL-ZEILE (in Aufklapp)
  // =============================================

  Widget _buildDetailRow(_LayerDetail detail, Color layerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            detail.positive ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: detail.positive ? Colors.green.shade400 : Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail.sublabel.isNotEmpty)
                  Text(
                    detail.sublabel,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PLATTFORM-LABELS
  // =============================================

  String _platformLabel(String platform) {
    switch (platform) {
      case 'telegram': return 'Telegram';
      case 'satoshikleinanzeigen': return 'Satoshi-Kleinanzeigen';
      case 'robosats': return 'RoboSats';
      case 'nostr': return 'Nostr';
      case 'other': return 'Andere';
      default: return platform;
    }
  }
}

// =============================================
// HILFSKLASSEN
// =============================================

class _TrustSignal {
  final Color color;
  final IconData icon;
  final String label;
  final String explanation;
  final String actionHint;

  _TrustSignal({
    required this.color,
    required this.icon,
    required this.label,
    required this.explanation,
    this.actionHint = '',
  });
}

class _LayerDetail {
  final String label;
  final String sublabel;
  final bool positive;

  _LayerDetail({
    required this.label,
    this.sublabel = '',
    this.positive = false,
  });
}


