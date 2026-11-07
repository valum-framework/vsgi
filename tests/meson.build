# VSGI tests
vsgi_tests = [
    'application',
    'auth',
    'cgi',
    'cookies',
    'http-server',
    'multipart',
    'request',
    'response',
    'server',
    'socket-server']

foreach name : vsgi_tests
    test(name, executable(name + '-test', name + '-test.vala',
                          dependencies: [glib_dep, gobject_dep, gio_dep, gio_unix_dep, soup_dep, vsgi_dep]),
         env: ['G_TEST_SRCDIR=' + meson.current_source_dir()])
endforeach

if get_option('with_fcgi')
    test('fastcgi server', executable('fastcgi-server-test', 'fastcgi-server-test.vala',
                                      dependencies: [glib_dep, gobject_dep, gio_dep, gio_unix_dep, soup_dep, vsgi_dep]))
endif

loader_test_lib = shared_library('loader-test', 'loader-test.vala',
                                 dependencies: [glib_dep, gobject_dep, gio_dep, gio_unix_dep, soup_dep, vsgi_dep])
test('loader', vsgi_loader,
     args: ['--directory', meson.current_build_dir(), '--server=cgi', 'loader-test'],
     env: ['VSGI_SERVER_PATH=' + join_paths(meson.current_build_dir(), '../src/servers')])

python = find_program('python3')
if get_option('with_introspection')
    test('gi', python,
         args: meson.current_source_dir() + '/gi-test.py' ,
         env: ['GI_TYPELIB_PATH=' + join_paths(meson.current_build_dir(), '../src'),
               'VSGI_SERVER_PATH=' + join_paths(meson.current_build_dir(), '../src/servers')])
endif
