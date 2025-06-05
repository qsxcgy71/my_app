import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';
import '../models/course_model.dart';
import '../models/profile_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// 初始化Stripe
  static Future<void> initializeStripe() async {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  /// 创建支付意图（Payment Intent）
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 将金额转换为分（Stripe要求最小单位）
      final amountInCents = (amount * 100).round();
      
      print('Creating payment intent with amount: $amountInCents cents (${amount} ${currency.toUpperCase()})');
      print('Description: $description');
      
      final requestBody = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
        if (metadata != null)
          ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
      };
      
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Payment intent created successfully: ${responseData['id']}');
        return responseData;
      } else {
        print('Error creating payment intent: Status ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in createPaymentIntent: $e');
      return null;
    }
  }

  /// 处理课程购买支付
  Future<bool> processCoursePayment({
    required Course course,
    required List<ChildInfo> selectedChildren,
    required BuildContext context,
  }) async {
    try {
      // 如果是免费课程，直接返回成功
      if (course.price == 0) {
        _showPaymentSuccessDialog(context, course, selectedChildren, isFree: true);
        return true;
      }

      print('Starting payment process for course: ${course.title}');
      print('Price: ${course.price}, Children count: ${selectedChildren.length}');

      // 计算总金额（课程价格 * 孩子数量）
      final totalAmount = course.price * selectedChildren.length;
      print('Total amount: $totalAmount');
      
      // 显示支付准备中的对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在准备支付...'),
            ],
          ),
        ),
      );
      
      // 创建支付意图
      print('Creating payment intent...');
      final paymentIntent = await createPaymentIntent(
        amount: totalAmount,
        currency: StripeConfig.currencyCode,
        description: '${course.title} - ${selectedChildren.map((c) => c.name).join(", ")}',
        metadata: {
          'course_id': course.id,
          'course_title': course.title,
          'children_count': selectedChildren.length.toString(),
          'children_names': selectedChildren.map((c) => c.name).join(", "),
        },
      );

      // 关闭准备中的对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (paymentIntent == null) {
        print('Failed to create payment intent');
        _showPaymentErrorDialog(context, '创建支付失败，请稍后重试');
        return false;
      }

      print('Payment intent created successfully');
      print('Client secret: ${paymentIntent['client_secret']}');

      // 初始化支付表单
      print('Initializing payment sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Kids Profile 儿童教育',
          style: ThemeMode.system,
          billingDetails: const BillingDetails(
            name: '家长用户',
          ),
          // 添加更多配置确保支付界面能正确显示
          allowsDelayedPaymentMethods: false,
          appearance: const PaymentSheetAppearance(
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF007AFF),
                  text: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );

      print('Payment sheet initialized, presenting to user...');
      
      // 显示支付界面
      await Stripe.instance.presentPaymentSheet();
      
      print('Payment completed successfully');
      
      // 支付成功
      _showPaymentSuccessDialog(context, course, selectedChildren);
      return true;

    } on StripeException catch (e) {
      print('Stripe error: ${e.error.code} - ${e.error.localizedMessage}');
      
      // 确保关闭任何打开的对话框
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      
      if (e.error.code == FailureCode.Canceled) {
        print('User canceled payment');
        // 用户取消支付，不显示错误消息
        return false;
      } else {
        _showPaymentErrorDialog(context, e.error.localizedMessage ?? '支付失败');
        return false;
      }
    } catch (e) {
      print('General payment error: $e');
      
      // 确保关闭任何打开的对话框
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      
      _showPaymentErrorDialog(context, '支付过程中发生错误，请稍后重试');
      return false;
    }
  }

  /// 显示支付成功对话框
  void _showPaymentSuccessDialog(
    BuildContext context, 
    Course course, 
    List<ChildInfo> children, {
    bool isFree = false
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: Text(isFree ? '报名成功！' : '支付成功！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFree 
                ? '您已成功为孩子报名免费课程：' 
                : '您已成功购买课程：',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '报名孩子：${children.map((c) => c.name).join("、")}',
              style: const TextStyle(fontSize: 14),
            ),
            if (!isFree) ...[
              const SizedBox(height: 8),
              Text(
                '支付金额：¥${(course.price * children.length).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 只关闭支付成功对话框本身
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  /// 显示支付错误对话框
  void _showPaymentErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('支付失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 获取测试用的银行卡信息
  static List<Map<String, String>> getTestCards() {
    return [
      {
        'name': '测试成功卡',
        'number': '4242 4242 4242 4242',
        'expiry': '12/34',
        'cvc': '123',
        'description': '支付成功',
      },
      {
        'name': '测试失败卡',
        'number': '4000 0000 0000 0002',
        'expiry': '12/34', 
        'cvc': '123',
        'description': '被拒绝的卡',
      },
      {
        'name': '3D验证卡',
        'number': '4000 0025 0000 3155',
        'expiry': '12/34',
        'cvc': '123',
        'description': '需要3D安全验证',
      },
    ];
  }
} 