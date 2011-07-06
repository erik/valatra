Valatra is a web framework with a terrible name based on Ruby's Sinatra
framework.

```vala
var app = new Valatra.App();
app.port = 3333;

app.get('/', (req, res) => {
  /* 200 by default */
  res.status = 200;

  /* sets content-type, 'text/html' by default */
  res.type("text/plain");

  /* set whatever HTTP header */
  res.headers["MY_HEADER"] = "Hello!";

  res.setBody("Hello World!");

});

// this would be called for a request to '/user/john', or '/user/123', etc
app.get("/user/:id", (req, res) => {
  var id = req.params["id"];
  // do something with id...
});

// Not implemented yet
app.post("/submit", (req, res) => {
  // if a POST was made to "/submit?title=My Awesome Title", req.params["title"]
  // would return that
  req.params["title"];
});

app.start();
```


## dependencies
Valatra depends on gio-2.0 and gee-1.0. Compiling on valac 0.12.0
