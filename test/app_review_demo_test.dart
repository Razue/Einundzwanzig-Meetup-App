import 'package:flutter_test/flutter_test.dart';

import 'package:einundzwanzig_meetup_app/services/app_review_demo.dart';

void main() {
  test('Demo-QR nur mit dem Apple-Review-Payload', () {
    expect(AppReviewDemo.matches('21review:einundzwanzig-meetup-demo'), isTrue);
    expect(AppReviewDemo.matches(' 21review:einundzwanzig-meetup-demo '), isTrue);
    expect(AppReviewDemo.matches('21:something'), isFalse);
    expect(AppReviewDemo.matches(null), isFalse);
  });
}
