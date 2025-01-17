part of isar;

/// The Isar storage engine.
enum IsarEngine {
  /// The native Isar storage engine.
  isar,

  /// The SQLite storage engine.
  sqlite
}

/// An Isar database instance.
@pragma('vm:isolate-unsendable')
abstract class Isar {
  /// The default Isar instance name.
  static const String defaultName = 'default';

  /// The default max Isar size.
  static const int defaultMaxSizeMiB = 128;

  /// The current Isar version.
  static const String version = '4.0.0-dev.2';

  /// Get an already opened Isar instance by its name.
  ///
  /// This method is especially useful to get an Isar instance from an isolate.
  /// It is much faster than using [open].
  static Isar get({
    required List<IsarCollectionSchema> schemas,
    String name = Isar.defaultName,
  }) {
    return _IsarImpl.getByName(name: name, schemas: schemas);
  }

  /// Open a new Isar instance.
  ///
  /// {@template isar_open}
  /// You have to provide a list of all collection [schemas] that you want to
  /// use in this instance as well as a [directory] where the database file
  /// should be stored.
  ///
  /// You can optionally provide a [name] for this instance. This is needed if
  /// you want to open multiple instances.
  ///
  /// If [encryptionKey] is provided, the database will be encrypted with the
  /// provided key. Opening an encrypted database with an incorrect key will
  /// result in an error. Only the SQLite storage engine supports encryption.
  ///
  /// [maxSizeMiB] is the maximum size of the database file in MiB. It is
  /// recommended to set this value as low as possible. Older devices might
  /// not be able to grant the requested amount of virtual memory. In that case
  /// Isar will try to use as much memory as possible.
  ///
  /// [compactOnLaunch] is a condition that triggers a database compaction
  /// on launch when the specified conditions are met. Only the Isar storage
  /// engine supports compaction.
  ///
  /// [inspector] enables the Isar inspector when the app is running in debug
  /// mode. In release mode the inspector is always disabled.
  /// {@endtemplate}
  static Isar open({
    required List<IsarCollectionSchema> schemas,
    required String directory,
    String name = Isar.defaultName,
    IsarEngine engine = IsarEngine.isar,
    int? maxSizeMiB = Isar.defaultMaxSizeMiB,
    String? encryptionKey,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) {
    return _IsarImpl.open(
      schemas: schemas,
      directory: directory,
      name: name,
      engine: engine,
      maxSizeMiB: maxSizeMiB,
      encryptionKey: encryptionKey,
      compactOnLaunch: compactOnLaunch,
    );
  }

  /// Open a new Isar instance asynchronously.
  ///
  /// {@macro isar_open}
  static Future<Isar> openAsync({
    required List<IsarCollectionSchema> schemas,
    required String directory,
    String name = Isar.defaultName,
    IsarEngine engine = IsarEngine.isar,
    int? maxSizeMiB = Isar.defaultMaxSizeMiB,
    String? encryptionKey,
    CompactCondition? compactOnLaunch,
    bool inspector = true,
  }) async {
    await Isolate.run(
      () {
        Isar.open(
          schemas: schemas,
          directory: directory,
          name: name,
          engine: engine,
          maxSizeMiB: maxSizeMiB,
          compactOnLaunch: compactOnLaunch,
          inspector: inspector,
        );
      },
      debugName: 'Isar open async',
    );
    return Isar.get(schemas: schemas, name: name);
  }

  /// Name of the instance.
  String get name;

  /// The directory containing the database file.
  String get directory;

  /// Whether this instance is open and active.
  ///
  /// The instance is open until [close] is called. After that, all operations
  /// will throw an [IsarNotReadyError].
  bool get isOpen;

  /// Get a collection by its type.
  ///
  /// You should use the generated extension methods instead. A collection
  /// `User` can be accessed with `isar.users`.
  IsarCollection<ID, OBJ> collection<ID, OBJ>();

  /// Create a synchronous read transaction.
  ///
  /// Explicit read transactions are optional, but they allow you to do atomic
  /// reads and rely on a consistent state of the database inside the
  /// transaction. Internally Isar always uses implicit read transactions for
  /// all read operations.
  ///
  /// It is recommended to use an explicit read transactions when you want to
  /// perform multiple subsequent read operations.
  ///
  /// Example:
  /// ```dart
  /// final (user, workspace) = isar.read((isar) {
  ///   final user = isar.users.where().findFirst();
  ///   final workspace = isar.workspaces.where().findFirst();
  ///   return (user, workspace);
  /// });
  /// ```
  T read<T>(T Function(Isar isar) callback);

  /// Create a synchronous read-write transaction.
  ///
  /// Unlike read operations, write operations in Isar must be wrapped in an
  /// explicit transaction.
  ///
  /// When a write transaction finishes successfully, it is automatically
  /// committed, and all changes are written to disk. If an error occurs, the
  /// transaction is aborted, and all the changes are rolled back. Transactions
  /// are “all or nothing”: either all the writes within a transaction succeed,
  /// or none of them take effect to guarantee data consistency.
  ///
  /// Example:
  /// ```dart
  /// isar.write((isar) {
  ///   final user = User(name: 'John');
  ///   isar.users.put(user);
  /// });
  /// ```
  T write<T>(T Function(Isar isar) callback);

  /// Create an asynchronous read transaction.
  ///
  /// The code inside the callback will be executed in a separate isolate.
  ///
  /// Check out the [read] method for more information.
  Future<T> readAsync<T>(T Function(Isar isar) callback, {String? debugName}) =>
      readAsyncWith(null, (isar, _) => callback(isar), debugName: debugName);

  /// Create an asynchronous read transaction and pass a parameter to the
  /// callback.
  ///
  /// The code inside the callback will be executed in a separate isolate.
  ///
  /// Check out the [read] method for more information.
  Future<T> readAsyncWith<T, P>(
    P param,
    T Function(Isar isar, P param) callback, {
    String? debugName,
  });

  /// Create an asynchronous read-write transaction.
  ///
  /// The code inside the callback will be executed in a separate isolate.
  ///
  /// Check out the [write] method for more information.
  Future<T> writeAsync<T>(
    T Function(Isar isar) callback, {
    String? debugName,
  }) =>
      writeAsyncWith(null, (isar, _) => callback(isar), debugName: debugName);

  /// Create an asynchronous read-write transaction and pass a parameter to the
  /// callback.
  ///
  /// The code inside the callback will be executed in a separate isolate.
  ///
  /// Check out the [write] method for more information.
  Future<T> writeAsyncWith<T, P>(
    P param,
    T Function(Isar isar, P param) callback, {
    String? debugName,
  });

  /// Returns the size of all the collections in bytes.
  ///
  /// For the native Isar storage engine this method is extremely fast and
  /// independent of the number of objects in the instance.
  int getSize({bool includeIndexes = false});

  /// Copy a compacted version of the database to the specified file.
  ///
  /// If you want to backup your database, you should always use a compacted
  /// version. Compacted does not mean compressed.
  ///
  /// Do not run this method while other transactions are active to avoid
  /// unnecessary growth of the database.
  void copyToFile(String path);

  /// Remove all data in this instance.
  void clear();

  /// Releases an Isar instance.
  ///
  /// If this is the only isolate that holds a reference to this instance, the
  /// Isar instance will be closed. [deleteFromDisk] additionally removes all
  /// database files if enabled.
  ///
  /// Returns whether the instance was actually closed.
  bool close({bool deleteFromDisk = false});

  /// Verifies the integrity of the database. This method is not intended to be
  /// used by end users and should only be used by Isar tests. Never call this
  /// method on a production database.
  @visibleForTesting
  void verify();

  /// Initialize Isar Core manually. You need to provide Isar Core libraries
  /// for every platform your app will run on.
  ///
  /// Only use this method for non-Flutter code or unit tests.
  static void initializeIsarCore({Map<Abi, String> libraries = const {}}) {
    IsarCore._initialize(libraries: libraries);
  }

  /// FNV-1a 64bit hash algorithm optimized for Dart Strings
  static int fastHash(String string) {
    // ignore: avoid_js_rounded_ints
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }
}
