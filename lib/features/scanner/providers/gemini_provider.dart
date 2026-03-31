import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiProvider = Provider<GeminiScanner>((ref) {
  return GeminiScanner();
});

class GeminiScanner {
  late final GenerativeModel _model;

  GeminiScanner() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in the .env file');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, 
      ),
    );
  }

  Future<Map<String, dynamic>> extractReceiptData(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final prompt = TextPart('''
You are an expert financial data extractor. Analyze this receipt image and extract the data.
Return ONLY a valid JSON object with no markdown formatting (do not wrap in ```json), no code blocks, and no extra text. 

The JSON MUST have the following exact keys and types:
- "merchant_name": string
- "date": string (DD-MM-YYYY format)
- "total_amount": double
- "tax_amount": double (or null if not found)
- "receipt_category": string
- "items": array of objects, each containing:
  - "item_name": string
  - "price": double
  - "category": string

CRITICAL INSTRUCTION: For both "receipt_category" and the "category" inside "items", you MUST choose exactly one of the following strings. Do not invent new categories:
["Groceries", "Food & Dining", "Travel & Transport", "Shopping & Retail", "Electronics", "Health & Pharmacy", "Home & Maintenance", "Entertainment", "Utility Bills", "Other"]
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      // Send the prompt and image to Gemini
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final rawText = response.text;

      if (rawText == null || rawText.isEmpty) {
        throw Exception("Gemini returned an empty response.");
      }

      // Clean the string just in case Gemini ignored the "no markdown" instruction
      String cleanedJson = rawText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.replaceAll('```json', '');
        cleanedJson = cleanedJson.replaceAll('```', '');
      }

      // Parse the JSON string into a Dart Map
      final Map<String, dynamic> parsedData = jsonDecode(cleanedJson.trim());
      return parsedData;
    } catch (e) {
      throw Exception("Failed to process receipt: $e");
    }
  }
}
