using Gee;

namespace Valatra {
  public class HTTPResponse : GLib.Object {
    private int status_;
    private string status_msg_;
    private string body_;
    
    public HashMap<string, string> headers;
    public HashMap<string, Cookie> session;
    
    public int status {
      get { return status_; }
      set { status_ = value;}
    }
    
    public string status_msg {
      get { return status_msg_; }
      set { status_msg_ = value; }
    }
    
    public string body {
      get { return body_; }
      set { body_ = value;}
    }
    
    public HTTPResponse() {
      status_ = 200;
      status_msg_ = "OK";
      body_ = "";
      
      headers = new HashMap<string, string>();      
      session = new HashMap<string, Cookie>();
      
      default_headers();
    }
    
    public HTTPResponse.with_status(int status, string msg) {
      status_ = status;
      status_msg_ = msg;
      body_ = "";
      headers = new HashMap<string, string>();
      session = new HashMap<string, Cookie>();      
      
      default_headers();
    }
    
    private void default_headers() {
      headers["Connection"] = "close";
      headers["Content-type"] = "text/plain";
      headers["X-Powered-By"] = "valatra";
    }
    
    public void type(string t) {
      if(t == "html") {
        headers["Content-type"] = "text/html";
      } else if(t == "plain") {
        headers["Content-type"] = "text/plain";
      } else {
        // TODO: add more types
        headers["Content-type"] = t;
      }
    }
    
    public string create() {
      StringBuilder build = new StringBuilder();
      build.append(@"HTTP/1.1 $status_ $status_msg_\r\n");
      
      headers["Content-length"] = body_.length.to_string();
      
      foreach(var ent in headers.entries) {
        string key = ent.key;
        string val = ent.value;
        
        stdout.printf(@"$key => $val\n");
        
        build.append(@"$key: $val\r\n");
      }
      
      foreach(var cookie in session.entries) {
        var val = cookie.value.create();
        
        build.append(@"Set-cookie: $val\r\n");
      }
            
      build.append(@"\r\n$body_");
      
      return build.str;
    }    
  }
}
