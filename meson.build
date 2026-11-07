project('vsgi', 'vala', 'c',
        version: '0.4.0-dev',
        license: 'LGPL',
        meson_version: '>=1.11')

api_version = '0.4'

add_project_arguments(['--enable-experimental',
                       '--target-glib=2.80',
                       '--vapidir', meson.current_source_dir() / 'vapi'],
                      language: 'vala')

glib = dependency('glib-2.0', version: '>=2.80')
gobject = dependency('gobject-2.0', version: '>=2.80')
gio = dependency('gio-2.0', version: '>=2.80')
gio_unix = dependency('gio-unix-2.0', version: '>=2.80')
gmodule = dependency('gmodule-2.0', version: '>=2.80')
soup = dependency('libsoup-2.4', version: '>=2.74')
openssl = dependency('openssl')
posix = meson.get_compiler('vala').find_library('posix')

if meson.get_compiler('c').has_function('memmem')
    add_project_arguments('--define=HAVE_MEMMEM', language: 'vala')
endif

subdir('src')
subdir('bin')
subdir('tests')
