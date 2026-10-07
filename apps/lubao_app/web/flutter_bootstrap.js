// Flutter Web без Google (020 часть А, 043 п.8): движок CanvasKit и
// запасные шрифты — со своего сервера, не с www.gstatic.com /
// fonts.gstatic.com (в Китае заблокированы, и в КЗ так быстрее).
// Китайские иероглифы — из вшитого Noto Sans SC (lubao_core assets).
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
    fontFallbackBaseUrl: "fonts/fallback/",
  },
});
