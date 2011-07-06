using Gee;

namespace Valatra {
  public delegate void RouteFunc(HTTPRequest req, HTTPResponse res);
  
  private class RouteWrapper : GLib.Object {
    private unowned RouteFunc func_;
    private Route route_;
    
    public RouteFunc func {
      get { return func_; }
      set { func_ = value;}
    }
    
    public Route route {
      get { return route_; }
      set { route_ = value; }
    }
    
    public RouteWrapper(Route r, RouteFunc f) {
      func_ = f;
      route_ = r;
    }
    
  }
  
  public class App : GLib.Object {
  
    private uint16 port_ = 3000;
    private SocketService server;
        
    /* since delegates can't be stored directly, this needs to be done */
    /* HTTP method => [{ path, func }]*/
    // TODO: using a HashMap here is not needed
    private HashMap<string, ArrayList<RouteWrapper>> routes;

    public uint16 port {
      get { return port_; }
      set {
        port_ = value;
        try {
          server.add_inet_port(value, null);
        } catch(Error e) {
          stderr.printf("App.port.set: %s\n", e.message);
        }
      }
    }
  
    public App() {
      server = new SocketService();
      routes = new HashMap<string, ArrayList<RouteWrapper>>();
    }
    
    /* probably not a good idea to override get... */
    public new void get(string route, RouteFunc func) {
      this.route("GET", route, func);
    }
    
    public void route(string meth, string path, RouteFunc func) {
      var route = new Route(path);
      if(routes[meth] == null) {
        stdout.printf("Creating %s\n", meth);
        routes[meth] = new ArrayList<RouteWrapper>();
      }
      stdout.printf("Creating %s \"%s\"\n", meth, route.route);
      routes[meth].add(new RouteWrapper(route, func));
    }

    public async bool start() {
    
        server.incoming.connect( (conn) => {
          InetSocketAddress addr;
          try {
            addr = (InetSocketAddress)conn.get_remote_address();
          } catch(Error e) {
            stderr.printf("App.start().incoming: %s\n", e.message);
            return false;
          }
          
          string str = addr.get_address().to_string();
          
          stdout.printf("Got a connection from >%s<\n", str);
          process_request.begin (conn);
          
          return true;
        });
        
        stdout.printf("Starting Valatra server on port %d...\n", port_);
        
        server.start();
        new MainLoop().run();
        
        return true;
    }
      
    private async void process_request(SocketConnection conn) {
      try {
        var dis = new DataInputStream(conn.input_stream);
        var dos = new DataOutputStream(conn.output_stream);

        StringBuilder req_str = new StringBuilder();

        while(true) {
          string line = yield dis.read_line_async(Priority.HIGH_IDLE);
          
          // end of headers
          if(line == "\r") {
            break;
          }
          
          req_str.append(line);
        }
        
        var request = new HTTPRequest(req_str.str, conn);
        request.parse();
        
        stdout.printf("%s, %s\n", request.method, request.path);
        
        ArrayList<RouteWrapper> array = routes[request.method];
        RouteWrapper wrap = null;
        
        foreach(var elem in array) {
          if(elem.route.matches(request)) {
            wrap = elem;
            break;
          }
        }        
        
        HTTPResponse res = null;       
        
        if(wrap != null) {
          res = new HTTPResponse();
          wrap.func(request, res);
        } else {
          res = new HTTPResponse.with_status(404, "Not found");
        }
        
        string msg = res.create();
        
        dos.put_string(msg);
                        
      } catch (Error e) {
        stderr.printf("App.process_request(): %s\n", e.message);
      } 
    }
  }
}
