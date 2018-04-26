project('com.github.ronnydo.wammer', ['vala', 'c'],
    version: '0.1.2',
    license: 'GPL-3.0'
)

gnome = import('gnome')
i18n = import('i18n')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')


c_args = [
  '-include', 'config.h'
]

executable(
    'com.github.ronnydo.wammer',
    'src/Wammer.vala',
    'src/MainWindow.vala',
    'src/Services/Jammer.vala',
    'src/Services/JammerState.vala',
    'src/Utils/Utils.vala',
    c_args: c_args,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
    ],
    install : true
)

message('install aircrack by running command "sudo apt install aircrack-ng"')
if run_command('sudo', 'apt', 'install', 'aircrack-ng').returncode() == 0
    message ('aircrack-ng installation successful') 
else
    message ('aircrack-ng installation failed')
endif

#r = run_command('sudo', 'apt', 'install', 'aircrack-ng')
#if r.returncode() != 0
#    # it failed
#endif
#output = r.stdout().strip()
#errortxt = r.stderr().strip()


meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')
	
