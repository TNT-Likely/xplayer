/// Native messages can contain authenticated URLs, relative signed requests and
/// headers. Keep one redaction rule for opt-in device and command-line logs.
String redactPlaybackLog(String message) => message
    .replaceAll(RegExp(r'(?:https?|rtmps?|rtsp)://\S+'), '[source URL]')
    .replaceAll(RegExp(r'''\?[^\s'"\]]+'''), '?[query omitted]')
    .replaceAll(
      RegExp(
        r'^(?:.*\b)?(?:authorization|cookie|set-cookie):.*$',
        caseSensitive: false,
        multiLine: true,
      ),
      '[credentials omitted]',
    );
