using Gee;

namespace Valatra {

  public class CacheEntry : GLib.Object {
    private Checksum checksum;

    public int size;
    public string content;
    public string etag;
    public DateTime modified;

    public CacheEntry(string cont, int sz = -1) {
      checksum = new Checksum(ChecksumType.MD5);

      content = cont;
      modified = new DateTime.now_utc();

      size = sz;

      update_etag();
    }

    public void update(string cont, int sz = -1) {
      content = cont;
      size = sz;

      modified = new DateTime.now_utc();

      update_etag();
    }

    public void update_etag() {
      checksum.update((uchar[])content, size);

      etag = checksum.get_string().dup();
      checksum = new Checksum(ChecksumType.SHA1);
    }
  }

  public class Cache : GLib.Object {
    private HashMap<string, CacheEntry> entries;

    public Cache() {
      entries  = new HashMap<string, CacheEntry>();
    }

    public void add(string path, string content) {
      var ent = new CacheEntry(content);
      this.set(path, ent);
    }

    public new void set(string path, CacheEntry entry) {
      entries.set(path, entry);
    }

    public new CacheEntry? get(string path) {
      return entries.get(path);
    }

    public void invalidate(string path) {
      if(entries.has_key(path)) {
        entries.unset(path);
      }
    }
  }
}

