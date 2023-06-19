import 'dart:io';

const ACCESS_TOKEN_KEY = 'ACCESS_TOKEN_KEY';
const REFRESH_TOKEN_KEY = 'REFRESH_TOKEN_KEY';

const emulatorIp = '10.0.0.2:3000';
const simulatorIp = '127.0.0.1:3000';

final hostIp = 'http://${Platform.isIOS ? simulatorIp : emulatorIp}';
