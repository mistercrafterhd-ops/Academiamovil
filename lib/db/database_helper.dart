import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alumno.dart';
import '../models/curso.dart';
import '../models/pago.dart';
import '../models/asistencia.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'academia_movil.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version because schema changed
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alumnos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        apellido TEXT NOT NULL,
        dni TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cursos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        precio REAL NOT NULL,
        fecha_inicio TEXT,
        fecha_fin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE matriculas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_alumno INTEGER NOT NULL,
        id_curso INTEGER NOT NULL,
        FOREIGN KEY (id_alumno) REFERENCES alumnos (id) ON DELETE CASCADE,
        FOREIGN KEY (id_curso) REFERENCES cursos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pagos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_alumno INTEGER NOT NULL,
        id_curso INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        cantidad REAL NOT NULL,
        metodo TEXT NOT NULL,
        pagado INTEGER NOT NULL,
        FOREIGN KEY (id_alumno) REFERENCES alumnos (id) ON DELETE CASCADE,
        FOREIGN KEY (id_curso) REFERENCES cursos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_alumno INTEGER NOT NULL,
        id_curso INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        presente INTEGER NOT NULL,
        FOREIGN KEY (id_alumno) REFERENCES alumnos (id) ON DELETE CASCADE,
        FOREIGN KEY (id_curso) REFERENCES cursos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop old tables to migrate to new schema
    await db.execute('DROP TABLE IF EXISTS asistencias');
    await db.execute('DROP TABLE IF EXISTS pagos');
    await db.execute('DROP TABLE IF EXISTS matriculas');
    await db.execute('DROP TABLE IF EXISTS cursos');
    await db.execute('DROP TABLE IF EXISTS alumnos');
    await _onCreate(db, newVersion);
  }

  // --- Alumnos ---
  Future<int> insertarAlumno(Alumno alumno) async {
    final db = await database;
    return await db.insert('alumnos', alumno.toMap());
  }

  Future<List<Alumno>> getAlumnos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('alumnos');
    return List.generate(maps.length, (i) => Alumno.fromMap(maps[i]));
  }

  Future<int> actualizarAlumno(Alumno alumno) async {
    final db = await database;
    return await db.update('alumnos', alumno.toMap(),
        where: 'id = ?', whereArgs: [alumno.id]);
  }

  Future<int> eliminarAlumno(int id) async {
    final db = await database;
    return await db.delete('alumnos', where: 'id = ?', whereArgs: [id]);
  }

  // --- Cursos ---
  Future<int> insertarCurso(Curso curso) async {
    final db = await database;
    return await db.insert('cursos', curso.toMap());
  }

  Future<List<Curso>> getCursos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cursos');
    return List.generate(maps.length, (i) => Curso.fromMap(maps[i]));
  }

  Future<int> actualizarCurso(Curso curso) async {
    final db = await database;
    return await db.update('cursos', curso.toMap(),
        where: 'id = ?', whereArgs: [curso.id]);
  }

  Future<int> eliminarCurso(int id) async {
    final db = await database;
    return await db.delete('cursos', where: 'id = ?', whereArgs: [id]);
  }

  // --- Matriculas ---
  Future<int> matricular(int idAlumno, int idCurso) async {
    final db = await database;
    return await db.insert('matriculas', {'id_alumno': idAlumno, 'id_curso': idCurso});
  }

  // Alias for old calls that might remain in other unupdated screens
  Future<int> matricularAlumno(int idAlumno, int idCurso) => matricular(idAlumno, idCurso);

  Future<int> desmatricular(int idAlumno, int idCurso) async {
    final db = await database;
    return await db.delete('matriculas',
        where: 'id_alumno = ? AND id_curso = ?',
        whereArgs: [idAlumno, idCurso]);
  }
  
  // Alias for old calls
  Future<int> desmatricularAlumno(int idAlumno, int idCurso) => desmatricular(idAlumno, idCurso);

  Future<List<Curso>> getCursosDeAlumno(int idAlumno) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT cursos.* FROM cursos
      INNER JOIN matriculas ON cursos.id = matriculas.id_curso
      WHERE matriculas.id_alumno = ?
    ''', [idAlumno]);
    return List.generate(maps.length, (i) => Curso.fromMap(maps[i]));
  }

  // Alias for old calls
  Future<List<Curso>> getCursosPorAlumno(int idAlumno) => getCursosDeAlumno(idAlumno);

  Future<List<Curso>> getCursosNoMatriculados(int idAlumno) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM cursos 
      WHERE id NOT IN (
        SELECT id_curso FROM matriculas WHERE id_alumno = ?
      )
    ''', [idAlumno]);
    return List.generate(maps.length, (i) => Curso.fromMap(maps[i]));
  }

  Future<List<Alumno>> getAlumnosPorCurso(int idCurso) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT alumnos.* FROM alumnos
      INNER JOIN matriculas ON alumnos.id = matriculas.id_alumno
      WHERE matriculas.id_curso = ?
    ''', [idCurso]);
    return List.generate(maps.length, (i) => Alumno.fromMap(maps[i]));
  }

  // --- Pagos ---
  Future<int> insertPago(Pago pago) async {
    final db = await database;
    return await db.insert('pagos', pago.toMap());
  }

  // Alias for old calls
  Future<int> insertarPago(Pago pago) => insertPago(pago);

  Future<List<Pago>> getTodosLosPagos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pagos', orderBy: 'fecha DESC');
    return List.generate(maps.length, (i) => Pago.fromMap(maps[i]));
  }

  Future<int> eliminarPago(int id) async {
    final db = await database;
    return await db.delete('pagos', where: 'id = ?', whereArgs: [id]);
  }

  // --- Asistencias ---
  Future<int> insertarAsistencia(Asistencia asistencia) async {
    final db = await database;
    return await db.insert('asistencias', asistencia.toMap());
  }

  Future<List<Asistencia>> getAsistenciasPorCursoYFecha(
      int idCurso, String fecha) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('asistencias',
        where: 'id_curso = ? AND fecha = ?', whereArgs: [idCurso, fecha]);
    return List.generate(maps.length, (i) => Asistencia.fromMap(maps[i]));
  }

  Future<void> registrarAsistenciasMultiples(List<Asistencia> asistencias) async {
    final db = await database;
    Batch batch = db.batch();
    for (var a in asistencias) {
      if (a.id != null) {
        batch.update('asistencias', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
      } else {
        batch.insert('asistencias', a.toMap());
      }
    }
    await batch.commit(noResult: true);
  }
}
