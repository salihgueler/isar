part of isar_generator;

const _updateableTypes = [
  PropertyType.bool,
  PropertyType.byte,
  PropertyType.int,
  PropertyType.long,
  PropertyType.float,
  PropertyType.double,
  PropertyType.dateTime,
  PropertyType.string,
];

String _generateUpdate(ObjectInfo oi) {
  final updateProperties = oi.properties
      .where((p) => !p.isId && _updateableTypes.contains(p.type))
      .toList();

  if (updateProperties.isEmpty) {
    return '';
  }

  return '''
  sealed class _${oi.dartName}Update {
    bool call({
      required ${oi.idProperty!.dartType} ${oi.idProperty!.dartName},
      ${updateProperties.map((p) => '${p.scalarDartTypeNotNull}? ${p.dartName},').join('\n')}
    });
  }

  class _${oi.dartName}UpdateImpl implements _${oi.dartName}Update {
    const _${oi.dartName}UpdateImpl(this.collection);

    final IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> collection;

    @override
    bool call({
      required ${oi.idProperty!.dartType} ${oi.idProperty!.dartName},
      ${updateProperties.map((p) => 'Object? ${p.dartName} = ignore,').join('\n')}
    }) {
      return collection.updateProperties(
        [${oi.idProperty!.dartName}], 
        {
          ${updateProperties.map((p) => 'if (${p.dartName} != ignore) ${p.index}: ${p.dartName} as ${p.scalarDartTypeNotNull}?,').join('\n')}
        }
      ) > 0;
    }
  }

  sealed class _${oi.dartName}UpdateAll {
    int call({
      required List<${oi.idProperty!.dartType}> ${oi.idProperty!.dartName},
      ${updateProperties.map((p) => '${p.scalarDartTypeNotNull}? ${p.dartName},').join('\n')}
    });
  }

  class _${oi.dartName}UpdateAllImpl implements _${oi.dartName}UpdateAll {
    const _${oi.dartName}UpdateAllImpl(this.collection);

    final IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> collection;

    @override
    int call({
      required List<${oi.idProperty!.dartType}> ${oi.idProperty!.dartName},
      ${updateProperties.map((p) => 'Object? ${p.dartName} = ignore,').join('\n')}
    }) {
      return collection.updateProperties(
        ${oi.idProperty!.dartName}, 
        {
          ${updateProperties.map((p) => 'if (${p.dartName} != ignore) ${p.index}: ${p.dartName} as ${p.scalarDartTypeNotNull}?,').join('\n')}
        }
      );
    }
  }

  extension ${oi.dartName}Update on IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> {
    _${oi.dartName}Update get update => _${oi.dartName}UpdateImpl(this);

    _${oi.dartName}UpdateAll get updateAll => _${oi.dartName}UpdateAllImpl(this);
  }

  sealed class _${oi.dartName}QueryUpdate {
    int call({
      ${updateProperties.map((p) => '${p.scalarDartTypeNotNull}? ${p.dartName},').join('\n')}
    });
  }

  class _${oi.dartName}QueryUpdateImpl implements _${oi.dartName}QueryUpdate {
    const _${oi.dartName}QueryUpdateImpl(this.query, {this.limit});

    final IsarQuery<${oi.dartName}> query;
    final int? limit;

    @override
    int call({
      ${updateProperties.map((p) => 'Object? ${p.dartName} = ignore,').join('\n')}
    }) {
      return query.updateProperties(
        limit: limit, 
        {
          ${updateProperties.map((p) => 'if (${p.dartName} != ignore) ${p.index}: ${p.dartName} as ${p.scalarDartTypeNotNull}?,').join('\n')}
        }
      );
    }
  }

  extension ${oi.dartName}QueryUpdate on IsarQuery<${oi.dartName}> {
    _${oi.dartName}QueryUpdate get updateFirst => _${oi.dartName}QueryUpdateImpl(this, limit: 1);

    _${oi.dartName}QueryUpdate get updateAll => _${oi.dartName}QueryUpdateImpl(this);
  }
  ''';
}
