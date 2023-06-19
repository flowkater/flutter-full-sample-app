import 'package:actual/common/const/data.dart';
import 'package:actual/common/providers/providers.dart';
import 'package:actual/restaurant/model/cursor_pagination_model.dart';
import 'package:actual/restaurant/model/pagination_params.dart';
import 'package:actual/restaurant/repository/restaurant_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final dio = ref.watch(dioProvider);

  final repository = RestaurantRepository(dio, baseUrl: '$hostIp/restaurant');

  return repository;
});

final restaurantProvider =
    StateNotifierProvider<RestaurantStateNotifier, CursorPaginationBase>((ref) {
  final repository = ref.watch(restaurantRepositoryProvider);

  return RestaurantStateNotifier(repository: repository);
});

class RestaurantStateNotifier extends StateNotifier<CursorPaginationBase> {
  final RestaurantRepository repository;

  RestaurantStateNotifier({required this.repository})
      : super(CursorPaginationLoading()) {
    paginate();
  }

  paginate({
    int fetchCount = 20,
    bool fetchMore = false,
    bool forceRefresh = false,
  }) async {
    try {
      // 5가지 가능성
      // State의 상태
      // [상태가]
      // 1) CursorPagination - 정상적으로 데이터가 있는 상태
      // 2) CursorPaginationLoading - 데이터가 로딩중인 상태 (현재 캐시 없음)
      // 3) CursorPaginationError - 에러가 있는 상태
      // 4) CursorPaginationRefetching - 첫번째 페이지부터 다시 데이터를 가져올때
      // 5) CursorPaginationFetchMore - 추가 데이터를 paginate 해오라는 요청을 받았을때

      // 바로 반환하는 상황
      // 1) hasMore = false (기존 상태에서 이미 다음 데이터가 없다는 값을 들고있다면)
      // 2) 로딩중 - fetchMore: true
      //    fetchMore가 아닐때 - 새로고침의 의도가 있을 수 있다.
      if (state is CursorPagination && !forceRefresh) {
        final pageState = state as CursorPagination;

        if (!pageState.meta.hasMore) {
          return;
        }
      }

      final isLoading = state is CursorPaginationLoading;
      final isRefetching = state is CursorPaginationRefetching;
      final isFetchingMore = state is CursorPaginationFetchingMore;

      if (fetchMore && (isLoading || isRefetching || isFetchingMore)) {
        return;
      }

      PaginationParams paginationParams = PaginationParams(
        count: fetchCount,
      );

      if (fetchMore) {
        final pageState = state as CursorPagination;

        state = CursorPaginationFetchingMore(
          meta: pageState.meta,
          data: pageState.data,
        );

        paginationParams = paginationParams.copyWith(
          after: pageState.data.last.id,
        );
      } else {
        if (state is CursorPagination && !forceRefresh) {
          final pageState = state as CursorPagination;

          state = CursorPaginationRefetching(
            meta: pageState.meta,
            data: pageState.data,
          );
        } else {
          state = CursorPaginationLoading();
        }
      }

      final response = await repository.paginate(
        paginationParams: paginationParams,
      );

      if (state is CursorPaginationFetchingMore) {
        final pageState = state as CursorPaginationFetchingMore;

        state = response.copyWith(data: [
          ...pageState.data,
          ...response.data,
        ]);
      } else {
        state = response;
      }
    } catch (e) {
      print(e.toString());
      state = CursorPaginationError(message: '에러가 발생했습니다.');
    }
  }
}
