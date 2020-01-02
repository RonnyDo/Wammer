sudo rm -r build
meson build
cd build
meson --reconfigure -Dprefix=/usr
ninja

# Building language potfiles in /po directory
#ninja com.github.ronnydo.wammer-pot
#ninja com.github.ronnydo.wammer-update-po

# Is this necessary to install al languages?
#sudo ninja install

G_MESSAGES_DEBUG=all ./com.github.ronnydo.wammer
cd ..
