class StripeConfig {
  // Stripe测试环境密钥 - 仅用于沙箱测试
  static const String publishableKey = 'pk_test_51RWZeHRp8fmAilhH5G4ePllbTkuHuqCdeYMTNssZbldSxEoXsUWBiBG4Fn8iTTohCHV6jsVYIyi1cAdO4LDNK2s700UHeiJyR3';
  static const String secretKey = 'sk_test_51RWZeHRp8fmAilhH4B9kxut30aRN2ePDVqymW521T7vt0E6SCftZ2XxPHhNXSc5bbcnYrhpQ3gXPALfpQsL8LVYH00WRo4K3xt';
  
  // Stripe配置
  static const String merchantIdentifier = 'merchant.com.example.my_app';
  static const String countryCode = 'CN';
  static const String currencyCode = 'CNY';
  
  // 测试环境标识
  static const bool isTestMode = true;
  
  // 支付成功/失败的回调URL（用于Web支付）
  static const String successUrl = 'https://your-app.com/payment/success';
  static const String cancelUrl = 'https://your-app.com/payment/cancel';
} 