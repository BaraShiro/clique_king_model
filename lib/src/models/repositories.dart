import 'dart:io';
import 'package:clique_king_model/clique_king_model.dart';
import 'package:firedart/firedart.dart';
import 'package:dotenv/dotenv.dart';

/// A helper class for keeping references to [FirebaseAuth] and [Firestore].
class Repositories {
  String _apiKey = "";
  String _projectId = "";

  late FirebaseAuth _auth;
  late Firestore _store;

  FirebaseAuth get auth => _auth;
  Firestore get store => _store;

  /// Private constructor.
  Repositories._create() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    _apiKey = env['FIREBASE_API_KEY'] ?? "";
    _projectId = env['FIREBASE_PROJECT_ID'] ?? "";

    if (_apiKey.isEmpty) {
      print("FIREBASE_API_KEY missing from .env file");
      exit(0);
    }

    if (_projectId.isEmpty) {
      print("FIREBASE_PROJECT_ID missing from .env file");
      exit(0);
    }

  }

  /// Public async factory.
  static Future<Repositories> setup() async {
    print("create() (public factory)");

    // Call the private constructor.
    Repositories repositories = Repositories._create();

    // Do initialization that requires async.
    await repositories._initialize();

    // Return the fully initialized object.
    return repositories;
  }

  /// Initialize [FirebaseAuth] and [Firestore].
  Future<void> _initialize() async {
    _auth = FirebaseAuth.initialize(_apiKey, await HiveStore.create(path: Directory.current.path));
    _store = Firestore.initialize(_projectId);
  }

}
