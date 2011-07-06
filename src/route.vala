using GLib;
using Gee;

namespace Valatra {
  public class Route : Object {
    private string route_;
    private Regex regex_;
    private ArrayList<string> captures;
    
    public string route {
      get { return route_; }
      set { route_ = value;}
    }
    
    public Regex regex {
      get { return regex_; }
    }
    
    public Route(string route) {
      route_ = route;
      captures = new ArrayList<string>();
      
      try {
        compile();
      } catch(RegexError e) {
        stderr.printf("Route.new(): %s\n", e.message);
      }
    }
    
    // TODO: expand regex capabilities
    // compile the regexp
    public void compile() throws RegexError {
      Regex re = new Regex("(:\\w+)");
      var params = re.split_full(route_);
      
      StringBuilder route = new StringBuilder("^");
      
      foreach(var p in params) {
        if(p[0] != ':') {
          route.append(p);
        } else {
          var cap = p.slice(1, p.length);
          captures.add(cap);
          route.append(@"(?<$cap>\\w+)");
        }
      }
      
      route.append("$");
            
      route_ = route.str;
      regex_ = new Regex(route.str);      
    }
    
    public bool matches(HTTPRequest r) {      
      MatchInfo matchinfo;
      var result = regex_.match(r.path, 0, out matchinfo);
      
      if(result) {
        foreach(var cap in captures) {
          r.params[cap] = matchinfo.fetch_named(cap);
        }
      }
      
      return result;
    }
    
  }
}
