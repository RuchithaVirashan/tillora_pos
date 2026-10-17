import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// `DOC_INFO_1W` from winspool.
final class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

/// Sends bytes straight to a Windows printer queue as a RAW job, bypassing
/// the driver's page layout. Receipt printers read ESC/POS commands this
/// way, such as the pulse that opens a cash drawer.
abstract final class WindowsRawPrinter {
  static bool get isSupported => Platform.isWindows;

  static final _lib = DynamicLibrary.open('winspool.drv');

  static final _open = _lib.lookupFunction<
    Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>),
    int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>)
  >('OpenPrinterW');

  static final _startDoc = _lib.lookupFunction<
    Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>),
    int Function(int, int, Pointer<_DocInfo1>)
  >('StartDocPrinterW');

  static final _write = _lib.lookupFunction<
    Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>),
    int Function(int, Pointer<Void>, int, Pointer<Uint32>)
  >('WritePrinter');

  static int Function(int) _handleCall(String name) => _lib.lookupFunction<Int32 Function(IntPtr), int Function(int)>(name);

  static final _startPage = _handleCall('StartPagePrinter');
  static final _endPage = _handleCall('EndPagePrinter');
  static final _endDoc = _handleCall('EndDocPrinter');
  static final _close = _handleCall('ClosePrinter');

  /// Writes [bytes] to [printer] (its Windows name) as one RAW job.
  static void send(String printer, Uint8List bytes, {String job = 'Tillora'}) {
    final name = printer.toNativeUtf16();
    final docName = job.toNativeUtf16();
    final dataType = 'RAW'.toNativeUtf16();
    final handle = calloc<IntPtr>();
    final doc = calloc<_DocInfo1>();
    final data = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    try {
      if (_open(name, handle, nullptr) == 0) throw PrinterException('Printer "$printer" could not be opened');
      final h = handle.value;
      try {
        doc.ref
          ..pDocName = docName
          ..pOutputFile = nullptr
          ..pDatatype = dataType;
        if (_startDoc(h, 1, doc) == 0) throw PrinterException('Printer "$printer" did not accept the job');
        try {
          _startPage(h);
          data.asTypedList(bytes.length).setAll(0, bytes);
          final ok = _write(h, data.cast(), bytes.length, written) != 0;
          _endPage(h);
          if (!ok || written.value != bytes.length) throw PrinterException('Printer "$printer" did not take all the data');
        } finally {
          _endDoc(h);
        }
      } finally {
        _close(h);
      }
    } finally {
      for (final p in <Pointer>[name, docName, dataType, handle, doc, data, written]) {
        calloc.free(p);
      }
    }
  }
}

/// A printer problem with a message fit to show staff.
class PrinterException implements Exception {
  const PrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}
