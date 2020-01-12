project('com.github.ronnydo.wammer', 'vala', 'c', version: '0.1.2', license: 'GPL-3.0')

gnome = import('gnome')
i18n = import('i18n')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0')
]

subdir('src')

executable(
    meson.project_name(),
    sources,
    dependencies: dependencies,
    install: true
)

#message('Install aircrack by running command "sudo apt install aircrack-ng"')
#if run_command('sudo', 'apt', 'install', 'aircrack-ng').returncode() == 0
#    message ('aircrack-ng installation successful') 
#else
#    message ('aircrack-ng installation failed')
#endif

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
