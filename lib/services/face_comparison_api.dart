// services/face_recognition_api.dart
import 'dart:io';
import '../services/network_service.dart';
import '../utils/image_utils.dart';
import 'api_exception.dart';

class FaceRecognitionService {
  final NetworkService _network = NetworkService();

  // ---------------------------------------------------------
  // 🔥 Health Check
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      return await _network.get("/face/health");
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Get Face Registration Status
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getFaceStatus() async {
    try {
      return await _network.get("/face/status");
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Register Face (with base64 images)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> registerFace({
    required List<String> base64Images,
  }) async {
    try {
      return await _network.post(
        "/face/register",
        {
          "images": base64Images,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Register Face (with File objects) - FIXED VERSION
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> registerFaceWithFiles(List<File> imageFiles) async {
    try {
      final base64Images = await Future.wait(
        imageFiles.map((file) => ImageUtils.fileToDataUrl(file)),
      );

      return await registerFace(base64Images: base64Images);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Face Check-In (with base64)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> faceCheckIn({
    required String imageBase64,
    required String deviceInfo,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "image": imageBase64,
        "deviceInfo": deviceInfo,
      };

      if (latitude != null && longitude != null) {
        body["latitude"] = latitude;
        body["longitude"] = longitude;
      }

      if (address != null) {
        body["address"] = address;
      }

      return await _network.post("/face/check-in", body);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Face Check-In (with File) - FIXED VERSION
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> faceCheckInWithFile(
      File imageFile,
      String deviceInfo, {
        double? latitude,
        double? longitude,
        String? address,
      }) async {
    try {
      final imageBase64 = await ImageUtils.fileToDataUrl(imageFile);
      return await faceCheckIn(
        imageBase64: imageBase64,
        deviceInfo: deviceInfo,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Face Check-Out (with base64)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> faceCheckOut({
    required String imageBase64,
    required String deviceInfo,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "image": imageBase64,
        "deviceInfo": deviceInfo,
      };

      if (latitude != null && longitude != null) {
        body["latitude"] = latitude;
        body["longitude"] = longitude;
      }

      if (address != null) {
        body["address"] = address;
      }

      return await _network.post("/face/check-out", body);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Face Check-Out (with File) - FIXED VERSION
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> faceCheckOutWithFile(
      File imageFile,
      String deviceInfo, {
        double? latitude,
        double? longitude,
        String? address,
      }) async {
    try {
      final imageBase64 = await ImageUtils.fileToDataUrl(imageFile);
      return await faceCheckOut(
        imageBase64: imageBase64,
        deviceInfo: deviceInfo,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Verify Face (standalone)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> verifyFace(String imageBase64) async {
    try {
      return await _network.post(
        "/face/verify",
        {"image": imageBase64},
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Update Face Registration
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> updateFace({
    required List<String> base64Images,
  }) async {
    try {
      return await _network.put(
        "/face/update",
        {
          "images": base64Images,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Update Face (with Files) - FIXED VERSION
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> updateFaceWithFiles(List<File> imageFiles) async {
    try {
      final base64Images = await Future.wait(
        imageFiles.map((file) => ImageUtils.fileToDataUrl(file)),
      );

      return await updateFace(base64Images: base64Images);
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Delete Face Registration
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> deleteFace({
    String confirm = "DELETE",
  }) async {
    try {
      final response = await _network.deleteFace(
        "/face/delete",
        {"confirm": confirm},
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }


  // ---------------------------------------------------------
  // 🔥 Test Face Detection
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> testFaceDetection(String imageBase64) async {
    try {
      return await _network.post(
        "/face/test/detection",
        {"image": imageBase64},
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Compare Two Faces
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> compareFaces({
    required String image1Base64,
    required String image2Base64,
  }) async {
    try {
      return await _network.post(
        "/face/compare",
        {
          "image1": image1Base64,
          "image2": image2Base64,
        },
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // 🔥 Compare Two Faces (with Files) - FIXED VERSION
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> compareFacesWithFiles(File image1File, File image2File) async {
    try {
      final image1Base64 = await ImageUtils.fileToDataUrl(image1File);
      final image2Base64 = await ImageUtils.fileToDataUrl(image2File);

      return await compareFaces(
        image1Base64: image1Base64,
        image2Base64: image2Base64,
      );
    } catch (e) {
      if (e is ApiException) throw e;
      rethrow;
    }
  }
}