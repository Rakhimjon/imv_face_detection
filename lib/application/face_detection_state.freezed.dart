// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'face_detection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FaceDetectionState {

 BlocStatus get status; List<FaceEntity> get faces;
/// Create a copy of FaceDetectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaceDetectionStateCopyWith<FaceDetectionState> get copyWith => _$FaceDetectionStateCopyWithImpl<FaceDetectionState>(this as FaceDetectionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaceDetectionState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.faces, faces));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(faces));

@override
String toString() {
  return 'FaceDetectionState(status: $status, faces: $faces)';
}


}

/// @nodoc
abstract mixin class $FaceDetectionStateCopyWith<$Res>  {
  factory $FaceDetectionStateCopyWith(FaceDetectionState value, $Res Function(FaceDetectionState) _then) = _$FaceDetectionStateCopyWithImpl;
@useResult
$Res call({
 BlocStatus status, List<FaceEntity> faces
});




}
/// @nodoc
class _$FaceDetectionStateCopyWithImpl<$Res>
    implements $FaceDetectionStateCopyWith<$Res> {
  _$FaceDetectionStateCopyWithImpl(this._self, this._then);

  final FaceDetectionState _self;
  final $Res Function(FaceDetectionState) _then;

/// Create a copy of FaceDetectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? faces = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BlocStatus,faces: null == faces ? _self.faces : faces // ignore: cast_nullable_to_non_nullable
as List<FaceEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [FaceDetectionState].
extension FaceDetectionStatePatterns on FaceDetectionState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaceDetectionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaceDetectionState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaceDetectionState value)  $default,){
final _that = this;
switch (_that) {
case _FaceDetectionState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaceDetectionState value)?  $default,){
final _that = this;
switch (_that) {
case _FaceDetectionState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BlocStatus status,  List<FaceEntity> faces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaceDetectionState() when $default != null:
return $default(_that.status,_that.faces);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BlocStatus status,  List<FaceEntity> faces)  $default,) {final _that = this;
switch (_that) {
case _FaceDetectionState():
return $default(_that.status,_that.faces);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BlocStatus status,  List<FaceEntity> faces)?  $default,) {final _that = this;
switch (_that) {
case _FaceDetectionState() when $default != null:
return $default(_that.status,_that.faces);case _:
  return null;

}
}

}

/// @nodoc


class _FaceDetectionState implements FaceDetectionState {
  const _FaceDetectionState({this.status = const BlocStatus(), final  List<FaceEntity> faces = const []}): _faces = faces;
  

@override@JsonKey() final  BlocStatus status;
 final  List<FaceEntity> _faces;
@override@JsonKey() List<FaceEntity> get faces {
  if (_faces is EqualUnmodifiableListView) return _faces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_faces);
}


/// Create a copy of FaceDetectionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaceDetectionStateCopyWith<_FaceDetectionState> get copyWith => __$FaceDetectionStateCopyWithImpl<_FaceDetectionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaceDetectionState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._faces, _faces));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_faces));

@override
String toString() {
  return 'FaceDetectionState(status: $status, faces: $faces)';
}


}

/// @nodoc
abstract mixin class _$FaceDetectionStateCopyWith<$Res> implements $FaceDetectionStateCopyWith<$Res> {
  factory _$FaceDetectionStateCopyWith(_FaceDetectionState value, $Res Function(_FaceDetectionState) _then) = __$FaceDetectionStateCopyWithImpl;
@override @useResult
$Res call({
 BlocStatus status, List<FaceEntity> faces
});




}
/// @nodoc
class __$FaceDetectionStateCopyWithImpl<$Res>
    implements _$FaceDetectionStateCopyWith<$Res> {
  __$FaceDetectionStateCopyWithImpl(this._self, this._then);

  final _FaceDetectionState _self;
  final $Res Function(_FaceDetectionState) _then;

/// Create a copy of FaceDetectionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? faces = null,}) {
  return _then(_FaceDetectionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BlocStatus,faces: null == faces ? _self._faces : faces // ignore: cast_nullable_to_non_nullable
as List<FaceEntity>,
  ));
}


}

// dart format on
