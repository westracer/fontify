class EnumClass<K, V> {
  const EnumClass(this._map);

  final Map<K, V> _map;

  K getKeyForValue(V value) {
    final entry = _map.entries.firstWhere(
      (entry) => entry.value == value, 
      orElse: () => null
    );

    return entry?.key;
  }

  V getValueForKey(K key) {
    return _map[key];
  }
}