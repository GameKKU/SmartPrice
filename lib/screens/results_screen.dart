import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/price_checker_service.dart';

class ResultsScreen extends StatelessWidget {
  final PriceAnalysisResult result;
  final double? userDesiredPrice;

  const ResultsScreen({super.key, required this.result, this.userDesiredPrice});

  String _getQualityText(int stars) {
    switch (stars) {
      case 5:
        return 'ดีเยี่ยม (95-100% ใหม่)';
      case 4:
        return 'ดีมาก (85-95% ใหม่)';
      case 3:
        return 'ดี (70-85% ใหม่)';
      case 2:
        return 'ปานกลาง (50-70% ใหม่)';
      case 1:
        return 'พอใช้ (30-50% ใหม่)';
      case 0:
        return 'ต้องปรับปรุง (0-30% ใหม่)';
      default:
        return 'ดี (70-85% ใหม่)';
    }
  }

  void _copyToClipboard(BuildContext context, AnalysisData analysis) {
    final text = 'สินค้า: ${analysis.itemName}\nคุณภาพ: ${analysis.ratingStars}/5 ดาว\nราคาแนะนำ: ${analysis.minPriceThb}-${analysis.maxPriceThb} บาท';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกข้อความแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _isPriceInRange(double userPrice, double minPrice, double maxPrice) {
    return userPrice >= minPrice && userPrice <= maxPrice;
  }

  bool _isPriceTooHigh(double userPrice, double maxPrice) {
    return userPrice > maxPrice;
  }

  String _getRecommendedPrice() {
    if (userDesiredPrice == null) {
      return '${result.analysis.minPriceThb}-${result.analysis.maxPriceThb} บาท';
    }
    
    if (_isPriceTooHigh(userDesiredPrice!, result.analysis.maxPriceThb.toDouble())) {
      return '${result.analysis.maxPriceThb} บาท';
    } else {
      return '${userDesiredPrice!.toInt()} บาท';
    }
  }

  String _getPriceComparisonMessage() {
    if (userDesiredPrice == null) return '';
    
    if (_isPriceTooHigh(userDesiredPrice!, result.analysis.maxPriceThb.toDouble())) {
      return 'ราคาที่ต้องการสูงเกินไป แนะนำให้ขายไม่เกิน ${result.analysis.maxPriceThb} บาท';
    } else if (_isPriceInRange(userDesiredPrice!, result.analysis.minPriceThb.toDouble(), result.analysis.maxPriceThb.toDouble())) {
      return 'ราคาที่ต้องการอยู่ในช่วงที่เหมาะสม';
    } else {
      return 'ราคาที่ต้องการต่ำกว่าช่วงแนะนำ';
    }
  }

  Future<void> _sendToStaff(BuildContext context) async {
    try {
      final response = await PriceCheckerService.notifyStaff(
        itemName: result.analysis.itemName,
        userDesiredPrice: userDesiredPrice!,
        ratingStars: result.analysis.ratingStars,
        minPriceThb: result.analysis.minPriceThb,
        maxPriceThb: result.analysis.maxPriceThb,
        imageUrl: result.imageUrl,
        userAction: 'approve_sell',
      );
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ส่งข้อมูลให้เจ้าหน้าที่แล้ว',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'รหัสการแจ้ง: ${response['data']['notificationId']}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'เวลาตอบกลับโดยประมาณ: ${response['data']['estimatedResponseTime']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use structured analysis data with price comparison
    final recommendedPrice = _getRecommendedPrice();
    final priceComparisonMessage = _getPriceComparisonMessage();
    final quality = '${result.analysis.ratingStars}/5 ดาว';
    final qualityText = _getQualityText(result.analysis.ratingStars);
    final isPriceTooHigh = userDesiredPrice != null && _isPriceTooHigh(userDesiredPrice!, result.analysis.maxPriceThb.toDouble());
    final isPriceInRange = userDesiredPrice != null && _isPriceInRange(userDesiredPrice!, result.analysis.minPriceThb.toDouble(), result.analysis.maxPriceThb.toDouble());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ผลการวิเคราะห์'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF8C69),
                Color(0xFFFFA07A),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                _copyToClipboard(context, result.analysis);
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF8C69),
              Color(0xFFFFA07A),
              Color(0xFFF8F9FA),
            ],
            stops: [0.0, 0.2, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Image Preview Card
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.95),
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Image.network(
                                    result.imageUrl,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 220,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.grey[200]!,
                                              Colors.grey[300]!,
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                size: 48,
                                                color: Color(0xFFFF8C69),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'ไม่สามารถโหลดรูปภาพได้',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Item Name Card
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 35 * (1 - value)),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue[400]!,
                                Colors.blue[500]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'สินค้าที่ตรวจพบ',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        result.analysis.itemName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Price and Quality Cards
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: Row(
                          children: [
                            // Price Range Card
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.green,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.attach_money,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'ราคาแนะนำ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        recommendedPrice,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Quality Rating Card
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFFFF8C69),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'คุณภาพ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: List.generate(5, (index) {
                                           return Icon(
                                             index < result.analysis.ratingStars
                                                 ? Icons.star
                                                 : Icons.star_border,
                                             color: Colors.white,
                                             size: 16,
                                           );
                                         }),
                                       ),
                                       Text(
                                         qualityText,
                                         style: const TextStyle(
                                           fontSize: 12,
                                           color: Colors.white70,
                                         ),
                                       ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Price Comparison Message (only show when price is too high)
                if (userDesiredPrice != null && isPriceTooHigh)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1100),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 45 * (1 - value)),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.orange[100],
                              border: Border.all(
                                color: Colors.orange[300]!,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.warning,
                                      color: Colors.orange[700],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'เปรียบเทียบราคา',
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ราคาที่ต้องการสูงเกินไป แนะนำให้ขายไม่เกิน ${result.analysis.maxPriceThb} บาท',
                                          style: TextStyle(
                                            color: Colors.orange[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (userDesiredPrice != null)
                                          Text(
                                            'ราคาที่ต้องการ: ${userDesiredPrice!.toInt()} บาท',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                if (userDesiredPrice != null && isPriceTooHigh) const SizedBox(height: 24),
                
                // Enhanced Analysis Card (only show when price is too high)
                if (userDesiredPrice != null && isPriceTooHigh)
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8C69).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.analytics,
                                          color: Color(0xFFFF8C69),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'การวิเคราะห์แบบละเอียด',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFF8C69),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8C69).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.copy,
                                            color: Color(0xFFFF8C69),
                                          ),
                                          onPressed: () => _copyToClipboard(context, result.analysis),
                                          tooltip: 'คัดลอกข้อความ',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'สินค้า: ${result.analysis.itemName}\nคุณภาพสินค้า: ${result.analysis.ratingStars}/5 ดาว\nราคาแนะนำ: ${result.analysis.minPriceThb}-${result.analysis.maxPriceThb} บาท\n\nการวิเคราะห์นี้อิงจากคุณภาพที่มองเห็นจากภาพและข้อมูลราคาตลาด',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 32),
                
                // Action Buttons based on price comparison
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 60 * (1 - value)),
                        child: userDesiredPrice != null
                            ? Column(
                                children: [
                                  // Price comparison action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.red[400]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.close,
                                                    color: Colors.red[400],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'ไม่ตกลง',
                                                    style: TextStyle(
                                                      color: Colors.red[400],
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isPriceInRange || !isPriceTooHigh
                                                  ? [
                                                      Colors.green[400]!,
                                                      Colors.green[500]!,
                                                    ]
                                                  : [
                                                      const Color(0xFFFF8C69),
                                                      const Color(0xFFFFA07A),
                                                    ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isPriceInRange || !isPriceTooHigh
                                                    ? Colors.green[400]!
                                                    : const Color(0xFFFF8C69)).withOpacity(0.3),
                                                blurRadius: 15,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () {
                                                if (isPriceInRange || !isPriceTooHigh) {
                                                  _sendToStaff(context);
                                                } else {
                                                  // Just acknowledge the price limit
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('รับทราบข้อมูลราคาแล้ว'),
                                                      backgroundColor: Colors.orange,
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    isPriceInRange || !isPriceTooHigh
                                                        ? Icons.check
                                                        : Icons.thumb_up,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isPriceInRange || !isPriceTooHigh
                                                        ? 'ตกลงขาย'
                                                        : 'ตกลง',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Additional action buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFF8C69),
                                              width: 1,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_back,
                                                    color: const Color(0xFFFF8C69),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'วิเคราะห์ใหม่',
                                                    style: TextStyle(
                                                      color: const Color(0xFFFF8C69),
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: const Color(0xFFFF8C69).withOpacity(0.1),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(12),
                                              onTap: () {
                                                _copyToClipboard(context, result.analysis);
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.share,
                                                    color: const Color(0xFFFF8C69),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'แชร์ผลลัพธ์',
                                                    style: TextStyle(
                                                      color: const Color(0xFFFF8C69),
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : // Original buttons when no user price provided
                            Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFFF8C69),
                                          width: 2,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.arrow_back,
                                                color: Color(0xFFFF8C69),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'วิเคราะห์ใหม่',
                                                style: TextStyle(
                                                  color: Color(0xFFFF8C69),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFFF8C69),
                                            Color(0xFFFFA07A),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF8C69).withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () {
                                            _copyToClipboard(context, result.analysis);
                                          },
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.share,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'แชร์ผลลัพธ์',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}