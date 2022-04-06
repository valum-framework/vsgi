/*
 * This file is part of Valum.
 *
 * Valum is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Valum is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Valum.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Soup;

[ModuleInit]
public Type server_init (TypeModule type_module) {
	return typeof (VSGI.HTTP.Server);
}

/**
 * HTTP implementation of VSGI.
 */
namespace VSGI.HTTP {

	private class MessageBodyOutputStream : OutputStream {

		internal bool finished = false;

		public Soup.Server server { construct; get; }

		public Soup.Message message { construct; get; }

		public MessageBodyOutputStream (Soup.Server server, Message message) {
			Object (server: server, message: message);
		}

		construct {
			message.finished.connect (() => finished = true);
		}

		public override ssize_t write (uint8[] data, Cancellable? cancellable = null) throws IOError {
			if (unlikely (finished)) {
				// FIXME: throw a IOError here
				return -1;
			}
			message.response_body.append_take (data);
			return data.length;
		}

		/**
		 * Resume I/O on the underlying {@link Soup.Message} to flush the
		 * written chunks.
		 */
		public override bool flush (Cancellable? cancellable = null) throws IOError {
			if (finished) {
				throw new IOError.CONNECTION_CLOSED ("Connection closed by peer.");
			}
			server.unpause_message (message);
			return true;
		}

		public override bool close (Cancellable? cancellable = null) throws IOError {
			if (finished) {
				throw new IOError.CONNECTION_CLOSED ("Connection closed by peer.");
			}
			message.response_body.complete ();
			return true;
		}
	}

	/**
	 * Soup Request
	 */
	private class Request : VSGI.Request {

		private bool finished = false;

		/**
		 * Message underlying this request.
		 */
		public Message message { construct; get; }

		public ClientContext client_context { construct; get; }

		/**
		 * {@inheritDoc}
		 *
		 * @param connection contains the connection obtain from
		 *                   {@link Soup.ClientContext.steal_connection} or a
		 *                   stud if it is not available
		 * @param msg        message underlying this request
		 * @param query      parsed HTTP query provided by {@link Soup.ServerCallback}
		 */
		public Request (Message                    msg,
		                ClientContext              client_context,
		                HashTable<string, string>? query) {
			Object (message:           msg,
			        client_context:    client_context,
			        http_version:      msg.http_version,
			        gateway_interface: "HTTP/1.1",
			        method:            msg.method,
			        uri:               msg.uri,
			        query:             query,
			        headers:           msg.request_headers,
			        body:              new MemoryInputStream.from_data (msg.request_body.data, null));
		}

		construct {
			message.finished.connect (() => finished = true);
		}

		public override IOStream? steal_connection () {
			if (finished) {
				return null;
			}
			try {
				return _client_context == null ? null : client_context.steal_connection ();
			} finally {
				_client_context = null;
			}
		}
	}

	/**
	 * Soup Response
	 */
	private class Response : VSGI.Response {

		private bool finished = false;

		public Soup.Server soup_server { construct; get; }

		/**
		 * Message underlying this response.
		 */
		public Message message { construct; get; }

		public override uint status {
			get { return this.message.status_code; }
			set { this.message.status_code = value; }
		}

		public override string? reason_phrase {
			owned get { return this.message.reason_phrase == "Unknown Error" ? null : this.message.reason_phrase; }
			set { this.message.reason_phrase = value ?? Status.get_phrase (this.message.status_code); }
		}

		/**
		 * {@inheritDoc}
		 *
		 * @param msg message underlying this response
		 */
		public Response (Request req, Soup.Server soup_server, Message msg) {
			Object (request:     req,
			        soup_server: soup_server,
			        message:     msg,
			        headers:     msg.response_headers,
			        body:        new MessageBodyOutputStream (soup_server, msg));
		}

		construct {
			message.wrote_informational.connect (() => {
				wrote_headers (headers);
			});
			message.wrote_headers.connect (() => {
				wrote_headers (headers);
			});
			message.finished.connect (() => {
				finished = true;
			});
		}

		/**
		 * {@inheritDoc}
		 *
		 * Implementation based on {@link Soup.Message} already handles the
		 * writing of the status line.
		 */
		protected override bool write_status_line (HTTPVersion http_version, uint status, string reason_phrase, out size_t bytes_written, Cancellable? cancellable = null) throws IOError {
			if (finished) {
				throw new IOError.CONNECTION_CLOSED ("Connection closed by peer.");
			}
			bytes_written = 0;
			return true;
		}

		/**
		 * {@inheritDoc}
		 *
		 * Implementation based on {@link Soup.Message} already handles the
		 * writing of the headers.
		 */
		protected override bool write_headers (MessageHeaders headers, out size_t bytes_written, Cancellable? cancellable = null) throws IOError {
			if (finished) {
				throw new IOError.CONNECTION_CLOSED ("Connection closed by peer.");
			}
			bytes_written = 0;
			soup_server.unpause_message (message);
			return true;
		}
	}

	/**
	 * Implementation of VSGI.Server based on Soup.Server.
	 */
	[Version (since = "0.1")]
	public class Server : VSGI.Server, Initable {

		[Version (since = "0.3")]
		[Description (blurb = "Listen for HTTPS connections rather than plain HTTP")]
		public bool https { construct; get; default = false; }

		[Version (since = "0.3")]
		[Description (blurb = "TLS certificate containing both a PEM-Encoded certificate and private key")]
		public TlsCertificate? tls_certificate { construct; get; default = null; }

		[Version (since = "0.3")]
		[Description (blurb = "Value to use for the 'Server' header on Messages processed by this server")]
		public string? server_header { construct; get; default = null; }

		[Version (since = "0.3")]
		[Description (blurb = "Percent-encoding in the Request-URI path will not be automatically decoded")]
		public bool raw_paths { construct; get; default = false; }

		public override SList<URI> uris {
			owned get {
				return server.get_uris ();
			}
		}

		private Soup.Server server;

		private ServerListenOptions server_listen_options = 0;

		public bool init (Cancellable? cancellable = null) throws GLib.Error {
			if (https) {
				server = new Soup.Server (
					SERVER_RAW_PATHS,       raw_paths,
					SERVER_TLS_CERTIFICATE, tls_certificate);
			} else {
				server = new Soup.Server (
					SERVER_RAW_PATHS,       raw_paths,
					SERVER_TLS_CERTIFICATE, tls_certificate);
			}

			// register a catch-all handler
			server.add_handler (null, (server, msg, path, query, client) => {
				msg.set_status (Status.OK);

				// prevent I/O as we handle everything asynchronously
				server.pause_message (msg);

				var req = new Request (msg, client, query);
				var res = new Response (req, server, msg);

				var auth = req.headers.get_one ("Authorization");
				if (auth != null) {
					if (str_case_equal (auth.slice (0, 6), "Basic ")) {
						var auth_data = (string) Base64.decode (auth.substring (6));
						if (auth_data.index_of_char (':') != -1) {
							req.uri.set_user (auth_data.slice (0, auth.index_of_char (':')));
						}
					} else if (str_case_equal (auth.slice (0, 7), "Digest ")) {
						var auth_data = header_parse_param_list (auth.substring (7));
						req.uri.set_user (auth_data["username"]);
					}
				}

				handler.handle_async.begin (req, res, (obj, result) => {
					try {
						handler.handle_async.end (result);
					} catch (Error err) {
						critical ("%s", err.message);
					}
				});
			});

			if (server_header != null)
				server.server_header = server_header;

			if (https)
				server_listen_options |= ServerListenOptions.HTTPS;

			return true;
		}

		public override void listen (SocketAddress? address = null) throws GLib.Error {
			if (address == null) {
				server.listen_local (3003, server_listen_options);
			} else {
				server.listen (address, server_listen_options);
			}
		}

		public override void listen_socket (GLib.Socket socket) throws GLib.Error {
			server.listen_socket (socket, server_listen_options);
		}

		public override void stop () {
			server.disconnect ();
		}
	}
}
