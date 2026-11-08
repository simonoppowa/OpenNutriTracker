part of 'favourite_toggle_bloc.dart';

class FavouriteToggleState extends Equatable {
  final bool isFavourite;

  const FavouriteToggleState({this.isFavourite = false});

  @override
  List<Object?> get props => [isFavourite];
}
