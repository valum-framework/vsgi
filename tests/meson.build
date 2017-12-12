# VSGI tests
vsgi_tests = [
    'application',
    'auth',
    'http-server',
    'multipart',
    'request',
    'response',
    'server',
    'socket-server']

foreach name : vsgi_tests
    test(name, executable(name + '-test', name + '-test.vala',
                          dependencies: [glib, gobject, gio, gio_unix, soup, vsgi]),
         env: ['G_TEST_SRCDIR=' + meson.current_source_dir()])
endforeach

if fcgi.found()
    test('fastcgi server', executable('fastcgi-server-test', 'fastcgi-server-test.vala',
                                      dependencies: [glib, gobject, gio, gio_unix, soup, vsgi]))
endif

loader_test_lib = shared_library('loader-test', 'loader-test.vala',
                                 dependencies: [glib, gobject, gio, gio_unix, soup, vsgi])
test('loader', vsgi_loader,
     args: ['--directory', meson.current_build_dir(), '--server=cgi', 'loader-test'],
     env: ['VSGI_SERVER_PATH=src/vsgi/servers'])

python = find_program('python3')
if g_ir_compiler.found()
    test('gi', python,
         args: meson.current_source_dir() + '/gi-test.py' ,
         env: ['GI_TYPELIB_PATH=' + join_paths(meson.current_build_dir(), '../src/vsgi')])
 endif
