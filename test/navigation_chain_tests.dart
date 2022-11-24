import 'package:flutter_test/flutter_test.dart';
import 'package:siberian_core/siberian_core.dart';

void main() {
  test("good path", () {
    var chain = NavigationChain("/test");
  });

  test("is last", () {
    var chain = NavigationChain("/test");
    assert(!chain.canAdvance);
  });

  test("must not be last", () {
    var chain = NavigationChain("/first/second");
    assert(chain.canAdvance);
  });

  test("should fail tage", () {
    var chain = NavigationChain("/");
    expect(() => chain.takeArgument(), throwsA(isA<ReachedEndException>()));
  });

  test("should take argument", () {
    var chain = NavigationChain("/first/second");
    var argument = chain.takeArgument();
    assert(argument == 'first');
  });

  test("should take 2+ arguments", () {
    var chain = NavigationChain("/list/22/details");
    var first = chain.takeArgument();
    assert(first == 'list');
    var id = chain.takeArgument();
    assert(id == '22');
  });

  test("should fail last advance", () {
    var chain = NavigationChain("/test?success=true");
    assert(!chain.canAdvance);
    var advanced = chain.advance();
    assert(advanced == null);
  });

  test("should advance", () {
    var chain = NavigationChain("https://spar.westpower.ru/profile/settings?success=true");
    assert(chain.canAdvance);
    var advanced = chain.advance();

    assert(advanced != null);
    assert(advanced!.path == '/settings?success=true');
    assert(!advanced!.canAdvance);
  });

  test("check argument passing", () {
    var chain = NavigationChain("/profile/settings?success=true");
    assert(chain.canAdvance);
    var advanced = chain.advance();

    assert(advanced != null);
    assert(advanced!.queryParameters['success'] == 'true');
  });

  test("non-empty route name check", () {
    var chain = NavigationChain("/profile");
    assert(chain.route == '/profile');
  });

  test("empty route name check", () {
    var chain = NavigationChain("");
    assert(chain.route == '/');
  });

  test("complete in advance", () {
    var chain = NavigationChain("/test");
    assert(!chain.canAdvance);
    var next = chain.advance();
    assert(next == null);
  });

  test("complete in complex advance", () {
    var chain = NavigationChain("/first/second?q=1");
    assert(chain.canAdvance);
    var next = chain.advance();
    assert(next != null);
    assert(!next!.canAdvance);
  });
}
