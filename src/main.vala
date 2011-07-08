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

  app.get("/:user/:post_id", (req, res) => {
    var user = req.params["user"];
    var post = req.params["post_id"];

    res.body = @"Hello $user, here is post #$post.";
  });

  app.get("/cookie", (req, res) => {
    var cookie = req.session["mycookie"];

    res.type("text/plain");

    // cookie times out in 5 seconds
    if(cookie == null) {

      var timeOut = new Cookie("mycookie", "abc");
      timeOut.max_age = 5;
      res.session["mycookie"] = timeOut;
      res.body = "Cookie was null, setting it to \"abc\"";

    } else {
      res.body = @"Cookie was not null, it was $cookie";
    }

  });

  app.post("/post", (req, res) => {
    var body = req.body;
    res.body = @"You sent me $body";
  });

  app.start();

  return 0;
}

