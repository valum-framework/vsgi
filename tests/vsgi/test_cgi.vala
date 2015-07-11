using VSGI.CGI;

/**
 * @since 0.2
 */
public static void test_vsgi_cgi_request () {
	var environment   = new HashTable<string, string> (str_hash, str_equal);

	environment["PATH_INFO"]      = "/";
	environment["QUERY_STRING"]   = "a=b";
	environment["REMOTE_USER"]    = "root";
	environment["REQUEST_METHOD"] = "GET";
	environment["SERVER_NAME"]    = "0.0.0.0";
	environment["SERVER_PORT"]    = "3003";
	environment["HTTP_HOST"]      = "example.com";

	var connection = new VSGI.Test.Connection ();
	var request    = new Request (connection, environment);

	assert (Soup.HTTPVersion.@1_0 == request.http_version);
	assert (environment == request.environment);
	assert ("GET" == request.method);
	assert ("root" == request.uri.get_user ());
	assert ("0.0.0.0" == request.uri.get_host ());
	assert ("a=b" == request.uri.get_query ());
	assert (request.query.contains ("a"));
	assert ("b" == request.query["a"]);
	assert (3003 == request.uri.get_port ());
	assert (null == request.params);
	assert ("example.com" == request.headers.get_one ("Host"));
	assert (connection.input_stream == request.body);
}

/**
 * @since 0.2
 */
public static void test_vsgi_cgi_request_missing_path_info () {
	var environment = new HashTable<string, string> (str_hash, str_equal);
	var connection  = new VSGI.Test.Connection ();
	var request     = new Request (connection, environment);

	assert ("/" == request.uri.get_path ());
}

/**
 * @since 0.2
 */
public void test_vsgi_cgi_request_http_1_1 () {
	var connection  = new VSGI.Test.Connection ();
	var environment = new HashTable<string, string> (str_hash, str_equal);

	environment["SERVER_PROTOCOL"] = "HTTP/1.1";

	var request = new Request (connection, environment);

	assert (Soup.HTTPVersion.@1_1 == request.http_version);
}

/**
 * @since 0.2
 */
public void test_vsgi_cgi_response () {
	var environment = new HashTable<string, string> (str_hash, str_equal);
	var connection  = new VSGI.Test.Connection ();
	var request     = new Request (connection, environment);
	var response    = new Response (request);

	response.headers.replace ("Status", "200 OK");
	assert (200 == response.status);

	response.status = 404;
	assert ("404 Not Found" == response.headers["Status"]);

	response.write_head ();
	assert (response.head_written);
}

