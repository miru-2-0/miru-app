import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import '../domain/models/extension_item.dart';
import '../domain/models/extension_models.dart';

/// 真正的 JS 扩展运行时：使用 QuickJS 加载官方 miru 扩展脚本。
/// 桥接方案与 miru-app 完全一致：
/// - 全局 `sendMessage(channel, message)` 由 flutter_js 提供
/// - Dart async 处理器返回的 Future 会被转为 JS Promise，`await` 可直接拿到结果
class ExtensionRuntime {
  ExtensionRuntime(this.extension) {
    className = extension.package.replaceAll('.', '');
    if (className.contains(RegExp(r'[^a-zA-Z]'))) {
      className = '${className.replaceAll(RegExp(r'[^a-zA-Z]'), '')}Renamed';
    }
  }

  final ExtensionItem extension;
  late final JavascriptRuntime runtime;
  late String className;
  bool _isInitialized = false;
  String _currentRequestUrl = '';

  static const String _defaultUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String _keySettings = 'extension_settings_v1';

  bool get isInitialized => _isInitialized;

  /// 初始化 runtime：加载 crypto 库、注册 Dart 桥处理函数、注入扩展脚本并实例化。
  Future<void> init(String script) async {
    runtime = QuickJsRuntime2();
    runtime.enableHandlePromises();

    await _registerBridges();
    await _initRunExtension(script);
    _isInitialized = true;
  }

  Future<void> _registerBridges() async {
    Future<String?> handleGetSetting(dynamic args) async {
      final setting = await _getExtensionSetting(extension.package, args[0]);
      return setting;
    }

    void handleLog(dynamic args) {
      debugPrint('[${extension.package}] ${args[0]}');
    }

    Future<String?> handleRequest(dynamic args) async {
      final url = args[0] as String;
      _currentRequestUrl = url;

      final options = (args[1] as Map?) ?? {};
      final headers = <String, String>{
        for (final entry
            in ((options['headers'] as Map?) ?? {}).entries)
          entry.key.toString(): entry.value.toString(),
      };
      headers['User-Agent'] ??= _defaultUa;
      final method =
          (options['method'] as String? ?? 'get').toString().toUpperCase();
      final requestBody = options['data'];
      final queryParameters = (options['queryParameters'] as Map?) ?? {};

      final uri = Uri.parse(url);
      final mergedQuery = <String, String>{
        ...uri.queryParameters,
        for (final entry in queryParameters.entries)
          entry.key.toString(): entry.value.toString(),
      };

      final req = http.Request(method, uri.replace(queryParameters: mergedQuery));
      req.headers.addAll(headers);
      if (requestBody != null) {
        req.body = requestBody is String
            ? requestBody
            : jsonEncode(requestBody);
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      return res.body;
    }

    Future<void> handleRegisterSetting(dynamic args) async {
      final setting = (args as List).firstWhere(
        (e) => e is Map,
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      await _setExtensionSetting(extension.package, setting);
    }

    Future<void> handleCleanSettings(dynamic args) async {
      final keepKeys = (args as List?)?.cast<String>() ?? [];
      await _cleanExtensionSettings(extension.package, keepKeys);
    }

    String handleQuerySelector(dynamic args) {
      return _bridgeQuerySelector(
        args[0] as String,
        args[1] as String,
        args[2] as String,
      );
    }

    String handleQueryXPath(dynamic args) {
      return _bridgeQueryXPath(
        args[0] as String,
        args[1] as String,
        args[2] as String,
      );
    }

    String handleRemoveSelector(dynamic args) {
      return _bridgeRemoveSelector(
        args[0] as String,
        args[1] as String,
      );
    }

    String? handleGetAttributeText(dynamic args) {
      return _bridgeGetAttributeText(
        args[0] as String,
        args[1] as String,
        args[2] as String?,
      );
    }

    Future<String> handleQuerySelectorAll(dynamic args) async {
      return _bridgeQuerySelectorAll(
        args['content'] as String,
        args['selector'] as String,
      );
    }

    runtime.onMessage('getSetting', (args) => handleGetSetting(args));
    runtime.onMessage('log', (args) => handleLog(args));
    runtime.onMessage('request', (args) => handleRequest(args));
    runtime.onMessage(
        'registerSetting', (args) => handleRegisterSetting(args));
    runtime.onMessage('cleanSettings', (args) => handleCleanSettings(args));
    runtime.onMessage('queryXPath', (args) => handleQueryXPath(args));
    runtime.onMessage('removeSelector', (args) => handleRemoveSelector(args));
    runtime.onMessage(
        'getAttributeText', (args) => handleGetAttributeText(args));
    runtime.onMessage(
        'querySelectorAll', (args) => handleQuerySelectorAll(args));
    runtime.onMessage('querySelector', (args) => handleQuerySelector(args));
  }

  /// 注入 CryptoJS/jsencrypt/md5 + JS 桥接辅助类与扩展基类。
  Future<void> _initRunExtension(String extScript) async {
    final cryptoJs = await rootBundle.loadString('assets/js/CryptoJS.min.js');
    final jsencrypt = await rootBundle.loadString('assets/js/jsencrypt.min.js');
    final md5 = await rootBundle.loadString('assets/js/md5.min.js');

    final preamble = '''
      var window = (global = globalThis);
      $cryptoJs
      $jsencrypt
      $md5
      class Element {
        constructor(content, selector) {
          this.content = content;
          this.selector = selector || "";
        }

        async querySelector(selector) {
          return new Element(await this.excute(), selector);
        }

        async excute(fun) {
          return await sendMessage(
            "querySelector",
            JSON.stringify([this.content, this.selector, fun])
          );
        }

        async removeSelector(selector) {
          this.content = await sendMessage(
            "removeSelector",
            JSON.stringify([await this.outerHTML, selector])
          );
          return this;
        }

        async getAttributeText(attr) {
          return await sendMessage(
            "getAttributeText",
            JSON.stringify([await this.outerHTML, this.selector, attr])
          );
        }

        get text() {
          return this.excute("text");
        }

        get outerHTML() {
          return this.excute("outerHTML");
        }

        get innerHTML() {
          return this.excute("innerHTML");
        }
      }
      class XPathNode {
        constructor(content, selector) {
          this.content = content;
          this.selector = selector;
        }

        async excute(fun) {
          return await sendMessage(
            "queryXPath",
            JSON.stringify([this.content, this.selector, fun])
          );
        }

        get attr() {
          return this.excute("attr");
        }

        get attrs() {
          return this.excute("attrs");
        }

        get text() {
          return this.excute("text");
        }

        get allHTML() {
          return this.excute("allHTML");
        }

        get outerHTML() {
          return this.excute("outerHTML");
        }
      }

      console.log = function (message) {
        if (typeof message === "object") {
          message = JSON.stringify(message);
        }
        sendMessage("log", JSON.stringify([message.toString()]));
      };
      class Extension {
        package = "${extension.package}";
        name = "${extension.name}";
        settingKeys = [];
        async request(url, options) {
          options = options || {};
          options.headers = options.headers || {};
          const miruUrl = options.headers["Miru-Url"] || "${extension.webSite}";
          options.method = options.method || "get";
          const res = await sendMessage(
            "request",
            JSON.stringify([miruUrl + url, options])
          );
          try {
            return JSON.parse(res);
          } catch (e) {
            return res;
          }
        }
        querySelector(content, selector) {
          return new Element(content, selector);
        }
        queryXPath(content, selector) {
          return new XPathNode(content, selector);
        }
        async querySelectorAll(content, selector) {
          let elements = [];
          JSON.parse(
            await sendMessage("querySelectorAll", JSON.stringify({content:content,selector:selector}))
          ).forEach((e) => {
            elements.push(new Element(e, selector));
          });
          return elements;
        }
        async getAttributeText(content, selector, attr) {
          return await sendMessage(
            "getAttributeText",
            JSON.stringify([content, selector, attr])
          );
        }
        popular(page) {
          throw new Error("not implement popular");
        }
        latest(page) {
          throw new Error("not implement latest");
        }
        search(kw, page, filter) {
          throw new Error("not implement search");
        }
        createFilter(filter){
          throw new Error("not implement createFilter");
        }
        detail(url) {
          throw new Error("not implement detail");
        }
        watch(url) {
          throw new Error("not implement watch");
        }
        checkUpdate(url) {
          throw new Error("not implement checkUpdate");
        }
        async getSetting(key) {
          return sendMessage("getSetting", JSON.stringify([key]));
        }
        async registerSetting(settings) {
          console.log(JSON.stringify([settings]));
          this.settingKeys.push(settings.key);
          return sendMessage("registerSetting", JSON.stringify([settings]));
        }
        async load() {}
      }

      async function stringify(callback) {
        const data = await callback();
        return typeof data === "object" ? JSON.stringify(data,0,2) : data;
      }
    ''';

    final ext = extScript.replaceAll(
      RegExp(r'export default class.*'),
      'class $className extends Extension {',
    );

    runtime.evaluate(preamble);

    runtime.evaluate('''
      $ext
      if(typeof ${className}Instance !== 'undefined'){
        delete ${className}Instance;
      }
      var ${className}Instance = new $className();
      ${className}Instance.load().then(()=>{
        sendMessage("cleanSettings", JSON.stringify([${className}Instance.settingKeys]));
      });
    ''');
  }

  Map<String, String> get _defaultHeaders => {
        'Referer': _currentRequestUrl.isNotEmpty
            ? _currentRequestUrl
            : (extension.webSite ?? extension.package),
        'User-Agent': _defaultUa,
      };

  Future<T> _runExtension<T>(Future<T> Function() fun) async {
    try {
      return await fun();
    } catch (e) {
      debugPrint('扩展 [${extension.name}] 执行异常: $e');
      rethrow;
    }
  }

  Future<List<ExtensionListItem>> latest(int page) {
    return _runExtension(() async {
      final jsResult = await runtime.handlePromise(
        await runtime.evaluateAsync(
          'stringify(()=>${className}Instance.latest($page))',
        ),
      );
      final result = (jsonDecode(jsResult.stringResult) as List).map((e) {
        return ExtensionListItem.fromJson(e as Map<String, dynamic>);
      }).toList();
      for (final element in result) {
        element.headers ??= _defaultHeaders;
      }
      return result;
    });
  }

  Future<List<ExtensionListItem>> search(
    String kw,
    int page, {
    Map<String, List<String>>? filter,
  }) {
    return _runExtension(() async {
      final jsResult = await runtime.handlePromise(
        await runtime.evaluateAsync(
          'stringify(()=>${className}Instance.search(${jsonEncode(kw)},'
          '$page,${filter == null ? null : jsonEncode(filter)}))',
        ),
      );
      final result = (jsonDecode(jsResult.stringResult) as List).map((e) {
        return ExtensionListItem.fromJson(e as Map<String, dynamic>);
      }).toList();
      for (final element in result) {
        element.headers ??= _defaultHeaders;
      }
      return result;
    });
  }

  Future<Map<String, ExtensionFilter>> createFilter({
    Map<String, List<String>>? filter,
  }) {
    final eval = filter == null
        ? 'stringify(()=>${className}Instance.createFilter())'
        : 'stringify(()=>${className}Instance.createFilter(JSON.parse(${jsonEncode(jsonEncode(filter))})))';
    return _runExtension(() async {
      final jsResult = await runtime.handlePromise(
        await runtime.evaluateAsync(eval),
      );
      final result = jsonDecode(jsResult.stringResult) as Map<String, dynamic>;
      return result.map(
        (key, value) => MapEntry(
          key,
          ExtensionFilter.fromJson(value as Map<String, dynamic>),
        ),
      );
    });
  }

  Future<ExtensionDetail> detail(String url) {
    return _runExtension(() async {
      final jsResult = await runtime.handlePromise(
        await runtime.evaluateAsync(
          'stringify(()=>${className}Instance.detail(${jsonEncode(url)}))',
        ),
      );
      final result =
          ExtensionDetail.fromJson(jsonDecode(jsResult.stringResult));
      result.headers ??= _defaultHeaders;
      return result;
    });
  }

  Future<ExtensionBangumiWatch?> watch(String url) {
    return _runExtension(() async {
      final jsResult = await runtime.handlePromise(
        await runtime.evaluateAsync(
          'stringify(()=>${className}Instance.watch(${jsonEncode(url)}))',
        ),
      );
      final data = jsonDecode(jsResult.stringResult);
      if (data is! Map<String, dynamic>) {
        debugPrint('扩展 [${extension.name}] watch 返回异常数据: $data');
        return null;
      }
      final result = ExtensionBangumiWatch.fromJson(data);
      result.headers ??= _defaultHeaders;
      return result;
    });
  }

  void dispose() {
    runtime.dispose();
    _isInitialized = false;
  }

  // ---------- 桥接实现 ----------

  String _bridgeQuerySelector(
      String content, String selector, String fun) {
    final doc = parse(content).querySelector(selector);
    String result = '';
    switch (fun) {
      case 'text':
        result = doc?.text ?? '';
        break;
      case 'outerHTML':
        result = doc?.outerHtml ?? '';
        break;
      case 'innerHTML':
        result = doc?.innerHtml ?? '';
        break;
      default:
        result = doc?.outerHtml ?? '';
    }
    return result;
  }

  String _bridgeQueryXPath(
      String content, String selector, String fun) {
    final xpath = HtmlXPath.html(content);
    final result = xpath.queryXPath(selector);
    String returnVal = '';
    switch (fun) {
      case 'attr':
        returnVal = result.attr ?? '';
        break;
      case 'attrs':
        returnVal = jsonEncode(result.attrs);
        break;
      case 'text':
        returnVal = result.node?.text ?? '';
        break;
      case 'allHTML':
        returnVal = result.nodes
            .map((e) => (e.node as Element).outerHtml)
            .toList()
            .toString();
        break;
      case 'outerHTML':
        returnVal = (result.node?.node as Element).outerHtml;
        break;
      default:
        returnVal = result.node?.text ?? '';
    }
    return returnVal;
  }

  String _bridgeRemoveSelector(String content, String selector) {
    final doc = parse(content);
    doc.querySelectorAll(selector).forEach((element) {
      element.remove();
    });
    return doc.outerHtml;
  }

  String? _bridgeGetAttributeText(
      String content, String selector, String? attr) {
    final doc = parse(content).querySelector(selector);
    return doc?.attributes[attr];
  }

  Future<String> _bridgeQuerySelectorAll(
      String content, String selector) async {
    final doc = parse(content).querySelectorAll(selector);
    final elements = jsonEncode(doc.map((e) {
      return e.outerHtml;
    }).toList());
    return elements;
  }

  // ---------- 扩展设置持久化 ----------

  static Future<Map<String, dynamic>> _settingsOf(String package) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    if (raw == null || raw.isEmpty) return {};
    try {
      final all = jsonDecode(raw) as Map<String, dynamic>;
      return (all[package] as Map?)?.cast<String, dynamic>() ?? {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveSettings(
      String package, Map<String, dynamic> values) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySettings);
    Map<String, dynamic> all = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        all = (jsonDecode(raw) as Map<String, dynamic>).cast<String, dynamic>();
      } catch (_) {}
    }
    all[package] = values;
    await prefs.setString(_keySettings, jsonEncode(all));
  }

  static Future<String?> _getExtensionSetting(
      String package, String key) async {
    final settings = await _settingsOf(package);
    final setting = settings[key];
    if (setting is Map) {
      final defaultValue = setting['defaultValue'];
      if (setting['value'] != null) return setting['value'].toString();
      if (defaultValue != null) return defaultValue.toString();
    }
    return setting?.toString();
  }

  static Future<void> _setExtensionSetting(
      String package, Map<String, dynamic> setting) async {
    final settings = await _settingsOf(package);
    final key = setting['key']?.toString();
    if (key == null || key.isEmpty) return;
    settings[key] = setting;
    await _saveSettings(package, settings);
  }

  static Future<void> _cleanExtensionSettings(
      String package, List<String> keepKeys) async {
    final settings = await _settingsOf(package);
    final toRemove = settings.keys
        .where((key) => !keepKeys.contains(key))
        .toList();
    if (toRemove.isEmpty) return;
    for (final key in toRemove) {
      settings.remove(key);
    }
    await _saveSettings(package, settings);
  }
}