import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as imageLib;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: const ColorScheme.light().copyWith(
          primary:const Color(0xFF3B6BF9),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  bool isImageLoaded = false;
  var result = '';

  double? imageWidth;
  double? imageHeight;

  bool isTextVisible = false;


  ///resim yükleme
  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage == null) return;
      final imageTemporary = File(pickedImage.path);

      /// Resmi boyutlandır
      final decodedImage = await decodeImage(File(pickedImage.path).readAsBytesSync());
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final double maxWidth = screenWidth - 16; // İstenilen maksimum genişlik
      final double maxHeight = screenHeight - 200; // İstenilen maksimum yükseklik
      final double aspectRatio = decodedImage.width / decodedImage.height;
      imageWidth = (decodedImage.width > maxWidth) ? maxWidth : decodedImage.width.toDouble();
      imageHeight = imageWidth! / aspectRatio;

      if (imageHeight! > maxHeight) {
        imageHeight = maxHeight;
        imageWidth = imageHeight! * aspectRatio;
      }
      setState(() {
        this.image = imageTemporary;
        isImageLoaded = true;
      });
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
    }
  }

  ///görüntüden metin okuma
  Future<void> readTextFromAnImage() async {
    setState(() {
      result = 'Recognizing text...';
      isTextVisible = true;
    });

    GoogleVisionImage myImage = GoogleVisionImage.fromFile(image!); //taranılacak metin içeren image
    TextRecognizer recognizeText = GoogleVision.instance.textRecognizer(); //metni tanıma işlemi
    VisionText readText = await recognizeText.processImage(myImage); //metin görüntüsü işleme
    await recognizeText.close(); //recognizer kapatılır ve bellek serbest bırakılır

    String scannedText = '';

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          scannedText += word.text! + ' ';
        }
        scannedText += '\n';
      }
      scannedText += '\n';
    }

    setState(() {
      result = scannedText.trim();
    });
  }

  ///Resmi ve metni temizler
  void clearImageAndText() {
    setState(() {
      image = null;
      isImageLoaded = false;
      result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child: Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: const BoxDecoration(),
                  child: image != null && imageWidth != null && imageHeight != null
                      ? Image.file(
                          image!,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.contain,
                        )
                      : const Image(image: AssetImage("assets/picture.png"),)
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      pickImage(ImageSource.gallery);
                    },
                    child: const Icon(Icons.image_outlined),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pickImage(ImageSource.camera);
                    },
                    child : const Icon(Icons.camera_alt_outlined),

                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      readTextFromAnImage();
                    },
                    label: const Text("Scan"),
                    icon: const Icon(Icons.document_scanner_outlined),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      clearImageAndText();
                      isTextVisible = false;
                    },
                    child: const Text("Clear"),

                  ),

                ],
              ),
              ///taranan text'i içeren container'ın görünürlüğü
              Visibility(
                visible: isTextVisible,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  ///Taranan text'i copyalanabilir formatta oluşturur
                  child: SelectableText(
                    result,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///verilen görüntüyü çözümler
  Future<imageLib.Image> decodeImage(List<int> imageBytes) async {
    final imageLib.Image? decodedImage = imageLib.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image.');
    }
    return decodedImage;
  }
}
