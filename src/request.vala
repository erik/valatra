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
    private string request_str;
    private SocketConnection conn;
    private string method_;
    private string request_uri_;
    private string request_ip_;
    private string request_path_;
    private string request_query_;
    
    public HashMap<string, string> params;
    public HashMap<string, string> headers;
    public HashMap<string, string> session;
    
    public string method {
      get { return method_; }
    }
    public string uri {
      get { return request_uri_; }
    }
    public string path {
      get { return request_path_; }
    }
    public string query {
      get { return request_query_; }
    }
    public string ip {
      get { return request_ip_; }
    }
  
    public HTTPRequest(string str, SocketConnection c) {
      headers = new HashMap<string, string>();
      params  = new HashMap<string, string>();
      session = new HashMap<string, string>();
      
      method_      = null;
      request_uri_ = null;
      
      request_str = str;
      conn = c;
    }
    
    public void parse() {
      InetSocketAddress addr;
      try {
        addr = (InetSocketAddress)conn.get_remote_address();
      } catch(Error e) {
        stderr.printf("HTTPRequest.parse().: %s\n", e.message);
        return;
      }
          
      request_ip_ = addr.get_address().to_string();
      
      var lines = request_str.split("\r");
      
      // find HTTP method
      var pieces = lines[0].split(" ");
      
      if(pieces.length != 3) {
        stderr.printf("Malformed request: \"%s\"\n", lines[0]);
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
        
        request_uri_ = uri;
        
        int ind = uri.index_of("?");
        if(ind == -1) {
          request_path_  = uri;
          request_query_ = null;
        } else {
          request_path_  = uri[0:ind];
          request_query_ = uri[ind + 1 : uri.length];
          
          string[] qparams = request_query_.split("&");
          foreach(string param in qparams) {
            string[] tmp = param.split("=", 2);
                        
            this.params[tmp[0]] = tmp[1];
          }
          
        }
        
        if(proto != "HTTP/1.1") {
          stderr.printf("Unsupported protocol: \"%s\"\n", proto);
        }                        
      }

      // ignore the blank line at the end      
      var rest = lines[1:lines.length - 1];
      
      foreach(string line in rest) {
        string[] split = line.split(":", 2);
        string field = split[0];
        string val   = split[1].strip();
        
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
