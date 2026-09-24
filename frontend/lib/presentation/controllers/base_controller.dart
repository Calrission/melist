import 'package:flutter/material.dart';

enum ControllerState { init, loading, loaded, error }

abstract class BaseController<T> extends ChangeNotifier{
  BaseController({
    this._state = ControllerState.init
  });

  ControllerState _state;
  ControllerState get state => _state;

  T? _data;
  T? get data => _data;
  set data(T newData) {
    _data = newData;
    emit(ControllerState.loaded);
  }

  Object? _error;
  Object? get error => _error;
  set error(Object err) {
    _error = err;
    emit(ControllerState.error);
  }

  @protected
  void emit(ControllerState newState) {
    _state = newState;
    notifyListeners();
  }
}