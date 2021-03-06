library preference;

import 'package:built_value/built_value.dart';
import 'package:yaga/model/preferences/serializable_preference.dart';
import 'package:yaga/model/preferences/serializers/base_type_serializer.dart';
import 'package:yaga/model/preferences/value_preference.dart';

part 'choice_preference.g.dart';

abstract class ChoicePreference
    with BaseTypeSerializer<String, ChoicePreference>
    implements
        SerializablePreference<String, String, ChoicePreference>,
        Built<ChoicePreference, ChoicePreferenceBuilder> {
  Map<String, String> get choices;

  static void _initializeBuilder(ChoicePreferenceBuilder b) =>
      ValuePreference.initBuilder(b);

  factory ChoicePreference([void Function(ChoicePreferenceBuilder) updates]) =
      _$ChoicePreference;
  ChoicePreference._();
}
