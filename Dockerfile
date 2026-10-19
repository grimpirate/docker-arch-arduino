FROM ghcr.io/linuxserver/baseimage-selkies:arch

ENV TITLE="Grim Arch X11 Docker"
ENV PIXELFLUX_WAYLAND=false
ENV TZ=America/New_York
ENV PUID=1000
ENV PGID=1000

# Update system and install xterm
RUN pacman -Sy --noconfirm && \
    pacman -S --noconfirm nano git wget arduino-cli python unzip tk && \
    pacman -Scc --noconfirm

WORKDIR /config

RUN git clone --depth 1 https://github.com/MrBlinky/Arduboy-Python-Utilities
RUN git clone --depth 1 https://git.suckless.org/dwm
RUN git clone --depth 1 https://git.suckless.org/dmenu
RUN git clone --depth 1 https://git.suckless.org/slstatus

RUN sed -i 's|const unsigned int interval = 1000|const unsigned int interval = 60000|g' slstatus/config.def.h && \
    sed -i 's|{ d|{ run_command, "", "sleep 10; /config/svgwall/scripts/update.sh" },\n//{ d|g' slstatus/config.def.h

RUN make -C /config/dwm clean install
RUN make -C /config/dmenu clean install
RUN make -C /config/slstatus clean install

RUN rm -rf dwm/ dmenu/ slstatus/

RUN git clone --depth 1 https://github.com/grimpirate/svgwall

WORKDIR /config/svgwall

RUN wget https://github.com/grimpirate/SVGWall/releases/download/v20251126.1/SVGWall-x86_64.AppImage

RUN chmod -R 0755 build.sh SVGWall-x86_64.AppImage scripts/ && \
    sed -i 's|-j|--appimage-extract-and-run -j|g' scripts/update.sh && \
    rm -rf assets/ build.sh LICENSE README.md screenshot.png src_c/ src_java/

WORKDIR /defaults

RUN sed -i 's|/usr/bin/openbox-session|/usr/local/bin/dwm|g' startwm.sh && \
    sed -i 's|then|then\n  slstatus \&|g' startwm.sh && \
    sed -i 's|else|else\n  slstatus \&|g' startwm.sh && \
    rm autostart_wayland labwc.xml menu_wayland.xml startwm_wayland.sh menu.xml autostart

RUN pacman -Rns openbox --noconfirm

RUN arduino-cli config init
RUN arduino-cli config add board_manager.additional_urls https://raw.githubusercontent.com/MrBlinky/Arduboy-homemade-package/main/package_arduboy_homemade_index.json
RUN arduino-cli core update-index
RUN arduino-cli core install arduino:avr
RUN arduino-cli core install arduboy-homemade:avr
RUN arduino-cli config set library.enable_unsafe_install true
RUN arduino-cli lib install --git-url https://github.com/MLXXXp/Arduboy2
RUN arduino-cli lib install Keyboard
RUN python -m pip install pyserial pillow
# arduino-cli compile -b "arduboy-homemade:avr:arduboy-fx:core=arduboy-core" sketch/ --output-dir sketch/

EXPOSE 3000
EXPOSE 3001
VOLUME /config

# docker build -t arch-selkies .
# docker run -d --shm-size=1gb -e PIXELFLUX_WAYLAND=false -e PUID=1000 -e PGID=1000 -p 3000:3000 -p 3001:3001 arch-selkies
# docker run -d --shm-size=1gb -e PIXELFLUX_WAYLAND=false -e PUID=1000 -e PGID=1000 -p 3000:3000 -p 3001:3001 ghcr.io/linuxserver/baseimage-selkies:arch
