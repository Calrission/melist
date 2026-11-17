import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:melist/presentation/theme/palette.dart';
import 'package:melist/presentation/widgets/wishlist_tile.dart';
import 'package:melist_core/melist_core.dart';

const _wishlist = WishlistModel(id: 1, ownerId: 2, name: 'Birthday');

void main() {
  testWidgets(
    'keeps the filled icon when the parent updates isFavorite during the request',
    (tester) async {
      final release = Completer<void>();

      await tester.pumpWidget(_Host(release: release, publishDuringRequest: true));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      release.complete();
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    },
  );

  testWidgets(
    'toggles locally when the parent leaves isFavorite unchanged',
    (tester) async {
      await tester.pumpWidget(const _Host());

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    },
  );

  testWidgets('does not toggle when the request fails', (tester) async {
    await tester.pumpWidget(const _Host(succeeds: false));

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}

class _Host extends StatefulWidget {
  const _Host({
    this.release,
    this.publishDuringRequest = false,
    this.succeeds = true,
  });

  final Completer<void>? release;
  final bool publishDuringRequest;
  final bool succeeds;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Palette.light().themeData,
      home: Scaffold(
        body: WishListTile(
          wishlistModel: _wishlist,
          showFavoriteAction: true,
          showEdit: false,
          isFavorite: _isFavorite,
          onToggleFavorite: (current) async {
            final release = widget.release;
            if (widget.publishDuringRequest) {
              setState(() => _isFavorite = !current);
            }
            if (release != null) {
              await release.future;
            }
            return widget.succeeds;
          },
        ),
      ),
    );
  }
}
