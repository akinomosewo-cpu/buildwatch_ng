import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable { const AppEvent(); @override List<Object?> get props => []; }
class AppStarted extends AppEvent { const AppStarted(); }
class ItemAdded extends AppEvent {
  final Map<String, dynamic> data;
  const ItemAdded(this.data);
  @override List<Object?> get props => [data];
}
class ItemDeleted extends AppEvent {
  final String id; const ItemDeleted(this.id);
  @override List<Object?> get props => [id];
}
class ItemUpdated extends AppEvent {
  final String id; final Map<String, dynamic> data;
  const ItemUpdated(this.id, this.data);
  @override List<Object?> get props => [id, data];
}

abstract class AppState extends Equatable { const AppState(); @override List<Object?> get props => []; }
class AppInitial extends AppState { const AppInitial(); }
class AppLoading extends AppState { const AppLoading(); }
class AppLoaded extends AppState {
  final List<Map<String, dynamic>> items;
  const AppLoaded(this.items);
  @override List<Object?> get props => [items];
}
class AppError extends AppState {
  final String message; const AppError(this.message);
  @override List<Object?> get props => [message];
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppInitial()) {
    on<AppStarted>((e, emit) => emit(const AppLoaded([])));
    on<ItemAdded>((e, emit) {
      if (state is AppLoaded) {
        final current = (state as AppLoaded).items;
        emit(AppLoaded([...current, e.data]));
      }
    });
    on<ItemDeleted>((e, emit) {
      if (state is AppLoaded) {
        emit(AppLoaded((state as AppLoaded).items.where((i) => i['id'] != e.id).toList()));
      }
    });
    on<ItemUpdated>((e, emit) {
      if (state is AppLoaded) {
        emit(AppLoaded((state as AppLoaded).items.map((i) => i['id'] == e.id ? {...i, ...e.data} : i).toList()));
      }
    });
  }
}
