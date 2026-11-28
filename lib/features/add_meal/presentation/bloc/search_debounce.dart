import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Shared tuning for search-as-you-type across the product and food blocs.
const searchDebounceDuration = Duration(milliseconds: 500);

/// Let saved and cached matches appear while online catalogues are still busy.
const searchFirstResultsDelay = Duration(seconds: 2);

/// Interactive searches must finish even when a provider stalls. Other
/// workflows, including barcode lookup and bulk resolution, keep their own
/// request policies.
const searchRemoteDeadline = Duration(seconds: 10);

/// True when the online result (including an error) arrived before the
/// preview delay. Cancel the timer on quick answers so widget disposal does
/// not leave a pending timer behind.
Future<bool> completedBeforeSearchPreview<T>(Future<T> remote) async {
  final first = Completer<bool>();
  final timer = Timer(searchFirstResultsDelay, () => first.complete(false));
  remote.then(
    (_) {
      if (!first.isCompleted) first.complete(true);
    },
    onError: (Object _) {
      if (!first.isCompleted) first.complete(true);
    },
  );
  final completed = await first.future;
  timer.cancel();
  return completed;
}

/// Minimum trimmed query length before a search runs at all. Shorter (or
/// blank) input doesn't query any source — local or remote — and resets
/// the search blocs to their initial state.
const minQueryLength = 2;

/// Debounce keystrokes, then run the latest one as a restartable handler so an
/// in-flight search is cancelled the moment a newer query arrives. Keeps the
/// remote source to roughly one request per typing pause.
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      restartable<E>().call(events.debounce(duration), mapper);
}
