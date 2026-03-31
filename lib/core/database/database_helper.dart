import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const _databaseName = "WalletPulse.db";
  static const _databaseVersion = 1;
  final _uuid = const Uuid();

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
    // 1. Create categories FIRST so other tables can reference it
    await db.execute('''
      CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          color_hex TEXT
      )
    ''');

    // 2. Create receipts
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

    // 3. Create line_items WITH the quantity column
    await db.execute('''
      CREATE TABLE line_items (
          id TEXT PRIMARY KEY,
          receipt_id TEXT NOT NULL,
          item_name TEXT NOT NULL,
          quantity INTEGER DEFAULT 1,
          price REAL NOT NULL,
          category_id TEXT,
          FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 4. Create splits table
    await db.execute('''
      CREATE TABLE line_item_splits (
          id TEXT PRIMARY KEY,
          line_item_id TEXT NOT NULL,
          user_name TEXT NOT NULL,
          owed_amount REAL NOT NULL,
          FOREIGN KEY (line_item_id) REFERENCES line_items (id) ON DELETE CASCADE
      )
    ''');

    // Seed the 10 exact categories
    final defaultCategories = [
      {'id': _uuid.v4(), 'name': 'Groceries', 'color_hex': '#E1BEE7'},
      {'id': _uuid.v4(), 'name': 'Food & Dining', 'color_hex': '#B2DFDB'},
      {'id': _uuid.v4(), 'name': 'Travel & Transport', 'color_hex': '#FFCCBC'},
      {'id': _uuid.v4(), 'name': 'Shopping & Retail', 'color_hex': '#F8BBD0'},
      {'id': _uuid.v4(), 'name': 'Electronics', 'color_hex': '#FFF9C4'},
      {'id': _uuid.v4(), 'name': 'Health & Pharmacy', 'color_hex': '#C8E6C9'},
      {'id': _uuid.v4(), 'name': 'Home & Maintenance', 'color_hex': '#D7CCC8'},
      {'id': _uuid.v4(), 'name': 'Entertainment', 'color_hex': '#BBDEFB'},
      {'id': _uuid.v4(), 'name': 'Utility Bills', 'color_hex': '#B3E5FC'},
      {'id': _uuid.v4(), 'name': 'Other', 'color_hex': '#CFD8DC'},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  // --- The Master Save Method ---
  Future<void> saveReceiptFromGemini(
    Map<String, dynamic> data,
    String imagePath,
  ) async {
    final db = await instance.database;
    String normalizeDate(String inputDate) {
      try {
        DateTime.parse(inputDate);
        return inputDate;
      } catch (e) {
        final parts = inputDate.split(RegExp(r'[-/]'));
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
        return DateTime.now().toIso8601String().split('T')[0];
      }
    }

    await db.transaction((txn) async {
      // 1. Helper function to find a Category ID by its name
      Future<String?> getCategoryId(String categoryName) async {
        final List<Map<String, dynamic>> maps = await txn.query(
          'categories',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [categoryName],
        );
        if (maps.isNotEmpty) {
          return maps.first['id'] as String;
        }
        final otherMap = await txn.query(
          'categories',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: ['Other'],
        );
        return otherMap.isNotEmpty ? otherMap.first['id'] as String : null;
      }

      // 2. Insert the main Receipt
      final String receiptId = _uuid.v4();
      final String? masterCategoryId = await getCategoryId(
        data['receipt_category'] ?? 'Other',
      );
      final cleanDate = normalizeDate(data['date'] ?? '');

      await txn.insert('receipts', {
        'id': receiptId,
        'merchant_name': data['merchant_name'],
        'purchase_date': cleanDate,
        'total_amount': data['total_amount'],
        'tax_amount': data['tax_amount'],
        'category_id': masterCategoryId,
        'image_path': imagePath,
      });

      // 3. Loop through and insert all Line Items
      if (data['items'] != null && data['items'] is List) {
        for (var item in data['items']) {
          final String itemId = _uuid.v4();
          final String? itemCategoryId = await getCategoryId(
            item['category'] ?? 'Other',
          );

          await txn.insert('line_items', {
            'id': itemId,
            'receipt_id': receiptId,
            'item_name': item['item_name'],
            'quantity': item['quantity'] ?? 1,
            'price': item['price'],
            'category_id': itemCategoryId,
          });
        }
      }
    });
  }

  // Fetch All Receipts
  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT 
        receipts.*, 
        categories.name as category_name 
      FROM receipts
      LEFT JOIN categories ON receipts.category_id = categories.id
      ORDER BY receipts.purchase_date DESC
    ''');
  }

  // Delete a Receipt
  Future<int> deleteReceipt(String id) async {
    final db = await instance.database;
    return await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  // Fetch Line Items for a specific Receipt
  Future<List<Map<String, dynamic>>> getLineItems(String receiptId) async {
    final db = await instance.database;
    return await db.query(
      'line_items',
      where: 'receipt_id = ?',
      whereArgs: [receiptId],
    );
  }
}
