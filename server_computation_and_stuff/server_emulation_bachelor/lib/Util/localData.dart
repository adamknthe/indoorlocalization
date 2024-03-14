import 'package:path_provider/path_provider.dart';
import 'dart:io';



class localData{

  static Future<String> getFilePath([String sensortype = ""]) async {

    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    String appDocumentsPath = appDocumentsDirectory.path;
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime tsdate = DateTime.fromMillisecondsSinceEpoch(timestamp);

    String datetime = tsdate.year.toString() + "-" + tsdate.month.toString() + "-" + tsdate.day.toString()+"-"+tsdate.hour.toString()+"-"+tsdate.minute.toString()+"-"+tsdate.second.toString();
    String filePath = '$appDocumentsPath/$sensortype-$datetime.csv';
    print(filePath);
    return filePath;
  }

  static Future<List<String>> getFilesInDir() async{
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
    List<String> files = <String>[];
    await for (var entity in appDocumentsDirectory.list(recursive: false, followLinks: false)) {
      if(entity.path.contains(".csv")){
        files.add(entity.path);
      }
    }
    return files;
  }

  static int numberOfFiles(){
    int lenght = 0;
    localData.getFilesInDir().then((value) => lenght = value.length);
    return lenght;
  }

  static Future<void> removeFile(File file) async {
    try{
      file.delete();
    } catch (e){
      print("error");
    }
  }

  static Future<void> appendToFile(String data, File file)async {
    file.writeAsString(data,mode: FileMode.append);
  }

  static Future<File> saveFile(File file,String data) async {
    await file.writeAsString(data,mode: FileMode.append);
    return file;
  }

  static Future<File> createFile([String sensortype = ""]) async {
    return File(await getFilePath(sensortype));
  }

  static Future<String> readFile() async {
    File file = File(await getFilePath());
    String fileContent = await file.readAsString();
    return fileContent;
  }

}