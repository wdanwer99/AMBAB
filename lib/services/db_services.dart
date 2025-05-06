import 'package:agriplant/models/product.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        price REAL,
        imageUrl TEXT,
        category TEXT,
        quantity INTEGER DEFAULT 1
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 1
      ''');
    }
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<int> updateProduct(
      Map<String, dynamic> product, Map<String, int> map) async {
    final db = await database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> saveProduct(Product product, String userId) async {
    final db = await database;
    await db.insert(
      'saved_products',
      {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'imageUrl': product.image,
        'description': product.description,
        'category': product.category,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> getSavedProducts(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'saved_products',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        price: maps[i]['price'],
        quantity: maps[i]['quantity'],
        image: maps[i]['imageUrl'],
        description: maps[i]['description'],
        category: maps[i]['category'],
      );
    });
  }

  Future<void> deleteSavedProduct(String userId, String productId) async {
    final db = await database;
    await db.delete(
      'saved_products',
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, productId],
    );
  }
}
