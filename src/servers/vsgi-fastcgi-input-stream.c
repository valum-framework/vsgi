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

#include "vsgi-fastcgi-input-stream.h"

typedef struct
{
	FCGX_Stream *in;
} VSGIFastCGIInputStreamPrivate;

struct _VSGIFastCGIInputStream
{
	GUnixInputStream               parent_instance;
	VSGIFastCGIInputStreamPrivate *priv;
};

G_DEFINE_TYPE_WITH_PRIVATE (VSGIFastCGIInputStream,
                            vsgi_fastcgi_input_stream,
                            G_TYPE_UNIX_INPUT_STREAM)

static const gchar *
vsgi_fastcgi_strerror (int err)
{
	if (err > 0)
	{
		return g_strerror (err);
	}
	else
	{
		switch (err)
		{
			case FCGX_CALL_SEQ_ERROR:
				return "FCXG: Call seq error";
			case FCGX_PARAMS_ERROR:
				return "FCGX: Params error";
			case FCGX_PROTOCOL_ERROR:
				return "FCGX: Protocol error";
			case FCGX_UNSUPPORTED_VERSION:
				return "FCGX: Unsupported version";
			default:
				g_assert_not_reached ();
		}
	}
}

static gssize
vsgi_fastcgi_input_stream_real_read (GInputStream  *self,
                                     void          *buffer,
                                     gsize          count,
                                     GCancellable  *cancellable,
                                     GError       **error)
{
	FCGX_Stream *in_stream;
	gint ret;
	gint err;

	g_return_val_if_fail (VSGI_FASTCGI_IS_INPUT_STREAM (self), -1);

	in_stream = VSGI_FASTCGI_INPUT_STREAM (self)->priv->in;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return -1;
	}

	ret = FCGX_GetStr (buffer, count, in_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (in_stream);

		g_set_error (error,
		             G_IO_ERROR,
		             g_io_error_from_errno (err),
		             vsgi_fastcgi_strerror (err));

		FCGX_ClearError (in_stream);

		return -1;
	}

	return ret;
}

static gboolean
vsgi_fastcgi_input_stream_real_close (GInputStream  *self,
                                      GCancellable  *cancellable,
                                      GError       **error)
{
	FCGX_Stream *in_stream;
	gint ret;
	gint err;

	g_return_val_if_fail (VSGI_FASTCGI_IS_INPUT_STREAM (self), FALSE);

	in_stream = VSGI_FASTCGI_INPUT_STREAM (self)->priv->in;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return FALSE;
	}

	ret = FCGX_FClose (in_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (in_stream);

		g_set_error (error,
		             G_IO_ERROR,
		             g_io_error_from_errno (err),
		             vsgi_fastcgi_strerror (err));

		FCGX_ClearError (in_stream);

		return FALSE;
	}

    return in_stream->isClosed;
}

static void
vsgi_fastcgi_input_stream_init (VSGIFastCGIInputStream *self)
{
	self->priv = vsgi_fastcgi_input_stream_get_instance_private (self);
}

static void
vsgi_fastcgi_input_stream_class_init (VSGIFastCGIInputStreamClass *klass)
{
	klass->parent_class.parent_class.read_fn = vsgi_fastcgi_input_stream_real_read;
	klass->parent_class.parent_class.close_fn = vsgi_fastcgi_input_stream_real_close;
}

VSGIFastCGIInputStream*
vsgi_fastcgi_input_stream_new (gint fd, FCGX_Stream* in)
{
	VSGIFastCGIInputStream *self;

	self = g_object_new (VSGI_FASTCGI_TYPE_INPUT_STREAM, "fd", fd, NULL);

	self->priv->in = in;

	return self;
}
