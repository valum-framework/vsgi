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

#include "vsgi-fastcgi-output-stream.h"

typedef struct
{
	FCGX_Stream *out;
	FCGX_Stream *err;
} VSGIFastCGIOutputStreamPrivate;

struct _VSGIFastCGIOutputStream
{
	GUnixOutputStream               parent_instance;
	VSGIFastCGIOutputStreamPrivate *priv;
};

G_DEFINE_TYPE_WITH_PRIVATE (VSGIFastCGIOutputStream,
                            vsgi_fastcgi_output_stream,
                            G_TYPE_UNIX_OUTPUT_STREAM)

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
vsgi_fastcgi_output_stream_real_write (GOutputStream  *self,
                                       const void     *buffer,
                                       gsize           count,
                                       GCancellable   *cancellable,
                                       GError        **error)
{
	FCGX_Stream *out_stream;
	gint err;
	gint ret;

	g_return_val_if_fail (VSGI_FASTCGI_IS_OUTPUT_STREAM (self), -1);

	out_stream = VSGI_FASTCGI_OUTPUT_STREAM (self)->priv->out;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return -1;
	}

	ret = FCGX_PutStr (buffer, count, out_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (out_stream);

		g_set_error (error,
		             G_IO_ERROR,
		             g_io_error_from_errno (err),
		             vsgi_fastcgi_strerror (err));

		FCGX_ClearError (out_stream);

		return -1;
	}

	return ret;
}

static gboolean
vsgi_fastcgi_output_stream_real_flush (GOutputStream  *self,
                                       GCancellable   *cancellable,
                                       GError        **error)
{
	FCGX_Stream *out_stream;
	gint ret;
	gint err;

	g_return_val_if_fail (VSGI_FASTCGI_IS_OUTPUT_STREAM (self), FALSE);

	out_stream = VSGI_FASTCGI_OUTPUT_STREAM (self)->priv->out;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return FALSE;
	}

	ret = FCGX_FFlush (out_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (out_stream);

		g_set_error (error,
		             G_IO_ERROR,
		             g_io_error_from_errno (err),
		             vsgi_fastcgi_strerror (err));

		FCGX_ClearError (out_stream);

		return FALSE;
	}

	return TRUE;
}

static gboolean
vsgi_fastcgi_output_stream_real_close (GOutputStream  *self,
                                       GCancellable   *cancellable,
                                       GError        **error)
{
	FCGX_Stream *err_stream;
	FCGX_Stream *out_stream;
	gint ret;
	gint err;

	g_return_val_if_fail (VSGI_FASTCGI_IS_OUTPUT_STREAM (self), FALSE);

	out_stream = VSGI_FASTCGI_OUTPUT_STREAM (self)->priv->out;
	err_stream = VSGI_FASTCGI_OUTPUT_STREAM (self)->priv->err;

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return FALSE;
	}

	/* always close the error stream first */

	ret = FCGX_FClose (err_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (err_stream);

		/* only emit a critical as we can still recover after */
		g_critical ("%s (%s, %d)", vsgi_fastcgi_strerror (err),
		                           g_quark_to_string (G_IO_ERROR),
		                           g_io_error_from_errno (err));

		FCGX_ClearError (err_stream);
	}

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
	{
		return FALSE;
	}

	ret = FCGX_FClose (out_stream);

	if (G_UNLIKELY (ret == -1))
	{
		err = FCGX_GetError (out_stream);

		g_set_error (error,
		             G_IO_ERROR,
		             g_io_error_from_errno (err),
		             vsgi_fastcgi_strerror (err));

		FCGX_ClearError (out_stream);

		return FALSE;
	}

	return out_stream->isClosed;
}

static void
vsgi_fastcgi_output_stream_init (VSGIFastCGIOutputStream *self)
{
	self->priv = vsgi_fastcgi_output_stream_get_instance_private (self);
}

static void
vsgi_fastcgi_output_stream_class_init (VSGIFastCGIOutputStreamClass *klass)
{
	klass->parent_class.parent_class.write_fn = vsgi_fastcgi_output_stream_real_write;
	klass->parent_class.parent_class.flush    = vsgi_fastcgi_output_stream_real_flush;
	klass->parent_class.parent_class.close_fn = vsgi_fastcgi_output_stream_real_close;
}

VSGIFastCGIOutputStream*
vsgi_fastcgi_output_stream_new (gint fd, FCGX_Stream* out, FCGX_Stream* err)
{
	VSGIFastCGIOutputStream *self;

	self = g_object_new (VSGI_FASTCGI_TYPE_OUTPUT_STREAM, "fd", fd, NULL);

	self->priv->out = out;
	self->priv->err = err;

	return self;
}
