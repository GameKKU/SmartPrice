import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/price_checker_service.dart';

class ResultsScreen extends StatelessWidget {
  final PriceAnalysisResult result;

  const ResultsScreen({super.key, required this.result});

  String _extractPriceRange(String analysis) {
    // Try to extract price range from Thai text
    final priceRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)-?(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*บาท');
    final match = priceRegex.firstMatch(analysis);
    if (match != null) {
      return '${match.group(1)}-${match.group(2)} บาท';
    }
    
    // Fallback: look for any price mention
    final singlePriceRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*บาท');
    final singleMatch = singlePriceRegex.firstMatch(analysis);
    if (singleMatch != null) {
      return '${singleMatch.group(1)} บาท';
    }
    
    return 'ไม่สามารถระบุราคาได้';
  }

  String _extractQuality(String analysis) {
    // Try to extract quality assessment from Thai text
    if (analysis.contains('ดีมาก')) {
      return 'ดีมาก (90-95% ใหม่)';
    } else if (analysis.contains('ดี')) {
      return 'ดี (80-90% ใหม่)';
    } else if (analysis.contains('ปานกลาง')) {
      return 'ปานกลาง (70-80% ใหม่)';
    } else if (analysis.contains('พอใช้')) {
      return 'พอใช้ (60-70% ใหม่)';
    }
    return 'ไม่สามารถประเมินได้';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกข้อความแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceRange = _extractPriceRange(result.analysis);
    final quality = _extractQuality(result.analysis);

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
                Color(0xFF2196F3),
                Color(0xFF21CBF3),
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
              Color(0xFF2196F3),
              Color(0xFF21CBF3),
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
                                                color: Color(0xFF2196F3),
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
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2196F3).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Color(0xFF2196F3),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'สินค้าที่ระบุ',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2196F3),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        result.identifiedItem,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ],
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
                
                // Enhanced Price Summary Cards
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
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.3),
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
                                          Icons.monetization_on,
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
                                        priceRange,
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
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2196F3),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
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
                                          Icons.verified,
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
                                      Text(
                                        quality,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
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
                
                const SizedBox(height: 24),
                
                // Enhanced Analysis Card
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
                                        color: const Color(0xFF2196F3).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.analytics,
                                        color: Color(0xFF2196F3),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'การวิเคราะห์แบบละเอียด',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2196F3),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2196F3).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Color(0xFF2196F3),
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
                                    result.analysis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      height: 1.6,
                                      color: Colors.grey[800],
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
                
                // Enhanced Action Buttons
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 60 * (1 - value)),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF2196F3),
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
                                          color: Color(0xFF2196F3),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'วิเคราะห์ใหม่',
                                          style: TextStyle(
                                            color: Color(0xFF2196F3),
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
                                      Color(0xFF2196F3),
                                      Color(0xFF21CBF3),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
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
                                      _copyToClipboard(context, 
                                        'สินค้า: ${result.identifiedItem}\n'
                                        'คุณภาพ: $quality\n'
                                        'ราคาแนะนำ: $priceRange\n\n'
                                        '${result.analysis}'
                                      );
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