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

using VSGI;

int main (string[] args) {
	Test.init (ref args);

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi", () => {
		string[] environment = {
			"PATH_INFO=/",
			"QUERY_STRING=a=b",
			"REMOTE_USER=root",
			"REQUEST_METHOD=GET",
			"SERVER_NAME=0.0.0.0",
			"SERVER_PORT=3003",
			"HTTP_HOST=example.com"
		};

		var req_body = new MemoryInputStream ();
		var request  = new Request.from_cgi_environment (null, environment, req_body);

		assert (request.is_cgi);
		assert (Soup.HTTPVersion.@1_0 == request.http_version);
		assert ("CGI/1.1" == request.gateway_interface);
		assert ("GET" == request.method);
		assert ("root" == request.uri.get_user ());
		assert ("0.0.0.0" == request.uri.get_host ());
		assert ("a=b" == request.uri.get_query ());
		assert ("http://root@0.0.0.0:3003/?a=b" == request.uri.to_string (false));
		assert (request.query.contains ("a"));
		assert ("b" == request.query["a"]);
		assert (3003 == request.uri.get_port ());
		assert ("example.com" == request.headers.get_one ("Host"));
		assert (req_body != request.body);
	});

	/**
	 * @since 0.3
	 */
	Test.add_func ("/cgi/request/gateway-interface", () => {
		var request = new Request.from_cgi_environment (null, {"GATEWAY_INTERFACE=CGI/1.0"});

		assert ("CGI/1.0" == request.gateway_interface);
	});

	/**
	 * @since 0.3
	 */
	Test.add_func ("/cgi/request/content-type", () => {
		var request = new Request.from_cgi_environment (null, {"CONTENT_TYPE=text/html; charset=UTF-8"});

		HashTable<string, string> @params;
		assert ("text/html" == request.headers.get_content_type (out @params));
		assert ("UTF-8" == @params["charset"]);
	});

	/**
	 * @since 0.3
	 */
	Test.add_func ("/cgi/request/content-length", () => {
		var request = new Request.from_cgi_environment (null, {"CONTENT_LENGTH=12"});

		assert (12 == request.headers.get_content_length ());
	});

	/**
	 * @since 0.3
	 */
	Test.add_func ("/cgi/request/malformed-content-length", () => {
		var request = new Request.from_cgi_environment (null, {"CONTENT_LENGTH=12a"});

		assert (0 == request.headers.get_content_length ());
	});

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi/request/missing-path-info", () => {
		string[] environment = {};
		var request     = new Request.from_cgi_environment (null, environment);

		assert ("/" == request.uri.get_path ());
	});

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi/request/http-1-1", () => {
		string[] environment = {"SERVER_PROTOCOL=HTTP/1.1"};

		var request = new Request.from_cgi_environment (null, environment);

		assert (Soup.HTTPVersion.@1_1 == request.http_version);
	});

	/**
	 * @since 0.2.4
	 */
	Test.add_func ("/cgi/request/https-detection", () => {
		string[] environment = {"PATH_TRANSLATED=https://example.com:80/"};

		var request = new Request.from_cgi_environment (null, environment);

		assert ("https" == request.uri.scheme);
	});

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi/request/https-on", () => {
		string[] environment = {
			"PATH_INFO=/",
			"REQUEST_METHOD=GET",
			"REQUEST_URI=/",
			"SERVER_NAME=0.0.0.0",
			"SERVER_PORT=3003",
			"HTTPS=on"
		};

		var request    = new Request.from_cgi_environment (null, environment);

		assert ("https" == request.uri.scheme);
	});

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi/request-uri", () => {
		string[] environment = {
			"REQUEST_METHOD=GET",
			"SERVER_NAME=0.0.0.0",
			"SERVER_PORT=3003",
			"QUERY_STRING=a=b",
			"REQUEST_URI=/home?a=b"
		};

		var request    = new Request.from_cgi_environment (null, environment);

		assert ("GET" == request.method);
		assert ("/home" == request.uri.path);
		assert ("a" in request.query);
		assert ("b" == request.query["a"]);
	});

		/**
		 * @since 0.2
		 */
	Test.add_func ("/cgi/request-uri-with-query", () => {
		string[] environment = {
			"PATH_INFO=/home",
			"REQUEST_METHOD=GET",
			"SERVER_NAME=0.0.0.0",
			"SERVER_PORT=3003",
			"REQUEST_URI=/home?a=b"
		};

		var request    = new Request.from_cgi_environment (null, environment);

		assert ("/home" == request.uri.path);
	});

	/**
	 * @since 0.2
	 */
	Test.add_func ("/cgi/response", () => {
		string[] environment = {};
		var request     = new Request.from_cgi_environment (null, environment);
		var response    = new Response (request);

		assert (request.is_cgi);
		assert (Soup.Status.OK == response.status);

		size_t bytes_written;
		try {
			response.write_head (out bytes_written);
		} catch (IOError err) {
			assert_not_reached ();
		}
		assert (18 == bytes_written);
		assert (response.head_written);
	});

	return Test.run ();
}
