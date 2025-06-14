import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/expense.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Extract text from image
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  // Parse receipt data from extracted text
  static Map<String, dynamic> parseReceiptData(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    Map<String, dynamic> receiptData = {
      'title': '',
      'amount': 0.0,
      'date': DateTime.now(),
      'category': 'Other',
      'merchantName': '',
    };

    // Extract merchant name (usually first meaningful line)
    if (lines.isNotEmpty) {
      receiptData['merchantName'] = _extractMerchantName(lines);
      receiptData['title'] = receiptData['merchantName'];
    }

    // Extract amount
    receiptData['amount'] = _extractAmount(text);

    // Extract date
    receiptData['date'] = _extractDate(text);

    // Determine category based on merchant
    receiptData['category'] = _categorizeExpense(receiptData['merchantName'].toString());

    return receiptData;
  }

  // Extract merchant name from receipt lines
  static String _extractMerchantName(List<String> lines) {
    // Skip common receipt headers and look for merchant name
    final skipWords = ['receipt', 'invoice', 'bill', 'thank you', 'customer copy'];
    
    for (String line in lines.take(5)) { // Check first 5 lines
      final cleanLine = line.toLowerCase();
      
      // Skip short lines, numbers, and common headers
      if (line.length < 3 || 
          RegExp(r'^\d+$').hasMatch(line) ||
          skipWords.any((word) => cleanLine.contains(word))) {
        continue;
      }
      
      // Return first meaningful line as merchant name
      if (line.length > 3 && line.length < 50) {
        return line;
      }
    }
    
    return lines.isNotEmpty ? lines.first : 'Receipt';
  }

  // Extract amount from text using various patterns
  static double _extractAmount(String text) {
    // Common amount patterns on receipts - FIXED RegExp syntax
    final amountPatterns = [
      RegExp(r'total[:\s]*\$?(\d+\.?\d*)', caseSensitive: false, multiLine: true),
      RegExp(r'amount[:\s]*\$?(\d+\.?\d*)', caseSensitive: false, multiLine: true),
      RegExp(r'subtotal[:\s]*\$?(\d+\.?\d*)', caseSensitive: false, multiLine: true),
      RegExp(r'\$(\d+\.?\d*)', caseSensitive: false, multiLine: true),
      RegExp(r'(\d+\.\d{2})', caseSensitive: false, multiLine: true), // Match XX.XX format
    ];

    final amounts = <double>[];
    
    for (RegExp pattern in amountPatterns) {
      final matches = pattern.allMatches(text.toLowerCase());
      for (RegExpMatch match in matches) {
        final amountStr = match.group(1) ?? match.group(0);
        if (amountStr != null) {
          final amount = double.tryParse(amountStr.replaceAll('\$', ''));
          if (amount != null && amount > 0 && amount < 10000) { // Reasonable bounds
            amounts.add(amount);
          }
        }
      }
    }

    // Return the largest reasonable amount (likely the total)
    return amounts.isNotEmpty ? amounts.reduce((a, b) => a > b ? a : b) : 0.0;
  }

  // Extract date from text
  static DateTime _extractDate(String text) {
    // Common date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{2,4})'), // MM-DD-YYYY or DD-MM-YYYY
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'), // YYYY-MM-DD
    ];

    for (RegExp pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          int year, month, day;
          
          if (pattern.pattern.startsWith(r'(\d{4})')) {
            // YYYY-MM-DD format
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // MM/DD/YYYY or DD/MM/YYYY format
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
            
            // Assume MM/DD/YYYY format for simplicity
            month = part1;
            day = part2;
            
            // Handle 2-digit years
            if (year < 100) {
              year += 2000;
            }
          }

          // Validate date
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            final date = DateTime(year, month, day);
            // Only return dates that are not in the future and within last 1 year
            if (date.isBefore(DateTime.now().add(Duration(days: 1))) &&
                date.isAfter(DateTime.now().subtract(Duration(days: 365)))) {
              return date;
            }
          }
        } catch (e) {
          // Continue to next pattern if parsing fails
        }
      }
    }

    return DateTime.now(); // Default to today
  }

  // Categorize expense based on merchant name
  static String _categorizeExpense(String merchantName) {
    final merchant = merchantName.toLowerCase();
    
    if (merchant.contains('restaurant') || 
        merchant.contains('cafe') || 
        merchant.contains('pizza') ||
        merchant.contains('burger') ||
        merchant.contains('food') ||
        merchant.contains('kitchen') ||
        merchant.contains('bistro')) {
      return 'Food';
    }
    
    if (merchant.contains('gas') || 
        merchant.contains('fuel') ||
        merchant.contains('shell') ||
        merchant.contains('bp') ||
        merchant.contains('exxon') ||
        merchant.contains('uber') ||
        merchant.contains('lyft') ||
        merchant.contains('taxi')) {
      return 'Transport';
    }
    
    if (merchant.contains('walmart') || 
        merchant.contains('target') ||
        merchant.contains('amazon') ||
        merchant.contains('shop') ||
        merchant.contains('store') ||
        merchant.contains('market')) {
      return 'Shopping';
    }
    
    if (merchant.contains('pharmacy') || 
        merchant.contains('hospital') ||
        merchant.contains('clinic') ||
        merchant.contains('medical') ||
        merchant.contains('doctor') ||
        merchant.contains('cvs') ||
        merchant.contains('walgreens')) {
      return 'Health';
    }
    
    if (merchant.contains('movie') || 
        merchant.contains('cinema') ||
        merchant.contains('theater') ||
        merchant.contains('netflix') ||
        merchant.contains('spotify') ||
        merchant.contains('entertainment')) {
      return 'Entertainment';
    }
    
    return 'Other';
  }

  // Clean up resources
  static void dispose() {
    _textRecognizer.close();
  }
}