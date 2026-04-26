abstract class OcrService {
  Future<Map<String, dynamic>> extractDataFromImage(String imagePath, String docType);
}
