import 'package:einundzwanzig_meetup_app/models/meetup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Meetup meetup({String name = '', String city = 'Augsburg'}) => Meetup(
    id: 'test',
    name: name,
    city: city,
    country: 'DE',
    telegramLink: '',
    lat: 0,
    lng: 0,
  );

  test('group name differentiates meetups in the same city', () {
    expect(meetup(name: 'Einundzwanzig Augsburg Mitte').groupName,
        'Einundzwanzig Augsburg Mitte');
  });

  test('group name is omitted when absent or identical to city', () {
    expect(meetup().groupName, isNull);
    expect(meetup(name: 'Augsburg').groupName, isNull);
    expect(meetup(name: 'augsburg').groupName, isNull);
  });
}
