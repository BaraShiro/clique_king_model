import 'package:bloc/bloc.dart';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:meta/meta.dart';
import 'package:fpdart/fpdart.dart';

@immutable
sealed class CliqueEvent {}

final class CliqueLoad extends CliqueEvent {
  final String id;

  CliqueLoad({required this.id});
}

final class CliqueIncreaseScore extends CliqueEvent {}

@immutable
sealed class CliqueState {}

final class CliqueInitial extends CliqueState {}

final class CliqueLoadingInProgress extends CliqueState {}

final class CliqueLoadingSuccess extends CliqueState {
  final Clique clique;
  final List<Score> allScoresSorted;

  CliqueLoadingSuccess({
    required this.clique,
    required this.allScoresSorted,
  });
}

final class CliqueLoadingFailure extends CliqueState {}

final class CliqueBloc extends Bloc<CliqueEvent, CliqueState> {
  final UserRepository _userRepo; // passed in so it can be easily mocked
  final CliqueRepository _cliqueRepo; // passed in so it can be easily mocked

  CliqueBloc(
      {required UserRepository userRepository,
      required CliqueRepository cliqueRepository})
      : _userRepo = userRepository,
        _cliqueRepo = cliqueRepository,
        super(CliqueInitial()) {
    on<CliqueEvent>(
      (event, emit) async {
        switch (event) {
          case CliqueLoad():
          // TODO: Handle this case.
          case CliqueIncreaseScore():
          // TODO: Handle this case.
          // TODO: This is definitely up to you.
          //       What kind of action in the app should Increase Score?
        }
      },
    );
  }
}
