project('vsgi', 'vala', 'c',
        version: '0.4.0-dev',
        license: 'LGPL',
        meson_version: '>=0.46.0')

api_version = '0.4'

add_project_arguments(['--enable-experimental',
                       '--enable-deprecated',
                       '--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

glib = dependency('glib-2.0', version: '>=2.56')
gobject = dependency('gobject-2.0', version: '>=2.56')
gio = dependency('gio-2.0', version: '>=2.56')
gio_unix = dependency('gio-unix-2.0', version: '>=2.56')
gmodule = dependency('gmodule-2.0', version: '>=2.40')
soup = dependency('libsoup-2.4', version: '>=2.62')
openssl = dependency('openssl')
posix = meson.get_compiler('vala').find_library('posix')

if meson.get_compiler('c').has_function('memmem')
    add_project_arguments('--define=HAVE_MEMMEM', language: 'vala')
endif

subdir('src')
subdir('bin')
subdir('tests')
