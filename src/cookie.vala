namespace Valatra {
  public class Cookie {
    public string name;
    public string val;
    public DateTime expires;
    public int max_age;
    public string path;
    public string domain;
    
    public Cookie(string name, string val) {
      this.name = name;
      this.val  = val;
      
      this.path = null;
      this.domain = null;
      this.expires = null;
      this.max_age = -1;
    }
    
    public string create() {
      StringBuilder str = new StringBuilder();
      str.append(@"$name=$val; ");

      if(path != null) {
        str.append(@"path=$path; ");
      }
      
      if(domain != null) {
        str.append(@"domain=$domain; ");
      }
      
      if(expires != null) {
        string dt = expires.format("%a, %d-%b-%Y %H:%M:%S GMT");
        str.append(@"expires=$dt; ");
      }
      
      if(max_age != -1) {
        str.append(@"Max-age=$max_age; ");
      }
      
      return str.str;
      
    }
  }
}
