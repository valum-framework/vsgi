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

namespace VSGI {

	/**
	 * Server that feeds a {@link VSGI.Handler} with incoming requests.
	 *
	 * Once you have initialized a Server instance, start it by calling
	 * {@link GLib.Application.run} with the command-line arguments or a set of
	 * predefined arguments.
	 *
	 * The server should be implemented by overriding the
	 * {@link GLib.Application.command_line} signal.
	 */
	[Version (since = "0.1")]
	public abstract class Server : Object {

		private static HashTable<string, ServerModule>? _server_modules = null;

		/**
		 * Instantiate a new {@link VSGI.Server} instance.
		 *
		 * If the 'VSGI_SERVER_PATH' environment variable is set, it will used
		 * instead of the default system path.
		 *
		 * For a more fine-grained control, use {@link VSGI.ServerModule}.
		 *
		 * @param name name of the server implementation to load
		 * @param list arguments to pass to {@link GLib.Object.new_valist}
		 *
		 * @return the server instance of loaded successfully, otherwise 'null'
		 *         and a critical will be emitted
		 */
		[Version (since = "0.3")]
		public static new Server? @new_valist (string name, va_list list) {
			if (_server_modules == null)
				_server_modules = new HashTable<string, ServerModule> (str_hash, str_equal);
			if (_server_modules[name] == null) {
				var server_module = new ServerModule (Environment.get_variable ("VSGI_SERVER_PATH"), name);
				if (!server_module.load ())
					return null;
				_server_modules[name] = server_module;
			}
			var server = Object.@new_valist (_server_modules[name].server_type, list.arg<string> (), list) as Server;
			if (server is Initable) {
				try {
					((Initable) server).init ();
				} catch (Error err) {
					critical (err.message);
					return null;
				}
			}
			return server;
		}

		/**
		 * Instantiate a new {@link VSGI.Server} with varidic arguments.
		 */
		[Version (since = "0.3")]
		public static new Server? @new (string name, ...) {
			return @new_valist (name, va_list ());
		}

		/**
		 * Instantiate a new {@link VSGI.Server} with an initial handler.
		 *
		 * This constructor is merely meant for GI, so {@link Server.new} instead
		 * with a keyword argument for the handler.
		 *
		 * This will likely be removed in the future once we binding generation
		 * will be support the above pattern.
		 */
		[Version (since = "0.4", experimental = true)]
		public static new Server? new_with_handler (string name, Handler handler) {
			return @new (name, handler: handler);
		}

		/**
		 * Handler processing incoming connections.
		 */
		[Version (since = "0.3")]
		public Handler handler { get; construct set; }

		/**
		 * URIs this server is listening on.
		 */
		[Version (since = "0.3")]
		public abstract SList<Uri> uris { owned get; }

		/**
		 * Prepare the server for listening on the provided socket address.
		 *
		 * Once the {@link GLib.MainLoop} is started, the server should start
		 * accepting incoming connections.
		 *
		 * @param address a {@link GLib.SocketAddress} or 'null' to listen on
		 *                the default interface
		 *
		 * @throws GLib.IOError.NOT_SUPPORTED if the server does not support
		 *                                    listening on the provided address
		 */
		[Version (since = "0.3")]
		public abstract void listen (SocketAddress? address = null) throws Error;

		/**
		 * Prepare the server for listening on the provided socket.
		 *
		 * Once the {@link GLib.MainLoop} is started, the server should start
		 * accepting incoming connections.
		 *
		 * @throws GLib.IOError.NOT_SUPPORTED if the server does not support
		 *                                    listening on the provided address
		 */
		[Version (since = "0.3")]
		public abstract void listen_socket (Socket socket) throws Error;

		/**
		 * Stop accepting new connections.
		 */
		[Version (since = "0.3")]
		public abstract void stop ();

		/**
		 * Fork the execution.
		 *
		 * This is typically called after {@link VSGI.Server.listen} such that
		 * workers can share listening interfaces and descriptors.
		 *
		 * The default implementation wraps {@link Posix.fork} and check its
		 * return value. To disable forking, simply override this and return
		 * '0'.
		 *
		 * Marked as experimental because we might change this for a more
		 * sophisticated model based in {@link GLib.Subprocess} in the future.
		 *
		 * @throws GLib.SpawnError.FORK if the {@link Posix.fork} call fails
		 *
		 * @return the process pid if this is the parent process,
		 *         otherwise '0'
		 */
		[Version (since = "0.3", experimental = true)]
		public virtual Pid fork () throws Error {
			var pid = Posix.fork ();
			if (pid == -1) {
				throw new SpawnError.FORK (strerror (errno));
			}
			return pid;
		}

		/**
		 * Create a new {@link VSGI.Application} that cushion the execution of
		 * this server.
		 */
		[Version (since = "0.3")]
		public int run (string[] args = {}) {
			return new Application (this).run (args);
		}
	}
}
