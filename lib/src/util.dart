
String safeSubstring(String src, int length)
{
  return src.length > length ? src.substring(1,length) : src;
}