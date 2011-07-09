using Gee;

namespace Valatra {
  const string[] HTTP_METHODS = { "OPTIONS",
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "TRACE",
    "CONNECT"
  };

  // TODO: true error handling, rather than stderr
  public class HTTPRequest : GLib.Object {
    private StringBuilder str_;
    private SocketConnection conn;
    private string method_;
    private string uri_;
    private string ip_;
    private string path_;
    private string query_;
    private string body_;

    public bool accept_body;
    public unowned App app;

    public HashMap<string, string> params;
    public HashMap<string, string> headers;
    public HashMap<string, string> session;

    public string method {
      get { return method_; }
    }
    public string uri {
      get { return uri_; }
    }
    public string path {
      get { return path_; }
    }
    public string query {
      get { return query_; }
    }
    public string ip {
      get { return ip_; }
    }
    public string body {
      get { return body_; }
    }

    public HTTPRequest(SocketConnection c) {
      headers = new HashMap<string, string>();
      params  = new HashMap<string, string>();
      session = new HashMap<string, string>();

      method_ = null;
      uri_    = null;
      body_   = null;
      ip_     = null;

      conn = c;

      accept_body = false;

      str_    = new StringBuilder();
    }
    public void parse(string line) {
      str_.append(line);
      str_.append("\n");

      if(method_ == null) {
        var pieces = line.split(" ");

          if(pieces.length != 3) {
            stderr.printf("Malformed request: \"%s\"\n", line);
            return;
          } else {
            var method = pieces[0];
            var uri    = Uri.unescape_string(pieces[1]);
            var proto  = pieces[2];

            var validMethod = false;
            foreach(string meth in HTTP_METHODS) {
              if(meth == method) {
                validMethod = true;
                break;
              }
            }

            if(!validMethod) {
              stderr.printf("Invalid method: \"%s\"\n", method);
            }

            method_ = method;

            uri_ = uri;

            int ind = uri.index_of("?");
            if(ind == -1) {
              path_  = uri;
              query_ = null;
            } else {
              path_  = uri[0:ind];
              query_ = uri[ind + 1 : uri.length];

              string[] qparams = query_.split("&");
              foreach(string param in qparams) {
                string[] tmp = param.split("=", 2);

                this.params[tmp[0]] = tmp[1];
              }
            }

            if(proto != "HTTP/1.1") {
              stderr.printf("Unsupported protocol: \"%s\"\n", proto);
            }
          }
        }

        if(ip_ == null) {
          InetSocketAddress addr;
          try {
            addr = (InetSocketAddress)conn.get_remote_address();
          } catch(Error e) {
            stderr.printf("HTTPRequest.parse().: %s\n", e.message);
            return;
          }

          ip_ = addr.get_address().to_string();
        }

        if(accept_body) {
          body_ = line;

          var pieces = line.split("&");
          foreach(var piece in pieces) {
            piece   = piece.replace("+", " ");
            var tmp = piece.split("=", 2);

            params[Uri.unescape_string(tmp[0])] = Uri.unescape_string(tmp[1]);

          }

        } else {
          string[] split = line.split(":", 2);
          string field = split[0];
          string val   = split[1];

          if(field == null || val == null) {
            return;
          }

          this.headers[field] = val.strip();

          if(field == "Cookie") {
            string[] cookies = val.split(";");
            foreach(string cookie in cookies) {
              string[] tmp = cookie.split("=");
              session[tmp[0]] = tmp[1];
            }
          }
        }
    }
  }
}

