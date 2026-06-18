/// Cross-platform entry point for printing to a TSC TE244 label printer.
///
/// The printer is driven with TSPL (TSC Printer Language). On the web build the
/// implementation talks to the printer over WebUSB; on every other platform the
/// stub throws [UnsupportedError]. The correct implementation is selected at
/// compile time via the conditional export below, so mobile/desktop builds keep
/// compiling even though they pull in no `dart:js_interop` code.
library;

export 'tsc_printer_stub.dart'
    if (dart.library.js_interop) 'tsc_printer_web.dart';
