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

    /* hacky: 7 is the size of HTTP_METHODS */
    private ArrayList<RouteWrapper> routes[7];

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

      for(int i = 0; i < HTTP_METHODS.length; ++i) {
        routes[i] = new ArrayList<RouteWrapper>();
      }

    }

    /* probably not a good idea to override get... */
    public new void get(string route, RouteFunc func) {
      this.route("GET", route, func);
    }

    public void post(string route, RouteFunc func) {
      this.route("POST", route, func);
    }

    public void route(string meth, string path, RouteFunc func) {
      int index = -1;
      for(int i = 0; i < HTTP_METHODS.length; ++i) {
        if(meth == HTTP_METHODS[i]) {
          index = i;
        }
      }

      if(index == -1) {
        stderr.printf("App.route(): Bad method: %s\n", meth);
        return;
      }

      var route = new Route(path);
      stdout.printf("Creating %s \"%s\"\n", meth, route.route);
      routes[index].add(new RouteWrapper(route, func));
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
        var dos = new DataOutputStream(conn.output_stream);

        var request = new HTTPRequest(conn);

        StringBuilder sb = new StringBuilder();

        while(true) {
          StringBuilder buf = new StringBuilder.sized(100);

          ssize_t ret = conn.socket.receive(buf.str, 100);

          if(ret > 0) {
            sb.append(buf.str[0 : ret]);
          }

          if(ret < 100) {
            break;
          }
        }

        var req_str = sb.str;

        while(true) {
          if(req_str == "" || req_str == null) {
            break;
          }
          var lines = req_str.split("\r\n", 2);
          req_str = lines[1];

          if(lines[0] == null) {
            break;
          } else if(lines[0] == "") {
            request.accept_body = true;
            request.parse(lines[1]);
            break;
          } else {
            request.parse(lines[0]);
          }
        }


        stdout.printf("%s, %s\n", request.method, request.path);

        int index = -1;
        for(int i = 0; i < HTTP_METHODS.length; ++i) {
          if(request.method == HTTP_METHODS[i]) {
            index = i;
          }
        }

        if(index == -1) {
          stderr.printf("App.route(): Bad method: %s\n", request.method);
          return;
        }

        ArrayList<RouteWrapper> array = routes[index];
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
          res.type("html");
          res.body = "<!doctype html><html><head><title>404</title></head><body><h1>404 Not found.</h1></body></html>";
        }

        res.create(dos);
      } catch (Error e) {
        stderr.printf("App.process_request(): %s\n", e.message);
      }
    }
  }
}

