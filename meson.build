project(
    'vsgi',
    'vala',
    'c',
    version: '0.4.0-dev',
    license: 'LGPL',
    meson_version: '>=1.3',
)

api_version = '0.4'

min_glib_version = '2.80'

add_project_arguments(
    [
        '--enable-experimental',
        '--target-glib=' + min_glib_version,
        '--vapidir',
        meson.current_source_dir() / 'vapi',
    ],
    language: 'vala',
)

add_project_arguments(
    [
        '-Wno-discarded-qualifiers',
        '-Wno-unused-but-set-variable',
        '-Wno-unused-function',
        '-Wno-unused-label',
        '-Wno-unused-variable',
    ],
    language: 'c',
)

glib_dep = dependency('glib-2.0', version: '>=' + min_glib_version)
gobject_dep = dependency('gobject-2.0', version: '>=' + min_glib_version)
gio_dep = dependency('gio-2.0', version: '>=' + min_glib_version)
gio_unix_dep = dependency('gio-unix-2.0', version: '>=' + min_glib_version)
gmodule_dep = dependency('gmodule-2.0', version: '>=' + min_glib_version)
soup_dep = dependency('libsoup-2.4', version: '>=2.74')
openssl_dep = dependency('openssl')
posix_dep = meson.get_compiler('vala').find_library('posix')

if meson.get_compiler('c').has_function('memmem')
    add_project_arguments('--define=HAVE_MEMMEM', language: 'vala')
endif

subdir('src')
subdir('bin')
subdir('tests')
