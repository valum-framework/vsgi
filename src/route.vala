using Gee;

namespace Valum {

	/**
	 * Route that matches Request path.
	 */
	public class Route : Object {

		/**
		 * Router that declared this route.
		 */
		private weak Router router;

		/**
		 * Regular expression matching the Request path.
		 */
		private Regex regex;

		/**
		 * Remembers what names have been defined in the regular expression to
		 * build the Request params Map.
		 */
		private Gee.List<string> captures;

		private unowned RequestCallback callback;

		public delegate void RequestCallback(Request req, Response res);

		/**
		 * Create a Route for a given callback using a Regex.
		 */
		public Route (Router router, Regex regex, Gee.List<string> captures, RequestCallback callback) {
			this.router   = router;
			this.regex    = regex;
			this.captures = captures;
			this.callback = callback;
		}

		/**
		 * Create a Route for a given callback from a rule.
         *
		 * A rule will compile down to Regex.
		 */
		public Route.from_rule (Router router, string rule, RequestCallback callback) {
			this.router   = router;
			this.captures = new ArrayList<string> ();
			this.callback = callback;
			try {
				Regex param_regex = new Regex("(<(?:\\w+:)?\\w+>)");
				var params = param_regex.split_full(rule);

				StringBuilder route = new StringBuilder("^");

				foreach (var p in params) {
					if(p[0] != '<') {
						// regular piece of route
						route.append (Regex.escape_string(p));
					} else {
						// extract parameter
						var cap  = p.slice(1, p.length - 1).split(":", 2);
						var type = cap.length == 1 ? "string" : cap[0];
						var key = cap.length == 1 ? cap[0] : cap[1];

						// TODO: support any type with a HashMap<string, string>
						var types = new HashMap<string, string> ();

						captures.add (key);
						route.append ("(?<%s>%s)".printf (key, this.router.types[type]));
					}
				}

				route.append("$");
				message("registered %s", route.str);

				this.regex = new Regex (route.str, RegexCompileFlags.OPTIMIZE);
			} catch(RegexError e) {
				error (e.message);
			}
		}

		public bool matches (string path) {
			return this.regex.match (path, 0);
		}

		public void fire (Request req, Response res) {
			MatchInfo matchinfo;
			// initialize Request parameters
			if (this.regex.match (req.path, 0, out matchinfo)) {
				foreach (var cap in captures) {
					req.params[cap] = matchinfo.fetch_named (cap);
				}
			}
			this.callback (req, res);
		}
	}
}
