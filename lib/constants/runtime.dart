import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'Constants.dart';

class Runtime{

  static late Client client;
  static late Account account;
  static late Databases database;
  static late Storage storage;
  static late Realtime realtime;
  static late Functions functions;
  static RealtimeSubscription? gameSubscription;
  static Account? user;
  static models.Session? session;
  static bool _initialized = false;

  static void initialize(){
    if(!_initialized){
      client = Client();
      client.setEndpoint(domain).setProject(projectId).setSelfSigned();
      account = Account(client);
      database = Databases(client);
      storage = Storage(client);
      realtime = Realtime(client);
      functions = Functions(client);
      _initialized = true;
    }
  }

}