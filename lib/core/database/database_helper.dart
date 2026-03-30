import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "WalletPulse.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          color_hex TEXT
      )
    ''');

    // UPDATED: Added category_id and its foreign key
    await db.execute('''
      CREATE TABLE receipts (
          id TEXT PRIMARY KEY,
          merchant_name TEXT NOT NULL,
          purchase_date TEXT NOT NULL,
          total_amount REAL NOT NULL,
          tax_amount REAL,
          category_id TEXT, 
          image_path TEXT,
          warranty_expiry_date TEXT,
          is_synced INTEGER DEFAULT 0,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE line_items (
          id TEXT PRIMARY KEY,
          receipt_id TEXT NOT NULL,
          item_name TEXT NOT NULL,
          price REAL NOT NULL,
          category_id TEXT,
          FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE line_item_splits (
          id TEXT PRIMARY KEY,
          line_item_id TEXT NOT NULL,
          user_name TEXT NOT NULL,
          owed_amount REAL NOT NULL,
          FOREIGN KEY (line_item_id) REFERENCES line_items (id) ON DELETE CASCADE
      )
    ''');
    
    // Default categories
    await db.rawInsert("INSERT INTO categories (id, name, color_hex) VALUES ('1', 'Food & Dining', '#FF5733')");
    await db.rawInsert("INSERT INTO categories (id, name, color_hex) VALUES ('2', 'Groceries', '#4CAF50')");
    await db.rawInsert("INSERT INTO categories (id, name, color_hex) VALUES ('3', 'Electronics', '#2196F3')");
  }
}