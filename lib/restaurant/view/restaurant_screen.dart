import 'package:actual/common/component/restaurant_card.dart';
import 'package:actual/common/providers/restaurant_provider.dart';
import 'package:actual/common/view/restaurant_detail_screen.dart';
import 'package:actual/restaurant/model/cursor_pagination_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantScreen extends ConsumerWidget {
  const RestaurantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(restaurantProvider);

    if (data is CursorPaginationLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final cp = data as CursorPagination;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        separatorBuilder: (_, index) => const SizedBox(
          height: 16.0,
        ),
        itemCount: cp.data.length,
        itemBuilder: (_, index) {
          final item = cp.data[index];

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailScreen(
                    id: item.id,
                  ),
                ),
              );
            },
            child: RestaurantCard.fromModel(model: item),
          );
        },
      ),
    );
  }
}
