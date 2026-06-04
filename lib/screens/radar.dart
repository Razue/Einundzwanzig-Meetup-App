import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import 'meetup_verification.dart'; 
import 'profile_edit.dart'; 
import 'badge_details.dart'; // <--- Jetzt existiert die Datei!
import '../models/badge.dart';
import '../models/meetup.dart';     
import '../models/user.dart'; 
import '../widgets/nostr_avatar.dart';

class RadarScreen extends StatefulWidget {
  final String cityName;
  const RadarScreen({super.key, required this.cityName});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  UserProfile _currentUser = UserProfile(); 

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() async {
    final user = await UserProfile.load();
    setState(() {
      _currentUser = user;
    });
  }

  void _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );
    _refreshProfile(); 
  }

  void _openScanner() async {
    Meetup currentMeetup;
    try {
      currentMeetup = allMeetups.firstWhere((m) => m.city == widget.cityName,
        orElse: () => fallbackMeetups.firstWhere((m) => m.city == widget.cityName,
          orElse: () => Meetup(id: "temp", city: widget.cityName, country: "DE", telegramLink: "", lat: 0, lng: 0)));
    } catch (e) {
      currentMeetup = Meetup(id: "err", city: widget.cityName, country: "DE", telegramLink: "", lat: 0, lng: 0);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: currentMeetup)),
    );

    // Bei Erfolg wechselt der Verification-Screen direkt in die Wallet
    // (pushReplacement); dieser await kehrt erst zurück, wenn der Nutzer
    // wieder hier landet. Profil/UI dann unbedingt auffrischen.
    if (mounted) {
      _refreshProfile();
      setState(() {});
    }
  }

  // Funktion zum Öffnen der Details
  void _openBadgeDetails(MeetupBadge badge) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BadgeDetailsScreen(badge: badge)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('RADAR / ${widget.cityName.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _openProfile,
            tooltip: AppLocalizations.of(context).rdEditIdentity,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // USER INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: cCard,
              child: Row(
                children: [
                  NostrAvatar(
                    fallbackText: _currentUser.nickname,
                    backgroundColor: _getVerificationColor(),
                    radius: 20,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.nickname.isEmpty ? AppLocalizations.of(context).rdAnon : _currentUser.nickname.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        _buildVerificationBadge(), 
                      ],
                    ),
                  ),
                  IconButton(onPressed: _openProfile, icon: const Icon(Icons.edit, color: Colors.grey, size: 20))
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // CHECK-IN BUTTON
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton.icon(
                onPressed: _openScanner, 
                icon: const Icon(Icons.nfc, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: cOrange, shape: const RoundedRectangleBorder()),
                label: Text(AppLocalizations.of(context).rdCollectBadge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 40),

            // DEINE REPUTATION
            Text(AppLocalizations.of(context).rdYourReputation, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const Divider(color: Colors.white24),
            
            if (myBadges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(AppLocalizations.of(context).rdNoBadges, style: const TextStyle(color: Colors.grey)),
              )
            else
              // Hier ist das GRID (Raster) für deine Badges
              GridView.builder(
                shrinkWrap: true, // Wichtig damit es in der ScrollView funktioniert
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 Stück nebeneinander
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: myBadges.length,
                itemBuilder: (context, index) {
                  final badge = myBadges[index];
                  return GestureDetector(
                    onTap: () => _openBadgeDetails(badge), // Klick öffnet Details
                    child: Container(
                      decoration: BoxDecoration(color: cCard, border: Border.all(color: cOrange)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified, color: cOrange, size: 30),
                          const SizedBox(height: 10),
                          // Name gekürzt anzeigen damit es passt
                          Text(
                            badge.meetupName.length > 5 
                                ? "${badge.meetupName.substring(0, 5)}.." 
                                : badge.meetupName.toUpperCase(), 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "${badge.date.day}.${badge.date.month}.",
                            style: const TextStyle(color: Colors.grey, fontSize: 10)
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
            
            // INFO TEXT (Statt Fake Liste)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(5)
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).rdSelfSovereign,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getVerificationColor() {
    if (_currentUser.nostrNpub.isNotEmpty && _currentUser.isVerified) return cPurple; 
    if (_currentUser.telegramHandle.isNotEmpty) return cCyan; 
    if (_currentUser.twitterHandle.isNotEmpty) return Colors.grey; 
    return cOrange; 
  }

  Widget _buildVerificationBadge() {
    if (_currentUser.nostrNpub.isNotEmpty && _currentUser.isVerified) {
      return Row(children: [const Icon(Icons.verified, color: cPurple, size: 14), const SizedBox(width: 4), Text(AppLocalizations.of(context).rdNostrVerified, style: const TextStyle(color: cPurple, fontSize: 12, fontWeight: FontWeight.bold))]);
    }
    
    bool isSocialVerified = _currentUser.isAdminVerified;

    if (_currentUser.telegramHandle.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSocialVerified ? Icons.verified : Icons.help_outline, color: cCyan, size: 14), 
              const SizedBox(width: 4),
              Text(_currentUser.telegramHandle, style: const TextStyle(color: cCyan, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isSocialVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                height: 30, 
                child: ElevatedButton.icon(
                  onPressed: _openScanner, 
                  icon: const Icon(Icons.nfc, size: 14, color: Colors.white),
                  label: Text(AppLocalizations.of(context).rdScanAdminTag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, shape: const RoundedRectangleBorder(), padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
            )
          else
             Padding(padding: const EdgeInsets.only(left: 18.0, top: 2), child: Text(AppLocalizations.of(context).rdVerifiedByAdmin, style: const TextStyle(color: cCyan, fontSize: 8, fontWeight: FontWeight.bold)))
        ],
      );
    }
    
    if (_currentUser.twitterHandle.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSocialVerified ? Icons.verified : Icons.help_outline, color: Colors.grey, size: 14), 
              const SizedBox(width: 4),
              Text(_currentUser.twitterHandle, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (!isSocialVerified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                height: 30, 
                child: ElevatedButton.icon(
                  onPressed: _openScanner, 
                  icon: const Icon(Icons.nfc, size: 14, color: Colors.white),
                  label: Text(AppLocalizations.of(context).rdScanAdminTag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, shape: const RoundedRectangleBorder(), padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
            )
          else
             Padding(padding: const EdgeInsets.only(left: 18.0, top: 2), child: Text(AppLocalizations.of(context).rdVerifiedByAdmin, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)))
        ],
      );
    }

    return Text(AppLocalizations.of(context).rdLinkingIdentity, style: const TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic));
  }
}


