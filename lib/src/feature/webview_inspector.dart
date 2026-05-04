import '../core/samseer_core.dart';
import '../model/http_call.dart';
import '../model/http_error.dart';
import '../model/http_request.dart';
import '../model/http_response.dart';

/// JavaScript snippet to inject into a WebView page (e.g. via
/// `flutter_inappwebview`'s `initialUserScripts` at document start).
///
/// Monkey-patches `XMLHttpRequest` and `fetch` to forward request, response,
/// and error events to the Dart side via the `samseer_webview` JavaScript
/// handler. Wire the handler to [Samseer.recordWebViewEvent] to surface the
/// captured calls inside the inspector.
///
/// Re-installation is idempotent (guarded by `window.__samseer_installed`).
const String webViewInterceptorScript = r'''
(function () {
  if (window.__samseer_installed) return;
  window.__samseer_installed = true;

  var counter = 0;
  function nextCid() {
    counter += 1;
    return Date.now().toString() + ':' + counter.toString();
  }
  function send(payload) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('samseer_webview', payload);
      }
    } catch (_) {}
  }
  function parseHeaders(raw) {
    var headers = {};
    if (!raw) return headers;
    raw.split('\r\n').forEach(function (line) {
      var idx = line.indexOf(':');
      if (idx > 0) {
        headers[line.substring(0, idx).trim().toLowerCase()] =
          line.substring(idx + 1).trim();
      }
    });
    return headers;
  }
  function bodyToString(body) {
    if (body == null) return null;
    if (typeof body === 'string') return body;
    try { return String(body); } catch (_) { return null; }
  }

  // --- XMLHttpRequest ---
  var XHR = window.XMLHttpRequest;
  if (XHR) {
    function PatchedXHR() {
      var xhr = new XHR();
      var cid = nextCid();
      var meta = { method: 'GET', url: '', headers: {} };

      var origOpen = xhr.open;
      xhr.open = function (method, url) {
        meta.method = method;
        meta.url = url;
        return origOpen.apply(xhr, arguments);
      };
      var origSetHeader = xhr.setRequestHeader;
      xhr.setRequestHeader = function (k, v) {
        meta.headers[String(k).toLowerCase()] = String(v);
        return origSetHeader.apply(xhr, arguments);
      };
      var origSend = xhr.send;
      xhr.send = function (body) {
        send({
          kind: 'req',
          cid: cid,
          method: meta.method,
          url: meta.url,
          headers: meta.headers,
          body: bodyToString(body),
        });
        return origSend.apply(xhr, arguments);
      };
      xhr.addEventListener('load', function () {
        var canReadText = xhr.responseType === '' || xhr.responseType === 'text';
        send({
          kind: 'res',
          cid: cid,
          status: xhr.status,
          headers: parseHeaders(xhr.getAllResponseHeaders()),
          body: canReadText ? xhr.responseText : null,
        });
      });
      xhr.addEventListener('error', function () {
        send({ kind: 'err', cid: cid, message: 'Network error' });
      });
      xhr.addEventListener('abort', function () {
        send({ kind: 'err', cid: cid, message: 'Aborted' });
      });
      xhr.addEventListener('timeout', function () {
        send({ kind: 'err', cid: cid, message: 'Timeout' });
      });
      return xhr;
    }
    PatchedXHR.prototype = XHR.prototype;
    window.XMLHttpRequest = PatchedXHR;
  }

  // --- fetch ---
  var origFetch = window.fetch;
  if (origFetch) {
    window.fetch = function (input, init) {
      var cid = nextCid();
      var url = typeof input === 'string'
        ? input
        : (input && input.url) || '';
      var method =
        (init && init.method) ||
        (input && typeof input !== 'string' && input.method) ||
        'GET';
      var headers = {};
      try {
        var h =
          (init && init.headers) ||
          (input && typeof input !== 'string' && input.headers);
        if (h) {
          if (typeof h.forEach === 'function') {
            h.forEach(function (v, k) {
              headers[String(k).toLowerCase()] = String(v);
            });
          } else if (Array.isArray(h)) {
            h.forEach(function (pair) {
              headers[String(pair[0]).toLowerCase()] = String(pair[1]);
            });
          } else {
            Object.keys(h).forEach(function (k) {
              headers[String(k).toLowerCase()] = String(h[k]);
            });
          }
        }
      } catch (_) {}
      var body = null;
      if (init && init.body != null) {
        body = bodyToString(init.body);
      }
      send({
        kind: 'req',
        cid: cid,
        method: method,
        url: url,
        headers: headers,
        body: body,
      });
      return origFetch.apply(this, arguments).then(function (res) {
        var resHeaders = {};
        try {
          res.headers.forEach(function (v, k) {
            resHeaders[String(k).toLowerCase()] = String(v);
          });
        } catch (_) {}
        res.clone().text().then(function (text) {
          send({
            kind: 'res',
            cid: cid,
            status: res.status,
            headers: resHeaders,
            body: text,
          });
        }).catch(function () {
          send({
            kind: 'res',
            cid: cid,
            status: res.status,
            headers: resHeaders,
            body: null,
          });
        });
        return res;
      }).catch(function (err) {
        send({
          kind: 'err',
          cid: cid,
          message: String((err && err.message) || err),
        });
        throw err;
      });
    };
  }
})();
''';

/// Dispatches WebView events emitted by [webViewInterceptorScript] to
/// [SamseerCore]. Maintains a `cid → call id` mapping so requests and
/// responses captured separately on the JS side correlate to the same
/// inspector entry.
class SamseerWebViewDispatcher {
  SamseerWebViewDispatcher(this._core);

  final SamseerCore _core;
  final Map<String, int> _ids = <String, int>{};

  void dispatch(Object? event) {
    if (event is! Map) return;
    final kind = event['kind'];
    final cid = event['cid'];
    if (kind is! String || cid is! String) return;
    switch (kind) {
      case 'req':
        _onRequest(cid, event);
        break;
      case 'res':
        _onResponse(cid, event);
        break;
      case 'err':
        _onError(cid, event);
        break;
    }
  }

  void _onRequest(String cid, Map event) {
    final method = (event['method'] ?? 'GET').toString().toUpperCase();
    final urlString = (event['url'] ?? '').toString();
    final uri = Uri.tryParse(urlString) ?? Uri();
    final headers = _toStringMap(event['headers']);
    final body = event['body'];
    final id = _core.nextId();
    _ids[cid] = id;
    final now = DateTime.now();
    _core.addCall(SamseerHttpCall(
      id: id,
      method: method,
      uri: urlString,
      endpoint: uri.path.isEmpty ? '/' : uri.path,
      server: uri.host,
      secure: uri.scheme == 'https',
      client: 'WebView',
      createdAt: now,
      request: SamseerHttpRequest(
        time: now,
        headers: headers,
        queryParameters: Map<String, dynamic>.from(uri.queryParameters),
        body: body,
        contentType: headers['content-type']?.toString(),
        size: _sizeOf(body),
      ),
    ));
  }

  void _onResponse(String cid, Map event) {
    final id = _ids.remove(cid);
    if (id == null) return;
    final status = event['status'];
    final headers = _toStringMap(event['headers']);
    final body = event['body'];
    _core.addResponse(
      id,
      SamseerHttpResponse(
        status: status is int
            ? status
            : status is num
                ? status.toInt()
                : 0,
        time: DateTime.now(),
        headers: headers,
        body: body,
        size: _sizeOf(body),
      ),
    );
  }

  void _onError(String cid, Map event) {
    final id = _ids.remove(cid);
    if (id == null) return;
    _core.addError(
      id,
      SamseerHttpError(message: event['message']?.toString()),
    );
  }

  static Map<String, dynamic> _toStringMap(Object? raw) {
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }

  static int? _sizeOf(Object? body) {
    if (body == null) return null;
    if (body is String) return body.length;
    return null;
  }
}
