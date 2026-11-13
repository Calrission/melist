import 'package:material_ui/material_ui.dart';

enum ControllerState { init, loading, loaded, error }

abstract class BaseController<T> extends ChangeNotifier{
  BaseController({
    this._state = ControllerState.init
  });

  ControllerState _state;
  ControllerState get state => _state;
  set state(ControllerState newState) {
    emit(newState);
  }

  T? _data;
  T? get data => _data;
  set data(T newData) {
    _data = newData;
    emit(ControllerState.loaded);
  }

  Object? _error;
  Object? get error => _error;
  set error(Object err) {
    setError(err);
  }

  @protected
  void setError(Object error, {bool silence = false, bool changeState = true}){
    _error = error;
    if (changeState) {
      _state = ControllerState.error;
    }
    if (!silence) {
      notifyListeners();
    }
  }

  @protected
  void emit(ControllerState newState) {
    _state = newState;
    notifyListeners();
  }

  void reset({bool silence = false}) {
    _data = null;
    _error = null;
    _state = ControllerState.init;
    if (!silence) {
      notifyListeners();
    }
  }
}