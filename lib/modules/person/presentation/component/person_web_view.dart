import 'package:exam/common/component/custom_refresh_indicator.dart';
import 'package:exam/common/theme/extension/app_theme_extension.dart';
import 'package:exam/modules/person/data/di/person_service_locator.dart';
import 'package:exam/modules/person/data/model/output/person.dart';
import 'package:exam/modules/person/presentation/bloc/person_list_bloc.dart';
import 'package:exam/modules/person/presentation/component/person_card.dart';
import 'package:exam/modules/person/presentation/event/person_list_event.dart';
import 'package:exam/modules/person/presentation/screen/person_details_screen.dart';
import 'package:exam/modules/person/presentation/state/person_list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PersonWebView extends StatelessWidget {
  const PersonWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PersonListBloc>(
      create: (_) =>
          PersonListBloc(personRepository)..add(const PersonListRequested()),
      child: const PersonWebViewContent(),
    );
  }
}

class PersonWebViewContent extends StatefulWidget {
  const PersonWebViewContent({super.key});

  @override
  State<PersonWebViewContent> createState() => _PersonWebViewContentState();
}

class _PersonWebViewContentState extends State<PersonWebViewContent> {
  final PagingController<int, Person> _pageController =
      PagingController(firstPageKey: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.sync(() {
      _pageController.refresh();
      context.read<PersonListBloc>().add(const PersonListRefreshed());
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: _onRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocListener<PersonListBloc, PersonListState>(
            listener: (context, state) {
              if (state.error != null) {
                _pageController.error = state.error;
              } else if (!state.hasMore) {
                _pageController.appendLastPage(state.persons);
              } else {
                _pageController.appendPage(state.persons, state.page);
              }
            },
            child: PagedGridView<int, Person>(
              pagingController: _pageController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(context.layout.paddingMedium),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              builderDelegate: PagedChildBuilderDelegate<Person>(
                newPageProgressIndicatorBuilder: (context) {
                  return const _SeeMoreButton();
                },
                itemBuilder: (context, person, index) {
                  return PersonCard.gridView(
                    state: PersonCardUiState(
                      name: person.name,
                      email: person.email,
                      imageUrl: person.image,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return PersonDetailsScreen(person: person);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeMoreButton extends StatelessWidget {
  const _SeeMoreButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<PersonListBloc>().add(const PersonListRequested()),
      child: Card(
        child: Center(
          child: Text(
            'Load more',
            style: context.textStyle.body2,
          ),
        ),
      ),
    );
  }
}
