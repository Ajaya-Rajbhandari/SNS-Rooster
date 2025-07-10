// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void setBeforeUnloadHandler(bool Function() shouldWarn) {
  html.window.onBeforeUnload.listen((event) {
    if (shouldWarn()) {
      event.preventDefault();
      (event as html.BeforeUnloadEvent).returnValue = '';
    }
  });
}
