import 'dart:ffi';

final class ConfidenceResponseStruct extends Struct {
  @Uint32()
  external int block;

  @Float()
  external double confidence;

  // ignore: non_constant_identifier_names
  external Pointer<Uint8> serialised_confidence;
}
