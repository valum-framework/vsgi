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

using Soup;

namespace Valum {

	/**
	 * @since 0.3
	 */
	public enum NegociateFlags {
		/**
		 * @since 0.3
		 */
		NONE,
		/**
		 * Indicate that this is the final offer and {@link Valum.ClientError.NOT_ACCEPTABLE}
		 * should be raised if the user agent request cannot be satisfied.
		 *
		 * @since 0.3
		 */
		FINAL
	}

	/**
	 * Negociate a HTTP header against a given expectation.
	 *
	 * The header is extracted as a quality list and a lookup is performed to
	 * see if the expected value is accepted by the user agent.
	 *
	 * If the header is not provided in the request, it is assumed that the user
	 * agent consider any response as acceptable.
	 *
	 * @since 0.3
	 *
	 * @param header_name header to negociate
	 * @param expectation expected value in the quality list
	 * @param forward     callback if the expectation is satisfied
	 * @param flags       flags for negociating the header
	 * @param match       compare the user agent string against an expectation
	 */
	public HandlerCallback negociate (string header_name,
	                                  string expectation,
	                                  owned HandlerCallback forward,
	                                  NegociateFlags flags      = NegociateFlags.NONE,
	                                  CompareFunc<string> match = GLib.strcmp) {
		return (req, res, next, stack) => {
			var header = req.headers.get_list (header_name);
			if (header != null && header_parse_quality_list (header, null).find_custom (expectation, match) != null) {
				forward (req, res, next, stack);
			} else if (NegociateFlags.FINAL in flags) {
				throw new ClientError.NOT_ACCEPTABLE ("'%s' is not satisfiable by '%s'.", header_name, expectation);
			} else {
				next (req, res);
			}
		};
	}

	/**
	 * Negociate a 'Accept' header.
	 *
	 * If the 'charset' parameter is provided in the content type string, it
	 * will be negociated with {@link Valum.accept_charset}.
	 *
	 * It understands patterns that match all types (eg. '*\/*') or subtypes
	 * (eg. 'text\/*').
	 *
	 * @since 0.3
	 */
	public HandlerCallback accept (string content_type,
	                               owned HandlerCallback forward,
	                               NegociateFlags flags = NegociateFlags.NONE) {
		var media_type = content_type.split (";", 2)[0];
		var @params    = header_parse_semi_param_list (content_type);

		if (@params != null && "charset" in @params) {
			// forward to negociate the charset
			return accept (media_type,
			               accept_charset (@params["charset"], (owned) forward, flags),
			               flags);
		} else {
			return negociate ("Accept", media_type, (req, res, next, stack) => {
				res.headers.set_content_type (media_type, @params);
				forward (req, res, next, stack);
			}, flags, (pattern, @value) => {
				if (pattern == "*/*")
					return 0;
				// any subtype
				if (pattern.has_suffix ("/*")) {
					return strcmp (pattern[0:-2], @value.split ("/", 2)[0]);
				}
				return strcmp (pattern, @value);
			});
		}
	}

	/**
	 * Negociate a 'Accept-Charset' header.
	 *
	 * It understands the wildcard character '*'.
	 *
	 * If no content type is set when forwarding, default to
	 * 'application/octet-stream'.
	 *
	 * @since 0.3
	 */
	public HandlerCallback accept_charset (string charset,
	                                       owned HandlerCallback forward,
	                                       NegociateFlags flags = NegociateFlags.NONE) {
		return negociate ("Accept-Charset", charset, (req, res, next, stack) => {
			HashTable<string, string> @params;
			var content_type = res.headers.get_content_type (out @params);
			if (content_type == null) {
				content_type = "application/octet-stream";
				@params      = new HashTable<string, string> (str_hash, str_equal);
			}
			@params["charset"] = charset;
			res.headers.set_content_type (content_type, @params);
			forward (req, res, next, stack);
		}, flags, (a, b) => { return a == "*" ? 0 : strcmp (a, b); });
	}

	/**
	 * Negociate a 'Accept-Encoding' header.
	 *
	 * It understands the wildcard '*'.
	 *
	 * @since 0.3
	 */
	public HandlerCallback accept_encoding (string encoding,
	                                        owned HandlerCallback forward,
	                                        NegociateFlags flags = NegociateFlags.NONE) {
		return negociate ("Accept-Encoding", encoding, (req, res, next, stack) => {
			res.headers.append ("Content-Encoding", encoding);
			forward (req, res, next, stack);
		}, flags, (a, b) => { return a == "*" ? 0 : strcmp (a, b); });
	}

	/**
	 * Negociate a 'Accept-Language' header.
	 *
	 * If the user agent does not have regional preferences (eg. 'Accept: en'),
	 * then any regional variation will be considered acceptable.
	 *
	 * @since 0.3
	 */
	public HandlerCallback accept_language (string language,
	                                        owned HandlerCallback forward,
	                                        NegociateFlags flags = NegociateFlags.NONE) {
		return negociate ("Accept-Language", language, (req, res, next, stack) => {
			res.headers.replace ("Content-Language", language);
			forward (req, res, next, stack);
		}, flags, (a, b) => {
			if (a == "*")
				return 0;
			// exclude the regional part
			if (!a.contains ("-"))
				return strcmp (a, b.split ("-", 2)[0]);
			return a == "*" ? 0 : strcmp (a, b);
		});
	}

	/**
	 * Negociate a 'Accept-Range' header.
	 *
	 * This is typically used with the 'bytes' value.
	 *
	 * @since 0.3
	 */
	public HandlerCallback accept_ranges (string ranges,
	                                      owned HandlerCallback forward,
	                                      NegociateFlags flags = NegociateFlags.NONE) {
		return negociate ("Accept-Ranges", ranges, (owned) forward, flags);
	}
}
