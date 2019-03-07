import 'package:flock/flock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:observable_state_lifecycle/observable_state_lifecycle.dart';

import '../MathEvent.dart';

void main() {
  group('ObserveStore', () {
    testWidgets('should render child widget', (tester) async {
      final store = createStore<MathEvent>();
      await tester.pumpWidget(Test(store: store, onRender: () {}));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should update child widget iff projection updates',
        (tester) async {
      final store = createStore<MathEvent>();
      var renderCount = 0;
      await tester.pumpWidget(Test(
          store: store,
          onRender: () {
            renderCount++;
          }));
      expect(find.text('0'), findsOneWidget);
      expect(renderCount, 1);
      store.publish(Plus(1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(renderCount, 2);
      store.publish(Plus(0));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(renderCount, 2);
    });
  });
}

class Test extends StatefulWidget {
  Test({this.store, this.onRender});

  final Store<MathEvent> store;
  final VoidCallback onRender;

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> with ObservableStateLifecycle<Test> {
  _TestState() : super() {
    addLifecycleObserver(observeStore(
        () => widget.store, sum, (int p) => setState(() => result = p)));
  }

  int result;

  @override
  Widget build(BuildContext context) {
    widget.onRender();
    return Text(result.toString(), textDirection: TextDirection.ltr);
  }
}
