import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

/// Web (browser) implementation of [TscPrinter] using the WebUSB API.
///
/// The TSC TE244 is driven with TSPL commands sent over a bulk OUT endpoint.
///
/// IMPORTANT — WebUSB and the printer-class blocklist:
/// Browsers refuse to `claimInterface` on interfaces whose class is one of the
/// protected classes, and USB Printer class (0x07) is on that list. If the
/// TE244 enumerates as a standard USB printer the browser throws a
/// SecurityError and there is no way around it from JavaScript. The fix is to
/// bind the printer to a generic/WinUSB driver (e.g. with Zadig on Windows) so
/// it exposes a vendor-specific interface (class 0xFF), which WebUSB can claim.
/// This code looks for such an interface first and falls back to interface 0.
class TscPrinter {
  /// Builds a 50mm x 30mm TSPL test label and sends it to a user-selected
  /// USB printer. Throws with a human-readable message on any failure.
  static Future<void> printTestLabel() async {
    final usb = _navigator.usb;
    if (usb == null) {
      throw UnsupportedError(
        'WebUSB is not supported by this browser. Use a recent Chrome/Edge '
        'over HTTPS (or localhost).',
      );
    }

    // Prompts the user to pick the printer. Empty filters lists every device
    // since the exact VID/PID of the TE244 may vary by interface module.
    final _USBDevice device;
    try {
      device = await usb
          .requestDevice(
            _USBDeviceRequestOptions(filters: <_USBDeviceFilter>[].toJS),
          )
          .toDart;
    } catch (e) {
      throw StateError('No printer selected ($e).');
    }

    try {
      await device.open().toDart;
    } catch (e) {
      throw StateError(
        'Could not open the printer. On Windows this means the TE244 is bound '
        'to its vendor/usbprint driver, which WebUSB cannot use. Replace its '
        'driver with WinUSB (run Zadig, select the TSC device, install '
        'WinUSB), then reconnect and try again. ($e)',
      );
    }
    try {
      if (device.configuration == null) {
        await device.selectConfiguration(1).toDart;
      }

      final target = _findOutEndpoint(device);
      if (target == null) {
        throw StateError(
          'Could not find a USB OUT endpoint on the selected device.',
        );
      }

      try {
        await device.claimInterface(target.interfaceNumber).toDart;
      } catch (e) {
        throw StateError(
          'The browser blocked access to this printer interface. The TE244 is '
          'likely enumerating as a USB printer (class 0x07), which WebUSB does '
          'not allow. Bind it to a WinUSB/libusb driver (e.g. via Zadig) and '
          'try again. ($e)',
        );
      }

      final tspl = _buildTestLabelTag();
      await device.transferOut(target.endpointNumber, tspl.toJS).toDart;
    } finally {
      await device.close().toDart;
    }
  }

  /// Walks the device's interfaces and returns the first bulk/interrupt OUT
  /// endpoint, preferring a vendor-specific interface (class 0xFF) which
  /// WebUSB is allowed to claim.
  static _OutEndpoint? _findOutEndpoint(_USBDevice device) {
    final config = device.configuration;
    if (config == null) return null;

    _OutEndpoint? fallback;
    for (final iface in config.interfaces.toDart) {
      final alt = iface.alternate;
      for (final ep in alt.endpoints.toDart) {
        if (ep.direction == 'out') {
          final candidate = _OutEndpoint(
            interfaceNumber: iface.interfaceNumber,
            endpointNumber: ep.endpointNumber,
          );
          if (alt.interfaceClass == 0xFF) return candidate;
          fallback ??= candidate;
        }
      }
    }
    return fallback;
  }
  static Uint8List _buildTestLabelTag() {
    final commands = StringBuffer()
      ..writeln('SIZE 100 mm,15 mm')
      ..writeln('GAP 2 mm,0 mm')
      ..writeln('DIRECTION 1')
      ..writeln('CLS')
      ..writeln('QRCODE 30,40 https://www.google.com')
      ..writeln('TEXT 100,40,"2",0,1,1,"ZOMO JEWELLERS"')
      ..writeln('TEXT 100,70,"2",0,0,0,"Ring 91.6 carat gold"')
      ..writeln('TEXT 100,90,"2",0,1,0,"Gross 4.6789g"')
      ..writeln('TEXT 100,100,"2",0,1,1,"Net 4.3456g"')
      ..writeln('PRINT 1,1');
    return Uint8List.fromList(latin1.encode(commands.toString()));
  }

  static Uint8List _buildTestLabelTagYuktha() {
    final commands = StringBuffer()
      ..writeln('SIZE 100 mm,15 mm')
      ..writeln('GAP 2 mm,0 mm')
      ..writeln('DIRECTION 1')
      ..writeln('CLS')
      ..writeln('TEXT 35,45,"3",0,1,1,"YUKTHA GATTU   Section 3A"')
      ..writeln('TEXT 35,75,"2",0,1,1,"Father 9985319822 Mother 9052736741"')
      ..writeln('TEXT 35,100,"2",0,1,1,"Orchids International School, Uppal"')
      ..writeln('PRINT 1,1');
    return Uint8List.fromList(latin1.encode(commands.toString()));
  }

  /// TSPL program for a 50mm x 30mm label on a 203-dpi TE244.
  static Uint8List _buildTestLabel() {
    final commands = StringBuffer()
      ..writeln('SIZE 50 mm,30 mm')
      ..writeln('GAP 2 mm,0 mm')
      ..writeln('DIRECTION 1')
      ..writeln('CLS')
      ..writeln('TEXT 30,40,"2",0,1,1,"ZOMO JEWELLERS"')
      ..writeln('TEXT 30,63,"2",0,1,1,"Ring 91.6 carat gold"')
      ..writeln('TEXT 30,90,"2",0,1,1,"Gross 4.6789g"')
      ..writeln('TEXT 30,120,"2",0,1,1,"Net 4.3456g"')
      // ..writeln('TEXT 30,70,"2",0,1,1,"TSC TE244 Test Print"')
      // ..writeln('TEXT 30,110,"1",0,1,1,"Label 50mm x 30mm"')
      ..writeln('BARCODE 30,150,"128",60,1,0,2,2,"881771918"')
      ..writeln('PRINT 1,1');
    return Uint8List.fromList(latin1.encode(commands.toString()));
  }
}

class _OutEndpoint {
  const _OutEndpoint({
    required this.interfaceNumber,
    required this.endpointNumber,
  });

  final int interfaceNumber;
  final int endpointNumber;
}

// --- Minimal WebUSB JS-interop bindings ------------------------------------

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _USB? get usb;
}

extension type _USB._(JSObject _) implements JSObject {
  external JSPromise<_USBDevice> requestDevice(_USBDeviceRequestOptions options);
}

extension type _USBDeviceRequestOptions._(JSObject _) implements JSObject {
  external factory _USBDeviceRequestOptions({JSArray<_USBDeviceFilter> filters});
}

extension type _USBDeviceFilter._(JSObject _) implements JSObject {
  external factory _USBDeviceFilter();
}

extension type _USBDevice._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> open();
  external JSPromise<JSAny?> selectConfiguration(int configurationValue);
  external JSPromise<JSAny?> claimInterface(int interfaceNumber);
  external JSPromise<JSAny?> transferOut(int endpointNumber, JSAny data);
  external JSPromise<JSAny?> close();
  external _USBConfiguration? get configuration;
}

extension type _USBConfiguration._(JSObject _) implements JSObject {
  external JSArray<_USBInterface> get interfaces;
}

extension type _USBInterface._(JSObject _) implements JSObject {
  external int get interfaceNumber;
  external _USBAlternateInterface get alternate;
}

extension type _USBAlternateInterface._(JSObject _) implements JSObject {
  external int get interfaceClass;
  external JSArray<_USBEndpoint> get endpoints;
}

extension type _USBEndpoint._(JSObject _) implements JSObject {
  external int get endpointNumber;
  external String get direction;
}
