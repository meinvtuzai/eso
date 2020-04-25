import 'package:jsonpath/json_path.dart';

class AnalyzeByJSonPath {
  final _jsonRulePattern = RegExp(r"(?<={)\$\..+?(?=})");
  dynamic _ctx;

  AnalyzeByJSonPath(json) {
    _ctx = json;
  }

  AnalyzeByJSonPath parse(json) {
    _ctx = json;
    return this;
  }

  dynamic get json => _ctx;

  String getString(String rule) {
    var result = "";
    if (rule.isEmpty || rule == null) return result;

    if (rule.contains("{\$.")) {
      result = rule;
      var matcher = _jsonRulePattern.allMatches(rule);
      for (var m in matcher) {
        result =
            result.replaceAll("{${m.group(0)}}", getString(m.group(0).trim()));
      }
      return result;
    }

    var rules = <String>[];
    var _customOrRule = false;
    if (rule.contains("&&")) {
      rules = rule.split("&&");
    } else if (rule.contains('||')) {
      rules = rule.split("||");
      _customOrRule = true;
    } else {
      try {
        final ob = JPath.compile(rule).search(_ctx);
        if (ob == null) return result;
        if (ob is List) {
          final builder = <String>[];
          for (var o in ob) {
            builder..add('$o'.trim())..add('\n');
          }
          result = builder.join('').replaceFirst(new RegExp(r'\n$'), '');
        } else {
          result = '$ob';
        }
      } catch (e) {
        print(e);
      }
      return result;
    }

    final textS = <String>[];
    for (String rl in rules) {
      String temp = getString(rl);
      if (temp.isNotEmpty) {
        textS.add(temp);
        if (_customOrRule) {
          break;
        }
      }
    }
    return textS.map((s) => s.trim()).join("\n");
  }

  List<String> getStringList(String rule) {
    final result = <String>[];
    if (null == rule || rule.isEmpty) return result;
    List<String> rules;
    String elementsType;
    if (rule.contains('&&')) {
      rules = rule.split('&&');
      elementsType = '&';
    } else if (rule.contains('%%')) {
      rules = rule.split('%%');
      elementsType = '%';
    } else {
      rules = rule.split('||');
      elementsType = '|';
    }
    if (rules.length == 1) {
      if (!rule.contains('{\$.')) {
        try {
          final object = JPath.compile(rule).search(_ctx);
          if (null == object) return result;
          if (object is List) {
            for (var o in object) result.add(o.toString());
          } else {
            result.add(object.toString());
          }
        } catch (e) {
          print(e);
        }
        return result;
      } else {
        final matcher = _jsonRulePattern.allMatches(rule);
        for (var m in matcher) {
          final stringList = getStringList(m.group(0).trim());
          for (var s in stringList) {
            result.add(rule.replaceAll('{${m.group(0)}}', s));
          }
        }
        return result;
      }
    } else {
      final results = <List<String>>[];
      for (var rl in rules) {
        final temp = getStringList(rl);
        if (temp != null && temp.isNotEmpty) {
          results.add(temp);
          if (temp.length > 0 && '|' == elementsType) {
            break;
          }
        }
      }
      if (results.length > 0) {
        if ('%' == elementsType) {
          for (int i = 0; i < results[0].length; i++) {
            for (var temp in results) {
              if (i < temp.length) {
                result.add('${temp[i]}');
              }
            }
          }
        } else {
          for (var temp in results) {
            result.addAll(temp);
          }
        }
      }
      return result;
    }
  }

  dynamic getObject(String rule) {
    try {
      final res = JPath.compile(rule).search(_ctx);
      return null == res ? '' : res;
    } catch (e) {
      print(e);
      return '';
    }
  }

  List<dynamic> getList(String rule) {
    final result = <dynamic>[];
    if (null == rule || rule.isEmpty) return result;
    String elementsType;
    List<String> rules;
    if (rule.contains('&&')) {
      rules = rule.split('&&');
      elementsType = '&';
    } else if (rule.contains('%%')) {
      rules = rule.split('%%');
      elementsType = '%';
    } else {
      rules = rule.split('||');
      elementsType = '|';
    }
    if (rules.length == 1) {
      try {
        final res = JPath.compile(rules[0]).search(_ctx);
        if (null == res) return result;
//        print(res.runtimeType);
        if (res[0] is List) {
          res.forEach((r) => result.addAll(r));
        } else {
          result.addAll(res);
        }
      } catch (e) {
        print(e);
      }
      return result;
    } else {
      final results = <List<Object>>[];
      for (var rl in rules) {
        final temp = getList(rl);
        if (null != temp && temp.isNotEmpty) {
          results.add(temp);
          if (temp.length > 0 && '|' == elementsType) {
            break;
          }
        }
      }
      if (results.length > 0) {
        if ('%' == elementsType) {
          for (int i = 0; i < results[0].length; i++) {
            for (var temp in results) {
              if (i < temp.length) {
                result.add(temp[i]);
              }
            }
          }
        } else {
          for (var temp in results) {
            result.addAll(temp);
          }
        }
      }
    }
    return result;
  }
}