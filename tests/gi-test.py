import unittest
import gi
gi.require_version('GLib', '2.0')
gi.require_version('Soup', '2.4')
gi.require_version('VSGI', '0.4')
from gi.repository import GLib, Soup, VSGI

class App(VSGI.Handler):
    def do_handle(self, req, res):
        return res.expand_utf8('Hello world!')

class GiTest(unittest.TestCase):
    def test_handler(self):
        app = App()

        req = VSGI.Request(uri=Soup.URI.new("http://localhost:3003/"))
        res = VSGI.Response(request=req)

        self.assertTrue(app.handle(req, res))
        payload = req.get_connection().get_output_stream().steal_as_bytes().get_data()
        self.assertTrue(payload.endswith(b'Hello world!'))

    def test_server(self):
        server = VSGI.Server.new_with_handler('http', App())
        server.listen()
        self.assertTrue(len(server.get_uris()) > 0)

if __name__ == '__main__':
    unittest.main()
