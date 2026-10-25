// Run with the application host; Android selects a separate probe app ID.
import '../packages/xplayer_player/tool/playback_device_probe.dart' as probe;
import 'application_playback_probe.dart' as application;

void main() {
  if (const bool.fromEnvironment('PLAYBACK_PROBE_APPLICATION')) {
    application.main();
  } else {
    probe.main();
  }
}
