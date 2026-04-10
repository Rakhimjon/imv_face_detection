// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'face_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FaceEntity {

 Rect get boundingBox; double? get headEulerAngleX;// Pitch
 double? get headEulerAngleY;// Yaw
 double? get headEulerAngleZ;// Roll
 Map<FaceLandmarkType, Offset> get landmarks; Map<FaceContourType, List<Offset>> get contours; int? get trackingId; double? get smilingProbability; double? get leftEyeOpenProbability; double? get rightEyeOpenProbability; String? get age;// Placeholder for future TFLite model
 String? get gender;
/// Create a copy of FaceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaceEntityCopyWith<FaceEntity> get copyWith => _$FaceEntityCopyWithImpl<FaceEntity>(this as FaceEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaceEntity&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.headEulerAngleX, headEulerAngleX) || other.headEulerAngleX == headEulerAngleX)&&(identical(other.headEulerAngleY, headEulerAngleY) || other.headEulerAngleY == headEulerAngleY)&&(identical(other.headEulerAngleZ, headEulerAngleZ) || other.headEulerAngleZ == headEulerAngleZ)&&const DeepCollectionEquality().equals(other.landmarks, landmarks)&&const DeepCollectionEquality().equals(other.contours, contours)&&(identical(other.trackingId, trackingId) || other.trackingId == trackingId)&&(identical(other.smilingProbability, smilingProbability) || other.smilingProbability == smilingProbability)&&(identical(other.leftEyeOpenProbability, leftEyeOpenProbability) || other.leftEyeOpenProbability == leftEyeOpenProbability)&&(identical(other.rightEyeOpenProbability, rightEyeOpenProbability) || other.rightEyeOpenProbability == rightEyeOpenProbability)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender));
}


@override
int get hashCode => Object.hash(runtimeType,boundingBox,headEulerAngleX,headEulerAngleY,headEulerAngleZ,const DeepCollectionEquality().hash(landmarks),const DeepCollectionEquality().hash(contours),trackingId,smilingProbability,leftEyeOpenProbability,rightEyeOpenProbability,age,gender);

@override
String toString() {
  return 'FaceEntity(boundingBox: $boundingBox, headEulerAngleX: $headEulerAngleX, headEulerAngleY: $headEulerAngleY, headEulerAngleZ: $headEulerAngleZ, landmarks: $landmarks, contours: $contours, trackingId: $trackingId, smilingProbability: $smilingProbability, leftEyeOpenProbability: $leftEyeOpenProbability, rightEyeOpenProbability: $rightEyeOpenProbability, age: $age, gender: $gender)';
}


}

/// @nodoc
abstract mixin class $FaceEntityCopyWith<$Res>  {
  factory $FaceEntityCopyWith(FaceEntity value, $Res Function(FaceEntity) _then) = _$FaceEntityCopyWithImpl;
@useResult
$Res call({
 Rect boundingBox, double? headEulerAngleX, double? headEulerAngleY, double? headEulerAngleZ, Map<FaceLandmarkType, Offset> landmarks, Map<FaceContourType, List<Offset>> contours, int? trackingId, double? smilingProbability, double? leftEyeOpenProbability, double? rightEyeOpenProbability, String? age, String? gender
});




}
/// @nodoc
class _$FaceEntityCopyWithImpl<$Res>
    implements $FaceEntityCopyWith<$Res> {
  _$FaceEntityCopyWithImpl(this._self, this._then);

  final FaceEntity _self;
  final $Res Function(FaceEntity) _then;

/// Create a copy of FaceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? boundingBox = null,Object? headEulerAngleX = freezed,Object? headEulerAngleY = freezed,Object? headEulerAngleZ = freezed,Object? landmarks = null,Object? contours = null,Object? trackingId = freezed,Object? smilingProbability = freezed,Object? leftEyeOpenProbability = freezed,Object? rightEyeOpenProbability = freezed,Object? age = freezed,Object? gender = freezed,}) {
  return _then(_self.copyWith(
boundingBox: null == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as Rect,headEulerAngleX: freezed == headEulerAngleX ? _self.headEulerAngleX : headEulerAngleX // ignore: cast_nullable_to_non_nullable
as double?,headEulerAngleY: freezed == headEulerAngleY ? _self.headEulerAngleY : headEulerAngleY // ignore: cast_nullable_to_non_nullable
as double?,headEulerAngleZ: freezed == headEulerAngleZ ? _self.headEulerAngleZ : headEulerAngleZ // ignore: cast_nullable_to_non_nullable
as double?,landmarks: null == landmarks ? _self.landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as Map<FaceLandmarkType, Offset>,contours: null == contours ? _self.contours : contours // ignore: cast_nullable_to_non_nullable
as Map<FaceContourType, List<Offset>>,trackingId: freezed == trackingId ? _self.trackingId : trackingId // ignore: cast_nullable_to_non_nullable
as int?,smilingProbability: freezed == smilingProbability ? _self.smilingProbability : smilingProbability // ignore: cast_nullable_to_non_nullable
as double?,leftEyeOpenProbability: freezed == leftEyeOpenProbability ? _self.leftEyeOpenProbability : leftEyeOpenProbability // ignore: cast_nullable_to_non_nullable
as double?,rightEyeOpenProbability: freezed == rightEyeOpenProbability ? _self.rightEyeOpenProbability : rightEyeOpenProbability // ignore: cast_nullable_to_non_nullable
as double?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FaceEntity].
extension FaceEntityPatterns on FaceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaceEntity value)  $default,){
final _that = this;
switch (_that) {
case _FaceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _FaceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Rect boundingBox,  double? headEulerAngleX,  double? headEulerAngleY,  double? headEulerAngleZ,  Map<FaceLandmarkType, Offset> landmarks,  Map<FaceContourType, List<Offset>> contours,  int? trackingId,  double? smilingProbability,  double? leftEyeOpenProbability,  double? rightEyeOpenProbability,  String? age,  String? gender)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaceEntity() when $default != null:
return $default(_that.boundingBox,_that.headEulerAngleX,_that.headEulerAngleY,_that.headEulerAngleZ,_that.landmarks,_that.contours,_that.trackingId,_that.smilingProbability,_that.leftEyeOpenProbability,_that.rightEyeOpenProbability,_that.age,_that.gender);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Rect boundingBox,  double? headEulerAngleX,  double? headEulerAngleY,  double? headEulerAngleZ,  Map<FaceLandmarkType, Offset> landmarks,  Map<FaceContourType, List<Offset>> contours,  int? trackingId,  double? smilingProbability,  double? leftEyeOpenProbability,  double? rightEyeOpenProbability,  String? age,  String? gender)  $default,) {final _that = this;
switch (_that) {
case _FaceEntity():
return $default(_that.boundingBox,_that.headEulerAngleX,_that.headEulerAngleY,_that.headEulerAngleZ,_that.landmarks,_that.contours,_that.trackingId,_that.smilingProbability,_that.leftEyeOpenProbability,_that.rightEyeOpenProbability,_that.age,_that.gender);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Rect boundingBox,  double? headEulerAngleX,  double? headEulerAngleY,  double? headEulerAngleZ,  Map<FaceLandmarkType, Offset> landmarks,  Map<FaceContourType, List<Offset>> contours,  int? trackingId,  double? smilingProbability,  double? leftEyeOpenProbability,  double? rightEyeOpenProbability,  String? age,  String? gender)?  $default,) {final _that = this;
switch (_that) {
case _FaceEntity() when $default != null:
return $default(_that.boundingBox,_that.headEulerAngleX,_that.headEulerAngleY,_that.headEulerAngleZ,_that.landmarks,_that.contours,_that.trackingId,_that.smilingProbability,_that.leftEyeOpenProbability,_that.rightEyeOpenProbability,_that.age,_that.gender);case _:
  return null;

}
}

}

/// @nodoc


class _FaceEntity implements FaceEntity {
  const _FaceEntity({required this.boundingBox, required this.headEulerAngleX, required this.headEulerAngleY, required this.headEulerAngleZ, required final  Map<FaceLandmarkType, Offset> landmarks, final  Map<FaceContourType, List<Offset>> contours = const {}, this.trackingId, this.smilingProbability = 0.0, this.leftEyeOpenProbability = 0.0, this.rightEyeOpenProbability = 0.0, this.age, this.gender}): _landmarks = landmarks,_contours = contours;
  

@override final  Rect boundingBox;
@override final  double? headEulerAngleX;
// Pitch
@override final  double? headEulerAngleY;
// Yaw
@override final  double? headEulerAngleZ;
// Roll
 final  Map<FaceLandmarkType, Offset> _landmarks;
// Roll
@override Map<FaceLandmarkType, Offset> get landmarks {
  if (_landmarks is EqualUnmodifiableMapView) return _landmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_landmarks);
}

 final  Map<FaceContourType, List<Offset>> _contours;
@override@JsonKey() Map<FaceContourType, List<Offset>> get contours {
  if (_contours is EqualUnmodifiableMapView) return _contours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_contours);
}

@override final  int? trackingId;
@override@JsonKey() final  double? smilingProbability;
@override@JsonKey() final  double? leftEyeOpenProbability;
@override@JsonKey() final  double? rightEyeOpenProbability;
@override final  String? age;
// Placeholder for future TFLite model
@override final  String? gender;

/// Create a copy of FaceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaceEntityCopyWith<_FaceEntity> get copyWith => __$FaceEntityCopyWithImpl<_FaceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaceEntity&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.headEulerAngleX, headEulerAngleX) || other.headEulerAngleX == headEulerAngleX)&&(identical(other.headEulerAngleY, headEulerAngleY) || other.headEulerAngleY == headEulerAngleY)&&(identical(other.headEulerAngleZ, headEulerAngleZ) || other.headEulerAngleZ == headEulerAngleZ)&&const DeepCollectionEquality().equals(other._landmarks, _landmarks)&&const DeepCollectionEquality().equals(other._contours, _contours)&&(identical(other.trackingId, trackingId) || other.trackingId == trackingId)&&(identical(other.smilingProbability, smilingProbability) || other.smilingProbability == smilingProbability)&&(identical(other.leftEyeOpenProbability, leftEyeOpenProbability) || other.leftEyeOpenProbability == leftEyeOpenProbability)&&(identical(other.rightEyeOpenProbability, rightEyeOpenProbability) || other.rightEyeOpenProbability == rightEyeOpenProbability)&&(identical(other.age, age) || other.age == age)&&(identical(other.gender, gender) || other.gender == gender));
}


@override
int get hashCode => Object.hash(runtimeType,boundingBox,headEulerAngleX,headEulerAngleY,headEulerAngleZ,const DeepCollectionEquality().hash(_landmarks),const DeepCollectionEquality().hash(_contours),trackingId,smilingProbability,leftEyeOpenProbability,rightEyeOpenProbability,age,gender);

@override
String toString() {
  return 'FaceEntity(boundingBox: $boundingBox, headEulerAngleX: $headEulerAngleX, headEulerAngleY: $headEulerAngleY, headEulerAngleZ: $headEulerAngleZ, landmarks: $landmarks, contours: $contours, trackingId: $trackingId, smilingProbability: $smilingProbability, leftEyeOpenProbability: $leftEyeOpenProbability, rightEyeOpenProbability: $rightEyeOpenProbability, age: $age, gender: $gender)';
}


}

/// @nodoc
abstract mixin class _$FaceEntityCopyWith<$Res> implements $FaceEntityCopyWith<$Res> {
  factory _$FaceEntityCopyWith(_FaceEntity value, $Res Function(_FaceEntity) _then) = __$FaceEntityCopyWithImpl;
@override @useResult
$Res call({
 Rect boundingBox, double? headEulerAngleX, double? headEulerAngleY, double? headEulerAngleZ, Map<FaceLandmarkType, Offset> landmarks, Map<FaceContourType, List<Offset>> contours, int? trackingId, double? smilingProbability, double? leftEyeOpenProbability, double? rightEyeOpenProbability, String? age, String? gender
});




}
/// @nodoc
class __$FaceEntityCopyWithImpl<$Res>
    implements _$FaceEntityCopyWith<$Res> {
  __$FaceEntityCopyWithImpl(this._self, this._then);

  final _FaceEntity _self;
  final $Res Function(_FaceEntity) _then;

/// Create a copy of FaceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? boundingBox = null,Object? headEulerAngleX = freezed,Object? headEulerAngleY = freezed,Object? headEulerAngleZ = freezed,Object? landmarks = null,Object? contours = null,Object? trackingId = freezed,Object? smilingProbability = freezed,Object? leftEyeOpenProbability = freezed,Object? rightEyeOpenProbability = freezed,Object? age = freezed,Object? gender = freezed,}) {
  return _then(_FaceEntity(
boundingBox: null == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as Rect,headEulerAngleX: freezed == headEulerAngleX ? _self.headEulerAngleX : headEulerAngleX // ignore: cast_nullable_to_non_nullable
as double?,headEulerAngleY: freezed == headEulerAngleY ? _self.headEulerAngleY : headEulerAngleY // ignore: cast_nullable_to_non_nullable
as double?,headEulerAngleZ: freezed == headEulerAngleZ ? _self.headEulerAngleZ : headEulerAngleZ // ignore: cast_nullable_to_non_nullable
as double?,landmarks: null == landmarks ? _self._landmarks : landmarks // ignore: cast_nullable_to_non_nullable
as Map<FaceLandmarkType, Offset>,contours: null == contours ? _self._contours : contours // ignore: cast_nullable_to_non_nullable
as Map<FaceContourType, List<Offset>>,trackingId: freezed == trackingId ? _self.trackingId : trackingId // ignore: cast_nullable_to_non_nullable
as int?,smilingProbability: freezed == smilingProbability ? _self.smilingProbability : smilingProbability // ignore: cast_nullable_to_non_nullable
as double?,leftEyeOpenProbability: freezed == leftEyeOpenProbability ? _self.leftEyeOpenProbability : leftEyeOpenProbability // ignore: cast_nullable_to_non_nullable
as double?,rightEyeOpenProbability: freezed == rightEyeOpenProbability ? _self.rightEyeOpenProbability : rightEyeOpenProbability // ignore: cast_nullable_to_non_nullable
as double?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
