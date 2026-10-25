import Flutter
import UIKit

public class LibmpvXplayerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    LibmpvXplayerVideoPlugin.register(with: registrar)
  }
}
