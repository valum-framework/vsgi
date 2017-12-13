# Vala Server Gateway Interface

VSGI is a middleware that interfaces different Web server technologies under a common and simple set of abstractions.

```vala
using VSGI;

class App : Handler 
{
    public override async bool handle_async (Request req, Response res) throws Error 
    {
        return yield res.expand_utf8_async ("Hello world!");
    }
}

Server.@new ("http", handler: new App ()).run ({"app", "--address=0.0.0.0:3003", "--forks=4"});
```
