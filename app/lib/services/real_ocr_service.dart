import 'dart:io';
import 'package:paddle_ocr_flutter/paddle_ocr_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ocr_service.dart';
import 'parsing/bank_detector.dart';

class RealOcrService implements OcrService {
  final PaddleOcrFlutter _ocr = PaddleOcrFlutter();
  bool _isInit = false;

  Future<void> _ensureInit() async {
    if (!_isInit) {
      await _ocr.init();
      _isInit = true;
    }
  }

  // Fuzzy keyword match helper
  bool _fuzzyMatch(String text, List<String> keywords) {
    final cleanText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ');
    for (final kw in keywords) {
      if (cleanText.contains(kw.toUpperCase())) return true;
    }
    return false;
  }

  // Count how many keywords match (for scoring)
  int _countMatches(String text, List<String> keywords) {
    final t = text.toLowerCase();
    return keywords.where((kw) => t.contains(kw.toLowerCase())).length;
  }

  // Hard eShram exclusion — if 2+ signals present, it IS an eShram card
  bool _isEshramCard(String text) {
    final signals = [
      'e-shram', 'eshram', 'universal account number', 'uan',
      'ministry of labour', 'eshram.gov.in', 'eshram-care',
      'primary occupation', 'blood group',
    ];
    return _countMatches(text, signals) >= 2;
  }

  @override
  Future<Map<String, dynamic>> extractDataFromImage(String imagePath, String docType) async {
    String text = '';
    double confidence = 0.90;

    // Handle PDF files directly without ML OCR
    if (imagePath.toLowerCase().endsWith('.pdf')) {
      print('\n[GigCredit OCR] ====== PDF PROCESSING START ======');
      print('[GigCredit OCR] File    : $imagePath');
      print('[GigCredit OCR] DocType : $docType');

      final bytes = await File(imagePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final int totalPages = document.pages.count;
      print('[GigCredit OCR] Pages   : $totalPages');

      final StringBuffer pdfText = StringBuffer();

      for (int i = 0; i < totalPages; i++) {
        final String pageData = PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);
        pdfText.write(pageData);
        // Log first 200 chars of each page for tracing
        final preview = pageData.trim().replaceAll('\n', ' ');
        print('[GigCredit OCR] Page ${i+1}/$totalPages | chars=${pageData.length} | preview: ${preview.length > 150 ? preview.substring(0, 150) : preview}');
      }

      text = pdfText.toString();
      document.dispose();
      confidence = 0.95;

      print('[GigCredit OCR] Total extracted chars: ${text.length}');
      print('[GigCredit OCR] ====== PDF PROCESSING END ======\n');
      
    } else {
      // Process images with PaddleOCR
      print('\n[GigCredit OCR] ====== IMAGE OCR START ======');
      print('[GigCredit OCR] File    : $imagePath');
      print('[GigCredit OCR] DocType : $docType');
      await _ensureInit();
      final results = await _ocr.recognize(imagePath);
      final StringBuffer sb = StringBuffer();
      for (int i = 0; i < results.length; i++) {
        sb.writeln(results[i].text);
        print('[GigCredit OCR] Line ${(i+1).toString().padLeft(2)}: ${results[i].text}');
      }
      text = sb.toString();
      print('[GigCredit OCR] Total lines: ${results.length}');
      print('[GigCredit OCR] ====== IMAGE OCR END ======\n');
    }

    final cleanText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    // ── HARD EXCLUSION: eShram card check (MUST run before all others) ─────
    final bool isEshram = _isEshramCard(text);

    // ── Identity signals ─────────────────────────────────────────────────────
    final bool hasAadhaarKeyword = _fuzzyMatch(text, [
      'aadhaar', 'aadhar', 'unique identification authority', 'uidai'
    ]);
    // Aadhaar FRONT has photo side: has name + DOB + gender + 12-digit number
    // Aadhaar BACK has address block
    final bool hasAadhaarFrontSignals = _fuzzyMatch(text, ['male', 'female', 'dob', 'date of birth']);
    final bool hasAadhaarBackSignals  = _fuzzyMatch(text, ['address', 's/o', 'c/o', 'help@uidai', 'www.uidai']);

    final RegExp panRegex = RegExp(r'[A-Z]{5}\d{4}[A-Z]');
    final Match? panMatch = panRegex.firstMatch(cleanText);
    final bool hasStrongPanSignal = _fuzzyMatch(text, ['income tax', 'permanent account', 'income tax department']);
    final bool isPan = (hasStrongPanSignal || panMatch != null) && !hasAadhaarKeyword;

    // Determine aadhaar validity (must NOT be eShram)
    final bool isAadhaar = hasAadhaarKeyword && !isEshram;

    print('[GigCredit OCR] --- Classification ---');
    print('[GigCredit OCR] isEshram=$isEshram | isAadhaar=$isAadhaar | isPan=$isPan');
    print('[GigCredit OCR] aadhaarFrontSignals=$hasAadhaarFrontSignals | aadhaarBackSignals=$hasAadhaarBackSignals');

    Map<String, dynamic> extractedData = {};

    if (docType == 'aadhaar_front' || docType == 'aadhaar_back') {
      // Hard reject: eShram uploaded in Aadhaar slot
      if (isEshram) {
        throw Exception('Wrong document: You uploaded an eShram card. Please upload your Aadhaar card.');
      }
      // Hard reject: PAN uploaded in Aadhaar slot
      if (isPan && !isAadhaar) {
        throw Exception('Wrong document: You uploaded a PAN card. Please upload your Aadhaar card.');
      }
      // Aadhaar front/back disambiguation
      if (docType == 'aadhaar_front' && hasAadhaarBackSignals && !hasAadhaarFrontSignals) {
        throw Exception('You uploaded the Aadhaar BACK side. This slot requires the FRONT side (photo side with name and DOB).');
      }
      if (docType == 'aadhaar_back' && hasAadhaarFrontSignals && !hasAadhaarBackSignals) {
        throw Exception('You uploaded the Aadhaar FRONT side. This slot requires the BACK side (address side).');
      }
      if (!isAadhaar) {
        throw Exception('Could not detect a valid Aadhaar card. Please upload a clear Aadhaar image.');
      }
      // Extract fields
      final aadhaarMatch = RegExp(r'\d{4}\s?\d{4}\s?\d{4}').firstMatch(text);
      if (aadhaarMatch != null) {
        extractedData['aadhaar_number'] = aadhaarMatch.group(0)?.replaceAll(' ', '');
        print('[GigCredit OCR] Extracted aadhaar_number: ${extractedData["aadhaar_number"]}');
      }
      final nameMatch = RegExp(r'(?:name|\n)\s*([A-Z][a-zA-Z ]{3,30})').firstMatch(text);
      if (nameMatch != null) {
        extractedData['name'] = nameMatch.group(1)?.trim();
        print('[GigCredit OCR] Extracted name: ${extractedData["name"]}');
      }
      return {'raw_text': text, 'doc_type': docType, 'confidence': 0.95, 'image_path': imagePath, ...extractedData};
    }
    else if (docType == 'pan') {
      // Hard reject: eShram in PAN slot
      if (isEshram) {
        throw Exception('Wrong document: You uploaded an eShram card. Please upload your PAN card.');
      }
      // Hard reject: Aadhaar in PAN slot
      if (isAadhaar && !isPan) {
        throw Exception('Wrong document: You uploaded an Aadhaar card. Please upload your PAN card.');
      }
      if (!isPan && panMatch == null) {
        throw Exception('Could not detect a valid PAN card. Please upload a clear PAN card image.');
      }
      if (panMatch != null) {
        extractedData['pan_number'] = panMatch.group(0);
        print('[GigCredit OCR] Extracted pan_number: ${extractedData["pan_number"]}');
      }
      return {'raw_text': text, 'doc_type': docType, 'confidence': 0.95, 'image_path': imagePath, ...extractedData};
    }
    else if (docType == 'bank_statement' || docType == 'sec_bank_statement') {
      // Strong positive signals — at least 3 required
      final bankStrongSignals = [
        'account statement', 'bank statement', 'statement of account',
        'savings account', 'current account', 'passbook',
      ];
      final bankModerateSignals = [
        'ifsc', 'micr', 'opening balance', 'closing balance',
        'hdfc bank', 'icici bank', 'axis bank', 'state bank', 'sbi',
        'canara bank', 'bank of baroda', 'kotak', 'indusind', 'yes bank',
        'neft', 'imps', 'upi', 'rtgs', 'account number', 'withdrawal', 'deposit',
      ];

      final strongHits    = _countMatches(text, bankStrongSignals);
      final moderateHits  = _countMatches(text, bankModerateSignals);
      final totalScore    = strongHits * 3 + moderateHits;

      print('[GigCredit OCR] Bank classification: strongHits=$strongHits, moderateHits=$moderateHits, totalScore=$totalScore');

      // Require minimum score: 1 strong OR 3+ moderate signals
      if (strongHits == 0 && moderateHits < 3) {
        throw Exception(
          'Not a valid bank statement (score=$totalScore). '
          'Please upload your bank account statement as a PDF. '
          'Uploading images, screenshots, or unrelated documents is not accepted.'
        );
      }
      
      // Reject if it is clearly something else AND doesn't have a strong bank score
      if (isEshram) {
        throw Exception('Wrong document: This is an eShram card, not a bank statement.');
      }
      if (isPan && !hasAadhaarKeyword && totalScore < 3) {
        throw Exception('Wrong document: This looks like a PAN card, not a bank statement.');
      }
      if (isAadhaar && totalScore < 3) {
        throw Exception('Wrong document: This looks like an Aadhaar card, not a bank statement.');
      }
      
      print('[GigCredit OCR] Bank statement ACCEPTED — score=$totalScore');

      // Run bank-wise parsing engine
      final bankType = BankDetector.detect(text);
      final parseResult = BankDetector.parseStatement(text);
      print('[GigCredit OCR] Bank detected: $bankType (${parseResult.bankName})');
      print('[GigCredit OCR] Transactions parsed: ${parseResult.transactions.length}');
      print('[GigCredit OCR] Monthly credits: ${parseResult.monthlyCredits}');
      print('[GigCredit OCR] Monthly debits: ${parseResult.monthlyDebits}');

      return {
        'raw_text': text, 'doc_type': docType, 'confidence': 0.95,
        'parsed': true, 'image_path': imagePath, 'statement_verified': true,
        'bank_score': totalScore,
        'bank_type': bankType,
        'bank_name': parseResult.bankName,
        'account_number': parseResult.accountNumber,
        'ifsc_code': parseResult.ifscCode,
        'holder_name': parseResult.holderName,
        'statement_period': parseResult.statementPeriod,
        'transaction_count': parseResult.transactions.length,
        'monthly_credits': parseResult.monthlyCredits,
        'monthly_debits': parseResult.monthlyDebits,
        'transactions': parseResult.transactions.map((t) => t.toJson()).toList(),
      };
    }
    else if (docType.startsWith('utility_')) {
      final subType = docType.replaceFirst('utility_', '');
      
      // ── Keyword tables (battle-tested 100% accurate from test_full_matrix.py) ──
      final Map<String, List<String>> utilityKeywords = {
        'electricity': ['electricity', 'tangedco', 'energy charges', 'power distribution', 'kwh', 'meter number', 'reading', 'units consumed'],
        'gas':         ['gas', 'indane', 'bharat gas', 'hp gas', 'cylinder', 'png', 'lpg', 'distributor', 'gas connection'],
        // 'postpaid' removed — Airtel WiFi bills say "postpaid wi-fi monthly statement"
        // 'jio number' / 'reliance jio' added — Jio bills say "jio number: xxxxxxxx"
        'mobile':      ['mobile bill', 'airtel mobile', 'jio mobile', 'jio number', 'reliance jio', 'vodafone', 'talktime', 'call charges', 'roaming', 'mobile postpaid'],
        // 'wi-fi' added — Airtel WiFi bills say "postpaid wi-fi monthly statement"
        'internet':    ['broadband', 'wi-fi', 'jiofiber', 'act fibernet', 'airtel fiber', 'data speed', 'unlimited data', 'internet service', 'wifi plan', 'fiber optic', 'airtel wifi'],
        'wifi':        ['broadband', 'wi-fi', 'jiofiber', 'act fibernet', 'airtel fiber', 'data speed', 'unlimited data', 'internet service', 'wifi plan', 'fiber optic', 'airtel wifi'],
        'ott':         ['netflix', 'amazon prime', 'hotstar', 'subscription plan', 'ott platform', 'streaming'],
        'rent':        ['rent receipt', 'tenant name', 'landlord', 'monthly rent', 'lease agreement', 'rental agreement', 'rent paid'],
      };

      final specificKeywords = utilityKeywords[subType] ?? [];
      final genericKeywords = ['bill', 'invoice', 'payment', 'due date', 'amount payable', 'customer no', 'consumer no', 'receipt'];

      final specificScore = _countMatches(text, specificKeywords);
      final genericScore  = _countMatches(text, genericKeywords);
      
      // Calculate max score across ALL other categories (dominance check)
      int maxOtherScore = 0;
      String maxOtherType = '';
      utilityKeywords.forEach((key, keywords) {
        if (key != subType) {
          final s = _countMatches(text, keywords);
          if (s > maxOtherScore) {
            maxOtherScore = s;
            maxOtherType = key;
          }
        }
      });

      print('[GigCredit OCR] Utility[$docType]: spec=$specificScore, gen=$genericScore, maxOther=$maxOtherScore($maxOtherType)');

      // Reject bank statements from all utility slots (bs>=4 and spec<3)
      final bankStrongHits = _countMatches(text, ['account statement', 'bank statement', 'statement of account', 'savings account', 'current account']);
      final bankModHits    = _countMatches(text, ['ifsc', 'micr', 'opening balance', 'closing balance', 'neft', 'imps', 'upi', 'withdrawal', 'deposit']);
      final bsTotal = bankStrongHits * 3 + bankModHits;
      if (bsTotal >= 4 && specificScore < 3) {
        throw Exception('Wrong document: This looks like a bank statement, not a $subType bill.');
      }

      // Strict spec=0 rejections
      if (specificScore == 0) {
        if (maxOtherScore > 0) {
          throw Exception('Wrong document: Found $maxOtherType signals instead of $subType. Please upload the correct $subType document.');
        }
        if (genericScore < 2) {
          throw Exception('Not a valid $subType bill (score=$specificScore/$genericScore). Please upload a clear official document.');
        }
        throw Exception('No $subType-specific signals found. Please upload the correct $subType document.');
      }

      // Dominance check: spec must be strictly highest
      if (specificScore < maxOtherScore) {
        throw Exception('Ambiguous document: $maxOtherType signals ($maxOtherScore) outscoring $subType ($specificScore). Please upload the correct $subType document.');
      }

      // ── Field Extraction ──
      final moneyPattern = RegExp(r'(?:RS\.?|INR|₹|AMOUNT\s*PAYABLE|TOTAL\s*AMOUNT|TOTAL|DUE)[\s:]*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final amounts = <double>[];
      for (final match in moneyPattern.allMatches(text.replaceAll(',', ''))) {
        try { amounts.add(double.parse(match.group(1)!)); } catch (_) {}
      }
      if (amounts.isNotEmpty) {
        extractedData['bill_amount'] = amounts.reduce((curr, next) => curr > next ? curr : next);
        print('[GigCredit OCR] Extracted bill_amount: ${extractedData["bill_amount"]}');
      }

      final datePattern = RegExp(r'\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b');
      final dates = <String>[];
      for (final match in datePattern.allMatches(text)) { dates.add(match.group(1)!); }
      if (dates.isNotEmpty) {
        extractedData['due_date'] = dates.last;
        print('[GigCredit OCR] Extracted due_date: ${extractedData["due_date"]}');
      }

      print('[GigCredit OCR] Utility ACCEPTED: $docType (spec=$specificScore)');
      extractedData['bill_verified'] = true;
    }

    else if (docType == 'work_rc') {
      if (!_fuzzyMatch(text, ['REGISTRATION', 'VEHICLE', 'CHASSIS', 'ENGINE', 'CLASS'])) {
        throw Exception('This does not look like an RC Book. Please upload a clear image.');
      }
      extractedData['rc_verified'] = true;
    }
    else if (docType == 'work_dl_front' || docType == 'work_dl_back') {
      if (!_fuzzyMatch(text, ['DRIVING', 'LICENCE', 'LICENSE', 'TRANSPORT', 'AUTHORIZATION', 'DOB'])) {
        throw Exception('This does not look like a Driving Licence. Please upload a clear image.');
      }
      extractedData['dl_verified'] = true;
    }
    else if (docType.contains('eshram')) {
      if (!_fuzzyMatch(text, ['ESHRAM', 'SHRAM', 'UAN', 'LABOUR', 'WORKER'])) {
        throw Exception('This does not look like an eShram card. Please upload a clear image.');
      }
      extractedData['eshram_verified'] = true;
    }

    // Default fallback
    return {
      'raw_text': text,
      'doc_type': docType,
      'confidence': confidence,
      'image_path': imagePath,
      ...extractedData
    };
  }
}
