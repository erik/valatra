/* TODO: this should be a tester, not main */

using Valatra;

public static int main (string[] args) {
  var app = new App();
  app.port = 3333;
    
  app.get("/", (req, res) => {
    res.type("html");
    
    string ip = req.ip;    
    res.body = @"<h1>Hello from Vala!<br>Your IP is $ip</h1>";
  });
  
  app.start();
  
  return 0;
}
