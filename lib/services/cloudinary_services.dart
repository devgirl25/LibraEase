import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  final String cloudName = "dgyot4gme";
  final String uploadPreset = "flutter_unsigned";

  /// Upload image to Cloudinary and return the URL
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      return data['secure_url'];
    } else {
      print("❌ Cloudinary upload failed: $resBody");
      return null;
    }
  }
}
