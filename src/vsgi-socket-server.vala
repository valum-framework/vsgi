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

/**
 * Base for implementing a server upon {@link GLib.SocketService}.
 */
[Version (since = "0.3")]
public abstract class VSGI.SocketServer : Server {

	[Version (since = "0.3")]
	[Description (blurb = "Listen queue depth used in the listen() call")]
	public int backlog { construct; get; default = 10; }

	/**
	 * Scheme used for generated listening {@link Uri}.
	 */
	[Version (since = "0.3")]
	protected abstract string scheme { get; }

	private SList<Uri> _uris = new SList<Uri> ();

	public override SList<Uri> uris {
		owned get {
			var copy_uris = new SList<Uri> ();
			foreach (var uri in _uris) {
				// no need to copy the URI itself since it is immutable
				copy_uris.append (uri);
			}
			return copy_uris;
		}
	}

	private SocketService socket_service = new SocketService ();

	construct {
		socket_service.incoming.connect (incoming);
		socket_service.set_backlog (backlog);
		socket_service.start ();
	}

	public override void listen (SocketAddress? address = null) throws Error {
		if (address == null) {
			throw new IOError.NOT_SUPPORTED ("The implementation does not support a default listening interface.");
		} else {
			SocketAddress effective_address;
			socket_service.add_address (address,
			                            SocketType.STREAM,
			                            SocketProtocol.DEFAULT,
			                            null,
			                            out effective_address);
			string scheme;
			string? host;
			string path;
			int port;
			if (effective_address is InetSocketAddress) {
				var effective_inet_address = effective_address as InetSocketAddress;
				if (effective_inet_address.get_family () == SocketFamily.IPV4) {
					scheme = "ipv4";
				} else if (effective_inet_address.get_family () == SocketFamily.IPV6) {
					scheme = "ipv6";
				}
				scheme = this.scheme;
				host = effective_inet_address.get_address ().to_string ();
				path = "/";
				port = effective_inet_address.get_port ();
			} else if (effective_address is UnixSocketAddress) {
				var effective_unix_address = effective_address as UnixSocketAddress;
				scheme = this.scheme + "+unix";
				host = null;
				path = effective_unix_address.get_path ();
				port = 0;
			} else {
				assert_not_reached ();
			}
			_uris.append (Uri.build (UriFlags.NONE, scheme, null, host, port, path, null, null));
		}
	}

	public override void listen_socket (Socket socket) throws Error {
		socket_service.add_socket (socket, null);
		_uris.append (Uri.build (UriFlags.NONE, scheme + "+fd", null, null, 0, socket.get_fd ().to_string (), null, null));
	}

	public override void stop () {
		socket_service.stop ();
	}

	/**
	 * Dispatch an incoming socket connection.
	 */
	[Version (since = "0.3")]
	protected abstract bool incoming (SocketConnection connection);
}
