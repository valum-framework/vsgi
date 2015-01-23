using Gee;
using Soup;

/**
 * Soup implementation of VSGI.
 */
namespace VSGI {

	/**
	 * Soup Request
	 */
	public class SoupRequest : VSGI.Request {

		private Soup.Message message;
		private HashMap<string, string> _environment = new HashMap<string, string> ();

		public override Map<string, string> environment { get { return this._environment; } }

		public override string method { owned get { return this.message.method ; } }

		public override URI uri { get { return this.message.uri; } }

		public override MessageHeaders headers {
			get {
				return this.message.request_headers;
			}
		}

		public SoupRequest(Soup.Message msg) {
			this.message = msg;
		}

		public override ssize_t read (uint8[] buffer, Cancellable? cancellable = null) {
			buffer = this.message.request_body.data;
			return this.message.request_body.data.length;
		}

		public override bool close(Cancellable? cancellable = null) {
			this.message.request_body.complete();
			return true;
		}
	}

	/**
	 * Soup Response
	 */
	public class SoupResponse : VSGI.Response {

		private Soup.Message message;

		public override string mime {
			get { return this.message.response_headers.get_content_type(null); }
			set { this.message.response_headers.set_content_type(value, null); }
		}

		public override uint status {
			get { return this.message.status_code; }
			set { this.message.set_status(value); }
		}

		public override MessageHeaders headers {
			get {
				return this.message.response_headers;
			}
		}

		public SoupResponse(Soup.Message msg) {
			this.message = msg;
		}

		public override ssize_t write(uint8[] buffer, Cancellable? cancellable = null) {
			this.message.response_body.append_take(buffer);
			return buffer.length;
		}

		public override bool close(Cancellable? cancellable = null) {
			this.message.response_body.complete();
			return true;
		}
	}

	/**
	 * Implementation of VSGI.Server based on Soup.Server.
	 */
	public class SoupServer : VSGI.Server {

		public SoupServer (VSGI.Application app) {
			base (app);
		}

		/**
		 * Creates a Soup.Server, bind the application to it using a closure and
		 * start the server.
		 */
		public override void listen () {

			var server = new Soup.Server (Soup.SERVER_SERVER_HEADER, VSGI.APP_NAME);

			Soup.ServerCallback soup_handler = (server, msg, path, query, client) => {

				var qry = new HashMap<string, string> ();

				if (query != null) {
					query.foreach((key, value) => {
						qry[key] = value;
					});
				}

				var req = new SoupRequest(msg);
				var res = new SoupResponse(msg);

				this.application.handler (req, res);
			};

			server.add_handler (null, soup_handler);

			server.listen_all(3003, Soup.ServerListenOptions.IPV4_ONLY);

			foreach (var uri in server.get_uris ()) {
				message("listening on %s", uri.to_string (false));
			}

			// run the server
			server.run ();
		}

	}
}
