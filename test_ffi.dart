import 'dart:ffi';
import 'package:ffi/ffi.dart';

void main() {
  // Test to check correct method name for Pointer<Utf8> to String conversion
  final testPtr = "Hello".toNativeUtf8();
  
  // Try different methods to see which works
  try {
    print("Method 1: ${testPtr.toDartString()}");
  } catch (e) {
    print("toDartString() failed: $e");
  }
  
  try {
    print("Method 2: ${testPtr.toString()}");
  } catch (e) {
    print("toString() failed: $e");
  }
  
  calloc.free(testPtr);
}
