const int kInt64Max = 0x7FFFFFFFFFFFFFFF;
const int kInt64Min = 0x8000000000000000;

int combineHashCode(int hashFirst, int hashOther) {
  int hash = 17;
  hash = hash * 31 + hashFirst;
  hash = hash * 31 + hashOther;
  return hash;
}