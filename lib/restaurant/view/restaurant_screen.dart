import 'package:actual/common/component/restaurant_card.dart';
import 'package:actual/common/const/data.dart';
import 'package:actual/common/dio/dio.dart';
import 'package:actual/common/view/restaurant_detail_screen.dart';
import 'package:actual/restaurant/model/cursor_pagination_model.dart';
import 'package:actual/restaurant/repository/restaurant_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({super.key});

  Future<CursorPagination> paginateRestaurant() async {
    final dio = Dio();

    dio.interceptors.add(
      CustomInterceptor(
        storage: storage,
      ),
    );

    final repository = RestaurantRepository(dio, baseUrl: '$hostIp/restaurant');

    return repository.paginate();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FutureBuilder<CursorPagination>(
            future: paginateRestaurant(),
            builder: (context, AsyncSnapshot<CursorPagination> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    snapshot.error.toString(),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Container(
                  child: const CircularProgressIndicator(),
                );
              }

              return ListView.separated(
                separatorBuilder: (_, index) => const SizedBox(
                  height: 16.0,
                ),
                itemCount: snapshot.data!.data.length,
                itemBuilder: (_, index) {
                  final item = snapshot.data!.data[index];

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
              );
            },
          ),
        ),
      ),
    );
  }
}
