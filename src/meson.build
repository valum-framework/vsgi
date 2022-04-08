vsgi_sources = files(
    'vsgi.vala',
    'vsgi-application.vala',
    'vsgi-authentication.vala',
    'vsgi-authorization.vala',
    'vsgi-basic-authentication.vala',
    'vsgi-basic-authorization.vala',
    'vsgi-bounded-input-stream.vala',
    'vsgi-cookie-utils.vala',
    'vsgi-handler-module.vala',
    'vsgi-handler.vala',
    'vsgi-multipart-input-stream.vala',
    'vsgi-multipart-output-stream.vala',
    'vsgi-request.vala',
    'vsgi-response.vala',
    'vsgi-server-module.vala',
    'vsgi-server.vala',
    'vsgi-socket-server.vala',
    'vsgi-tee-output-stream.vala')
vsgi_internal_header = join_paths(meson.current_build_dir(), 'vsgi-@0@-internal.h'.format(api_version))
vsgi_internal_vapi = join_paths(meson.current_build_dir(), 'vsgi-@0@-internal.vapi'.format(api_version))
vsgi_lib = library('vsgi-' + api_version, vsgi_sources,
                   dependencies: [glib, gobject, gio, gio_unix, gmodule, soup, openssl, posix],
                   vala_header: 'vsgi.h',
                   vala_gir: 'VSGI-@0@.gir'.format(api_version),
                   build_rpath: join_paths(meson.current_build_dir(), 'servers'),
                   vala_args: ['--internal-header', vsgi_internal_header,
                               '--internal-vapi', vsgi_internal_vapi],
                   link_args: ['-Wl,--disable-new-dtags'],
                   install: true,
                   install_dir: [true, 'include/vsgi-' + api_version, true, true],
                   install_rpath: join_paths(get_option('prefix'), get_option('libdir'), 'vsgi-@0@/servers'.format(api_version)))

install_data('vsgi-@0@.deps'.format(api_version),
             install_dir: 'share/vala/vapi')

vsgi_dep = declare_dependency(include_directories: include_directories('.'),
                              link_with: vsgi_lib)

if get_option('with_introspection')
    g_ir_compiler = find_program('g-ir-compiler')
    custom_target('VSGI typelib',
                  command: [g_ir_compiler, '--shared-library', vsgi_lib.full_path(), '--output', '@OUTPUT@', join_paths(meson.current_build_dir(), 'VSGI-@0@.gir'.format(api_version))],
                  output: 'VSGI-@0@.typelib'.format(api_version),
                  depends: vsgi_lib,
                  install: true,
                  install_dir: join_paths(get_option('libdir'), 'girepository-1.0'))
endif

pkgconfig = import('pkgconfig')
pkgconfig.generate(vsgi_lib,
                   version: meson.project_version(),
                   name: 'VSGI',
                   filebase: 'vsgi-' + api_version,
                   description: 'Interface and implementations for various web server technologies',
                   subdirs: 'vsgi-' + api_version)

subdir('servers')
