// TODO Implement this library.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getAssetPath(String asset) async {
  final path = await getLocalPath(asset);
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load(asset);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

List<String> getFullName(String textBlock) {
  final regex = RegExp(r'P<(\w+)<<(\w+)<');
  final fullNameMatch = regex.firstMatch(textBlock);

  if (fullNameMatch == null || fullNameMatch.groupCount != 2) {
    return ['',''];
  }

  final surnameBase = fullNameMatch.group(1)!;
  final givenName = fullNameMatch.group(2)!;

  return [surnameBase.substring(3), givenName];
}

List<String> predictIDType(String textBlock) {
  if (textBlock.toLowerCase().contains("passport")) {
    return ["passport"];
  }
  return ["unknown"];
}

bool isADate(String dateString) {
  print(dateString);
  try {
    final formatter = DateFormat('dd-MM-yyyy');
    formatter.parseStrict(dateString);
    return true;
  } catch (e) {
    return false;
  }
}


