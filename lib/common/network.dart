import 'dart:io';

extension NetworkInterfaceExt on NetworkInterface {
  bool get isVirtual {
    final nameLowCase = name.toLowerCase();
    return nameLowCase.startsWith('tun') ||
        nameLowCase.startsWith('tap') ||
        nameLowCase.startsWith('ppp');
  }

  bool get isWifi {
    final nameLowCase = name.toLowerCase();
    return nameLowCase == 'wlan0' ||
        nameLowCase.contains('wi-fi') ||
        nameLowCase.startsWith('wlp') ||
        nameLowCase == 'en0' ||
        nameLowCase == 'eth0';
  }

  bool get isMobileData {
    final nameLowCase = name.toLowerCase();
    return nameLowCase.startsWith('rmnet') ||
        nameLowCase.startsWith('ccmni');
  }

  bool get includesIPv4 {
    return addresses.any((addr) => addr.isIPv4);
  }
}

extension InternetAddressExt on InternetAddress {
  bool get isIPv4 {
    return type == InternetAddressType.IPv4;
  }
}
