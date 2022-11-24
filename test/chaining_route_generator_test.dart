import 'package:flutter_test/flutter_test.dart';
import 'package:siberian_core/src/navigation/custom_route_generator.dart';

void main() {
  test("simple route", () {
    var gen = ChainingRouteGenerator();
    var description = gen.generate("/test");

    assert(description != null);
    assert(description.arguments == null);
    assert(description.screenRoute == '/test');
  });

  test("complex route / no params", () {
    var gen = ChainingRouteGenerator();
    var description = gen.generate("/first/second/third");

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.navigationPath == '/second/third');
  });

  test("simple route / with params", () {
    var gen = ChainingRouteGenerator();
    var args = {"success": true};
    var description = gen.generate("/first", originalArguments: args);

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.navigationPath == null);
    assert(description.arguments!.passedArguments == args);
  });

  test("simple route / with route params", () {
    var gen = ChainingRouteGenerator();
    var description = gen.generate("/first?success=true");

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == null);
    assert(description.arguments!.navigationPath == null);
    assert(description.arguments!.queryParameters!['success'] == 'true');
  });

  test("complex route / with params", () {
    var gen = ChainingRouteGenerator();
    var description = gen.generate("/first/second/third", originalArguments: true);

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == true);
    assert(description.arguments!.queryParameters!.isEmpty);
    assert(description.arguments!.navigationPath == '/second/third');
  });

  test("complex route / with route params", () {
    var gen = ChainingRouteGenerator();
    var description = gen.generate("/first/second/third?success=true");

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == null);
    assert(description.arguments!.queryParameters!['success'] == 'true');
    assert(description.arguments!.navigationPath == '/second/third?success=true');
  });

  test("complex route / with route and original params", () {
    var gen = ChainingRouteGenerator();
    var args = {"query": "post"};
    var description = gen.generate("/first/second/third?success=true", originalArguments: args);

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == args);
    assert(description.arguments!.queryParameters!['success'] == 'true');
    assert(description.arguments!.navigationPath == '/second/third?success=true');
  });

  test("complex route / advance /  with route and original params", () {
    var gen = ChainingRouteGenerator();
    var args = {"query": "post"};
    var description = gen.generate("/first/second/third?success=true", originalArguments: args);

    assert(description != null);
    assert(description.screenRoute == '/first');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == args);
    assert(description.arguments!.queryParameters?['success'] == 'true');
    assert(description.arguments!.navigationPath == '/second/third?success=true');

    description =
        gen.generate(description.arguments!.navigationPath!, originalArguments: description.arguments!.passedArguments);

    assert(description != null);
    assert(description.screenRoute == '/second');
    assert(description.arguments != null);
    assert(description.arguments!.passedArguments == args);
    assert(description.arguments!.queryParameters?['success'] == 'true');
    assert(description.arguments!.navigationPath == '/third?success=true');
  });
}
