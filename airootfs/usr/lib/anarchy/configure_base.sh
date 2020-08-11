#!/usr/bin/env bash
###############################################################
### Anarchy Linux Install Script
### configure_base.sh
###
### Copyright (C) 2017 Dylan Schacht
###
### By: Dylan Schacht (deadhead)
### Email: deadhead3492@gmail.com
### Webpage: https://anarchylinux.org
###
### Any questions, comments, or bug reports may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v2.0
###############################################################

install_options() {

    op_title="$install_op_msg"
        while (true) ; do
                 install_opt=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$install_opt_msg" 16 80 5 \
                         "Anarchy-Desktop"       "$install_opt1" \
                         "Anarchy-Desktop-LTS"   "$install_opt2" \
                         "Anarchy-Server"        "$install_opt3" \
                         "Anarchy-Server-LTS"    "$install_opt4" \
             "Anarchy-Advanced"      "$install_opt0" 3>&1 1>&2 2>&3)
                 if [ "$?" -gt "0" ]; then
                          if (yesno "\n${exit_msg}" "${yes}" "${no}" 1) then
                                  main_menu
                          fi
                 else
                          break
                 fi
         done

         case "$install_opt" in
                 Anarchy-Advanced)       prepare_base
                                         graphics
                 ;;
                 *)                      quick_install
                 ;;
         esac

}

prepare_base() {

    op_title="$install_op_msg"
    while (true)
      do
        install_menu=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$install_type_msg" 17 69 8 \
            "Arch-Linux-Base" 		"$base_msg0" \
            "Arch-Linux-Base-Devel" 	"$base_msg1" \
            "Arch-Linux-Hardened"		"$hardened_msg0" \
            "Arch-Linux-Hardened-Devel"	"$hardened_msg1" \
            "Arch-Linux-LTS-Base" 		"$LTS_msg0" \
            "Arch-Linux-LTS-Base-Devel"	"$LTS_msg1" \
            "Arch-Linux-Zen"		"$zen_msg0" \
            "Arch-Linux-Zen-Devel"		"$zen_msg1" 3>&1 1>&2 2>&3)
        if [ "$?" -gt "0" ]; then
            if (yesno "\n${exit_msg}" "${yes}" "${no}" 1) then
                main_menu
            fi
        else
            break
        fi
    done

    case "$install_menu" in
        "Arch-Linux-Base")
            base_install="base linux linux-headers $base_defaults " kernel="linux"
        ;;
        "Arch-Linux-Base-Devel")
            base_install="base-devel linux linux-headers $base_defaults " kernel="linux"
        ;;
        "Arch-Linux-Hardened")
            base_install="base linux-hardened linux-hardened-headers $base_defaults " kernel="linux-hardened"
        ;;
        "Arch-Linux-Hardened-Devel")
            base_install="base-devel linux-hardened linux-hardened-headers linux-firmware $base_defaults " kernel="linux-hardened"
        ;;
        "Arch-Linux-LTS-Base")
            base_install="base linux-lts linux-lts-headers $base_defaults " kernel="linux-lts"
        ;;
        "Arch-Linux-LTS-Base-Devel")
            base_install="base-devel linux-lts linux-lts-headers $base_defaults " kernel="linux-lts"
        ;;
        "Arch-Linux-Zen")
            base_install="base linux-zen linux-zen-headers $base_defaults " kernel="linux-zen"
        ;;
        "Arch-Linux-Zen-Devel")
            base_install="base-devel linux-zen linux-zen-headers $base_defaults " kernel="linux-zen"
        ;;
    esac

    while (true)
      do
        shell=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$shell_msg" 16 64 6 \
            "bash"  "$shell5" \
            "dash"	"$shell0" \
            "fish"	"$shell1" \
            "mksh"	"$shell2" \
            "tcsh"	"$shell3" \
            "zsh"	"$shell4" 3>&1 1>&2 2>&3)
        if [ "$?" -gt "0" ]; then
            if (yesno "\n${exit_msg}" "${yes}" "${no}" 1) then
                main_menu
            fi
        else
            case "$shell" in
                bash) sh="/bin/bash" shell="bash-completion"
                ;;
                fish) 	sh="/bin/bash"
                ;;
                zsh) 	shrc=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "\n$shrc_msg" 13 65 4 \
                                "$default"		"$shrc_msg1" \
                                "grml-zsh-config"	"$shrc_msg4" \
                                "$none"			"$shrc_msg3" 3>&1 1>&2 2>&3)
                                if [ "$?" -gt "0" ]; then
                                    shrc="$default"
                                fi

                                sh="/usr/bin/$shell" shell="zsh zsh-syntax-highlighting"

                                if [ "$shrc" == "grml-zsh-config" ]; then
                                    shell+=" grml-zsh-config zsh-completions"
                                fi
                ;;
                *) sh="/bin/$shell"
                ;;
            esac

            base_install+="$shell "
            break
        fi
    done

    #
    # Bootloader selection
    #
    base_install+="${UCODE} "
    while (true)
      do
        if "$UEFI" ; then
            bootloader=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$loader_type_msg" 13 64 4 \
                "grub"			"${loader_msg}"    \
                "syslinux"		"${loader_msg1}"   \
                "systemd-boot"	"${loader_msg2}"   \
                "efistub"	    "${loader_msg3}"   \
                "refind"        "${loader_msg4}"   \
                "${none}" "-" 3>&1 1>&2 2>&3)
            ex="$?"
        else
            bootloader=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$loader_type_msg" 12 64 3 \
                "grub"			"$loader_msg" \
                "syslinux"		"$loader_msg1" \
                "$none" "-" 3>&1 1>&2 2>&3)
            ex="$?"
        fi

        if [ "$ex" -gt "0" ]; then
            if (yesno "\n${exit_msg}" "${yes}" "${no}" 1) then
                main_menu
            fi
        elif [ "$bootloader" == "systemd-boot" ]; then
            break
        elif [ "$bootloader" == "efistub" ]; then
            break
        elif [ "${bootloader}" == "refind" ]; then
            base_install+="refind "
            break
        elif [ "$bootloader" == "syslinux" ]; then
            if ! "$UEFI" ; then
                if (tune2fs -l /dev/"$BOOT" | grep "64bit" &> /dev/null); then
                    if (yesno "\n${syslinux_warn_msg}" "${yes}" "${no}") then
                        mnt=$(df | grep -w "$BOOT" | awk '{print $6}')
                        (umount "$mnt"
                        wipefs -a /dev/"$BOOT"
                        mkfs.ext4 -O \^64bit /dev/"$BOOT"
                        mount /dev/"$BOOT" "$mnt") &> /dev/null &
                        pid=$! pri=0.1 msg="\n$boot_load \n\n \Z1> \Z2mkfs.ext4 -O ^64bit /dev/$BOOT\Zn" load
                        base_install+="$bootloader "
                        break
                    fi
                else
                    base_install+="$bootloader "
                    break
                fi
            else
                base_install+="$bootloader "
                break
            fi
        elif [ "$bootloader" == "grub" ]; then
            base_install+="$bootloader "
            break
        else
            if (yesno "\n${grub_warn_msg0}" "${yes}" "${no}" 1) then
                msg "\n${grub_warn_msg1}"
                break
            fi
        fi
    done

    while (true)
      do
        net_util=$(dialog --ok-button "$ok" --cancel-button "$cancel" --menu "$wifi_util_msg" 13 64 3 \
            "networkmanager" 		"$net_util_msg1" \
            "netctl"			"$net_util_msg0" \
            "$none" "-" 3>&1 1>&2 2>&3)

        if [ "$?" -gt "0" ]; then
            if (yesno "\n${exit_msg}" "${yes}" "${no}" 1) then
                main_menu
            fi
        else
            if [ "$net_util" == "netctl" ] || [ "$net_util" == "networkmanager" ]; then
                base_install+="$net_util dialog " enable_nm=true
            fi
            break
        fi
    done

    if (yesno "\n\n${multilib_msg}" "${yes}" "${no}") then
        multilib=true
        echo "$(date -u "+%F %H:%M") : Include multilib" >> "$log"
    fi

    if (yesno "\n\n${dhcp_msg}" "${yes}" "${no}") then
        dhcp=true
        echo "$(date -u "+%F %H:%M") : Enable dhcp" >> "$log"
    fi

    if "$wifi" ; then
        base_install+="wireless_tools wpa_supplicant "
    else
        if (yesno "\n${wifi_option_msg}" "${yes}" "${no}" 1) then
            base_install+="wireless_tools wpa_supplicant "
        fi
    fi

    if "$bluetooth" ; then
        if (yesno "\n${bluetooth_msg}" "${yes}" "${no}" 1) then
            base_install+="bluez bluez-utils pulseaudio-bluetooth "
            enable_bt=true
        fi
    fi

    if (yesno "\n${pppoe_msg}" "${yes}" "${no}" 1) then
        base_install+="rp-pppoe "
    fi

    if (yesno "\n${os_prober_msg}" "${yes}" "${no}" 1) then
        base_install+="os-prober "
    fi

    if "$enable_f2fs" ; then
        base_install+="f2fs-tools "
    fi

    if "$UEFI" ; then
        base_install+="efibootmgr "
    fi

}

add_software() {

    op_title="$software_op_msg"
    if (yesno "\n${software_msg0}" "${yes}" "${no}") then

        while (true)
          do
            unset software
            add_soft=true
            if ! "$skip" ; then
                software_menu=$(dialog --extra-button --extra-label "$install" --ok-button "$select" --cancel-button "$cancel" --menu "$software_type_msg" 21 63 12 \
                    "$audio"	   "$audio_msg" \
                    "$database"	   "$database_msg" \
                    "$fonts"	   "$fonts_msg" \
                    "$games"	   "$games_msg" \
                    "$graphic"	   "$graphic_msg" \
                    "$internet"	   "$internet_msg" \
                    "$multimedia"  "$multimedia_msg" \
                    "$office"	   "$office_msg" \
                    "$programming" "$program_msg" \
                    "$terminal"	   "$terminal_msg" \
                    "$text_editor" "$text_editor_msg" \
                    "$servers"	   "$servers_msg" \
                    "$util"		   "$util_msg" \
                    "$extra_de"    "$extra_de_msg"  \
                    "$extra_wm"    "$extra_wm_msg"  \
                    "$done_msg"	"$install \Z2============>\Zn" 3>&1 1>&2 2>&3)
                ex="$?"

                if [ "$ex" -eq "1" ]; then
                    if (yesno "\n${software_warn_msg}" "${yes}" "${no}" 1) then
                        break
                    else
                        add_soft=false
                    fi
                elif [ "$ex" -eq "3" ]; then
                    software_menu="$done_msg"
                fi
            else
                skip=false
            fi

            case "$software_menu" in
                "$audio")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "audacity"		"$audio0" OFF \
                        "audacious"		"$audio1" OFF \
                        "clementine"		"$audio10" OFF \
                        "cmus"			"$audio2" OFF \
                        "jack2"			"$audio3" OFF \
                        "projectm"		"$audio4" OFF \
                        "lmms"			"$audio5" OFF \
                        "mpd"			"$audio6" OFF \
                        "ncmpcpp"		"$audio7" OFF \
                        "pianobar"		"$audio9" OFF \
                        "pavucontrol"		"$audio8" OFF \
                        "pulseaudio-equalizer"	"$audio11" OFF \
                        "qmmp"			"$audio13" OFF \
                        "rhythmbox"		"$audio14" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$database")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "couchdb"		"$db0" OFF \
                        "mariadb"		"$sys30" OFF \
                        "percona-server"	"$db2" OFF \
                        "phpmyadmin"		"$sys32" OFF \
                        "php-sqlite"		"$db3" OFF \
                        "postgresql"		"$sys31" OFF \
                        "redis"			"$db4" OFF \
                        "sqlite"		"$db6" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$internet")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "chromium"			"$net0" OFF \
                        "elinks"			"$net3" OFF \
                        "filezilla"			"$net1" OFF \
                        "firefox"			"$net2" OFF \
                        "irssi"				"$net9" OFF \
                        "lynx"				"$net3" OFF \
                        "midori"			"$net12" OFF \
                        "minitube"			"$net4" OFF \
                        "opera"				"$net5" OFF \
                        "thunderbird"			"$net6" OFF \
                        "transmission-cli" 		"$net7" OFF \
                        "transmission-gtk"		"$net8" OFF \
                        "hexchat"			"$net11" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (<<<"$software" grep "firefox" &>/dev/null) && [ -n "$bro" ]; then
                        software+=" firefox-i18n-$bro"
                    fi

                    if (<<<"$software" grep "thunderbird" &>/dev/null) && [ -n "$bro" ] && [ "$bro" != "lv" ]; then
                            software+=" thunderbird-i18n-$bro"
                    fi
                ;;
                "$fonts")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "bdf-unifont"		"$font0" OFF \
                        "noto-fonts-cjk"	"$font1" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$games")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 70 10 \
                        "aisleriot"	"$game11" OFF \
                        "bsd-games"	"$game1" OFF \
                        "bzflag"	"$game2" OFF \
                        "gnuchess"      "$game4" OFF \
                        "steam"		"$game10" OFF \
                        "supertux"	"$game5" OFF \
                        "supertuxkart"	"$game6" OFF \
                        "warsow"	"$game8" OFF \
                        "xonotic"	"$game9" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (<<<"$software" grep "steam" &>/dev/null); then
                        while (true)
                          do
                            if ! "$multilib" ; then
                                if (yesno "\n${steam_add_msg}" "${yes}" "${no}") then
                                    multilib=true
                                else
                                    software=$(<<<"$software" sed 's/steam//')
                                    break
                                fi
                            else
                                software+=" steam-native-runtime ttf-liberation"
                                cat /etc/pacman.conf | sed -e "/\[multilib\]/,/Include/"'s/^#//' | cat > /etc/pacman.conf.bak
                                cp /etc/pacman.conf.bak /etc/pacman.conf

                                if (<<<"$GPU" grep "nvidia" &>/dev/null); then
                                    software+=" lib32-nvidia-utils"
                                fi
                                break
                            fi
                        done
                    fi
                ;;
                "$graphic")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "blender"		"$graphic0" OFF \
                        "darktable"		"$graphic1" OFF \
                        "feh"			"$graphic6" OFF \
                        "gimp"			"$graphic2" OFF \
                        "graphicsmagick"	"$graphic8" OFF \
                        "graphviz"		"$graphic3" OFF \
                        "imagemagick"		"$graphic4" OFF \
                        "inkscape"		"$graphic9" OFF \
                        "mtpaint"		"$graphic10" OFF \
                        "mypaint"		"$graphic11" OFF \
                        "pinta"			"$graphic5" OFF \
                        "rawtherapee"		"$graphic7" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$multimedia")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "byzanz"				"$media10" OFF \
                        "handbrake"				"$media0" OFF \
                        "kdenlive"				"$media9" OFF \
                        "mplayer"				"$media1" OFF \
                        "mpv"					"$media7" OFF \
                        "multimedia-codecs"			"$media8" OFF \
                        "pitivi"				"$media2" OFF \
                        "simplescreenrecorder"			"$media3" OFF \
                        "smplayer"				"$media4" OFF \
                        "snappy-player"				"$media11" OFF \
                        "totem"					"$media5" OFF \
                        "vlc"         	   			"$media6" OFF \
                        "youtube-dl" "$media12" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                    if (<<<"$software" grep "vlc") then
                        software+=" qt5 phonon-qt5-vlc"
                    fi
                    if (<<<"$software" grep "multimedia-codecs") then
                        software=$(<<<"$software" sed 's/multimedia-codecs/gst-plugins-bad gst-plugins-base gst-plugins-good gst-plugins-ugly ffmpegthumbnailer gst-libav/')
                    fi
                ;;
                "$office")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "abiword"               "$office0" OFF \
                        "calligra"              "$office1" OFF \
                        "evince"		"$office9" OFF \
                        "gnumeric"		"$office3" OFF \
                        "glabels"		"$office10" OFF \
                        "gobby"			"$office8" OFF \
                        "libreoffice-fresh"	"$office4" OFF \
                        "libreoffice-still"	"$office5" OFF \
                        "mupdf"			"$office6" OFF \
                        "scribus"		"$office11" OFF \
                        "zathura"		"$office7" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (<<<"$software" grep "libreoffice-fresh" &>/dev/null) && [ -n "$lib" ]; then
                        software+=" libreoffice-fresh-$lib"
                    fi

                    if (<<<"$software" grep "libreoffice-still" &>/dev/null) && [ -n "$lib" ]; then
                        software+=" libreoffice-still-$lib"
                    fi
                ;;
                "$programming")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "clisp"			"$prg0" OFF \
                        "dmd"		    "$prg1" OFF \
                        "dart"			"$prg2" OFF \
                        "go"			"$prg3" OFF \
                        "go-tools"		"$prg4" OFF \
                        "java-runtime-common"	"$prg5" OFF \
                        "jdk8-openjdk"	"$prg7" OFF \
                        "java-openjfx"	"$prg8" OFF \
                        "jdk11-openjdk" "$prg14" OFF \
                        "jdk-openjdk"   "$prg15" OFF \
                        "perl"			"$prg9" OFF \
                        "php"			"$prg10" OFF \
                        "python"		"$prg11" OFF \
                        "ruby"			"$prg12" OFF \
                        "scala"			"$prg13" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$terminal")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "cool-retro-term"	"$term12" OFF \
                        "guake"			"$term1" OFF \
                        "kmscon"		"$term2" OFF \
                        "pantheon-terminal"	"$term3" OFF \
                        "rxvt-unicode"		"$term4" OFF \
                        "screen"		"$sys11" OFF \
                        "terminator"		"$term5" OFF \
                        "terminology"		"$term10" OFF \
                        "termite"		"$term9" OFF \
                        "tilda"			"$term11" OFF \
                        "tilix"			"$term13" oFF \
                        "tmux"			"$sys14" OFF \
                        "xfce4-terminal"	"$term6" OFF \
                        "yakuake"		"$term7" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$text_editor")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "atom"			"$edit7" OFF \
                        "emacs"			"$edit0" OFF \
                        "geany"			"$edit1" OFF \
                        "gedit"			"$edit2" OFF \
                        "gvim"			"$edit3" OFF \
                        "mousepad"		"$edit4" OFF \
                        "neovim"		"$edit5" OFF \
                        "vim"			"$edit6" OFF \
                        "zim"			"$edit8" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$servers")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 63 10 \
                        "LAMP Stack"		"${srv1}" OFF \
                        "LEMP Stack"		"${srv2}" OFF \
                        "apache"		"${sys1}" OFF \
                        "bind"			"${srv10}" OFF \
                        "cups"			"${srv11}" OFF \
                        "lighttpd"		"${srv5}" OFF \
                        "nginx"			"${srv3}" OFF \
                        "nginx-mainline"	"${srv4}" OFF \
                        "openssh"		"${sys10}" OFF \
                        "postfix"		"${srv6}" OFF \
                        "samba"			"${srv9}" OFF \
                        "squid"			"${srv8}" OFF \
                        "vsftpd"		"${srv7}" OFF \
                        "dhcpcd"		"${srv12}" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (grep "dhcpcd" <<<"${software}" &>/dev/null); then
                        if (yesno "\n${dhcp_msg}" "${yes}" "${no}") then
                            dhcp=true
                        fi
                    fi

                    if (grep "LAMP" <<<"$software" &>/dev/null); then
                        if (yesno "\n${apache_msg}" "${yes}" "${no}") then
                            config_http="LAMP"
                            enable_http=true
                        fi
                        software=$(<<<"$software" sed 's/LAMP Stack/apache php php-apache mariadb/')
                    elif (grep "LEMP" <<<"$software" &>/dev/null); then
                        if (yesno "\n${nginx_msg}" "${yes}" "${no}") then
                            config_http="LEMP"
                            enable_http=true
                        fi
                        software=$(<<<"$software" sed 's/LEMP Stack/nginx-mainline php php-fpm mariadb/')
                    elif (grep "apache" <<<"$software" &>/dev/null); then
                        if (yesno "\n${apache_msg}" "${yes}" "${no}") then
                            config_http="apache"
                            enable_http=true
                        fi
                    elif (grep "nginx" <<<"$software" &>/dev/null); then
                        if (yesno "\n${nginx_msg}" "${yes}" "${no}") then
                            config_http="nginx"
                            enable_http=true
                        fi
                    fi

                    if (grep "openssh" <<<"$software" &>/dev/null); then
                        if (yesno "\n${ssh_msg}" "${yes}" "${no}") then
                            enable_ssh=true
                        fi
                    fi

                    if (grep "cups" <<<"$software" &>/dev/null); then
                        software=$(<<<"$software" sed 's/cups/cups cups-pdf/')
                        if (yesno "\n${cups_msg}" "${yes}" "${no}") then
                            enable_cups=true
                        fi
                    fi

                    if ! "$enable_ftp" ; then
                        if (yesno "\n${ftp_msg}" "${yes}" "${no}") then
                            enable_ftp=true
                            if (<<<"$software" grep "vsftpd" &>/dev/null); then
                                ftp="vsftpd"
                            else
                                ftp="ftpd"
                            fi
                        fi
                    fi

                ;;
                "$util")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 65 10 \
                        "bc"			"$sys25" OFF \
                        "bleachbit"		"$sys22" OFF \
                        "conky"			"$sys2" OFF \
                        "dmenu"			"$sys19" OFF \
                        "galculator"		"$sys24" OFF \
                        "git"			"$sys3" OFF \
                        "gnome-packagekit"	"$sys26" OFF \
                        "gnome-software"	"$sys27" OFF \
                        "gparted"		"$sys4" OFF \
                        "gpm"			"$sys5" OFF \
                        "htop"			"$sys6" OFF \
                        "k3b"			"$sys8" OFF \
                        "nmap"			"$sys9" OFF \
                        "ntfs-3g"		"$sys28" OFF \
                        "pcmanfm"		"$sys21" OFF \
                        "ranger"		"$sys20" OFF \
                        "scrot"			"$sys13" OFF \
                        "tuxcmd"		"$sys15" OFF \
                        "virtualbox"		"$sys16" OFF \
                        "ufw"			"$sys17" OFF \
                        "wget"			"$sys18" OFF \
                        "xscreensaver"		"$sys34" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi
                ;;
                "$extra_wm")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 65 10 \
                        "awesome"		    "$de9" OFF \
                        "bspwm"			    "$de13" OFF \
                        "enlightenment"		"$de7" OFF \
                        "fluxbox"			"$de11" OFF \
                        "i3"	        	"$de10" OFF \
                        "openbox"		    "$de8" OFF \
                        "sway"		        "$de21" OFF \
                        "qtile"			    "$de25" OFF \
                        "xmonad"            "$de16" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (<<<"$software" grep "xmonad") then
                        if (yesno "\n${extra_msg5}" "${yes}" "${no}") then
                            software+=" xmonad-contrib"
                        fi
                    fi

                    if (<<<"$software" grep "enlightenment") then
                        software+=" terminology"
                    fi

                    if (<<<"$software" grep "bspwm") then
                        software+=" sxhkd"
                    fi

                ;;
                "$extra_de")
                    software=$(dialog --ok-button "$ok" --cancel-button "$cancel" --checklist "$software_msg1" 20 65 10 \
                        "budgie"	    	"$de17" OFF \
                        "cinnamon"	        "$de5" OFF \
                        "deepin"	    	"$de14" OFF \
                        "gnome"			    "$de4" OFF \
                        "gnome-flashback"   "$de19" OFF \
                        "KDE plasma"    	"$de6" OFF \
                        "lxde"		        "$de2" OFF \
                        "lxqt"			    "$de3" OFF \
                        "mate"	    		"$de1" OFF \
                        "xfce4"		    	"$de0" OFF 3>&1 1>&2 2>&3)
                    if [ "$?" -gt "0" ]; then
                        add_soft=false
                    fi

                    if (<<<"$software" grep "xfce4") then
                        if (yesno "\n${extra_msg0}" "${yes}" "${no}") then
                            software+=" xfce4-goodies"
                        fi
                    fi

                    if (<<<"$software" grep "gnome") then
                        if (yesno "\n${extra_msg1}" "${yes}" "${no}") then
                            software+=" gnome-extra"
                        fi
                    fi

                    if (<<<"$software" grep "gnome-flashback") then
                        if (yesno "\n${extra_msg1}" "${yes}" "${no}") then
                            software+=" gnome-backgrounds gnome-control-center gnome-screensaver gnome-applets sensors-applet"
                        fi
                    fi

                    if (<<<"$software" grep "mate") then
                        if (yesno "\n${extra_msg2}" "${yes}" "${no}") then
                            software+=" mate-extra gtk-engine-murrine"
                        else
                            software+=" gtk-engine-murrine"
                        fi
                    fi

                    if (<<<"$software" grep "deepin") then
                        if (yesno "\n${extra_msg4}" "${yes}" "${no}") then
                            software+=" deepin-extra $kernel-headers"
                        fi
                    fi

                    if (<<<"$software" grep "cinnamon") then
                        software+=" cinnamon-translations gnome-terminal file-roller p7zip zip unrar"
                    fi

                    if (<<<"$software" grep "lxde") then
                        if (yesno "\n${gtk3_var}" "${yes}" "${no}") then
                            software+="lxde-gtk3 "
                        fi
                    fi

                    if (<<<"$software" grep "lxqt") then
                        software+=" oxygen-icons breeze-icons"
                    fi

                    if (<<<"$software" grep "budgie") then
                        software=$(<<<"$software" sed 's/budgie/budgie-desktop arc-icon-theme arc-gtk-theme elementary-icon-theme/')
                    fi

                    if (<<<"$software" grep "KDE") then
                        if (yesno "\n${extra_msg3}" "${yes}" "${no}" 1) then
                            software=$(<<<"$software" sed 's/KDE plasma/plasma-desktop konsole dolphin plasma-nm plasma-pa libxshmfence kscreen/')
                            if "$LAPTOP" ; then
                                software+=" powerdevil"
                            fi
                        else
                            software=$(<<<"$software" sed 's/KDE plasma/plasma ark aspell-en cdrdao clementine dolphin dolphin-plugins ffmpegthumbs gwenview k3b kate kcalc kdialog kfind kdeconnect kdegraphics-thumbnailers kdenetwork-filesharing kdesu kdelibs4support kipi-plugins khelpcenter konsole kwalletmanager okular spectacle transmission-qt krita kolourpaint korganizer knetattach falkon kdenlive/')
                        fi
                        software=$(<<<"$software" sed 's/KDE plasma/plasma-desktop konsole dolphin plasma-nm plasma-pa libxshmfence kscreen/')
                    fi
                ;;
                "$done_msg")
                    if [ -z "$final_software" ]; then
                        if (yesno "\n${software_warn_msg}" "${yes}" "${no}" 1) then
                            break
                        else
                            add_soft=false
                        fi
                    else
                        download=$(echo "$final_software" | sed 's/\"//g' | tr ' ' '\n' | nl | sort -u -k2 | sort -n | cut -f2- | sed 's/$/ /g' | tr -d '\n')
                        download_list=$(echo "$download" |  sed -e 's/^[ \t]*//')

                        if ! "$menu_enter" ; then
                            echo "$(date -u "+%F %H:%M") : Add software list: $download" >> "$log"
                            base_install+="$download_list "
                            unset final_software
                            break
                        else
                            pacman -Sy --print-format='%s' $(echo "$download") | awk '{s+=$1} END {print s/1024/1024}' >/tmp/size &
                            pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2pacman -S --print-format\Zn" load
                            download_size=$(</tmp/size) ; rm /tmp/size
                            export software_size=$(<<<"$download_size" sed 's/\(\..\)\(.*\)/\1 MiB/')
                            export software_int=$(echo "$download" | wc -w)
                            cal_rate

                            if [ "$software_int" -lt "20" ]; then
                                height=17
                            else
                                height=20
                            fi

                            if (yesno "\n${software_confirm_var1}" "${install}" "${cancel}") then
                                arch-chroot "${ARCH}" pacman --noconfirm -Sy archlinux-keyring &>>"${log}" &
                                arch-chroot "$ARCH" pacman --noconfirm -Sy $(echo "$download") &>>"$log" &
                                pid=$! pri=$(<<<"$down" sed 's/\..*$//') msg="\n$software_load_var" load_log
                                echo "$(date -u "+%F %H:%M") : Finished installing software" >> "$log"
                                unset final_software
                                break
                            else
                                unset final_software
                                add_soft=false
                            fi
                        fi

                    fi
                ;;
            esac

            if "$add_soft" ; then
                if [ -z "$software" ]; then
                    if ! (yesno "\n${software_noconfirm_msg} ${software_menu}?" "${yes}" "${no}" 1) then
                        skip=true
                    fi
                else
                    add_software=$(echo "$software" | sed 's/\"//g')
                    software_list=$(echo "$add_software" | sed -e 's/^[ \t]*//')
                    pacman -Sy --print-format='%s' $(echo "$add_software") | awk '{s+=$1} END {print s/1024/1024}' >/tmp/size &
                    pid=$! pri=0.1 msg="$wait_load \n\n \Z1> \Z2pacman -Sy --print-format\Zn" load

                    download_size=$(</tmp/size) ; rm /tmp/size
                    software_size=$(<<<"$download_size" sed 's/\(\..\)\(.*\)/\1 MiB/')
                    software_int=$(echo "$add_software" | wc -w)
                    source "$lang_file"

                    if [ "$software_int" -lt "15" ]; then
                        height=14
                    else
                        height=16
                    fi

                    if (yesno "\n${software_confirm_var0}" "${add}" "${cancel}") then
                        final_software+="$software "
                    fi
                fi
            fi
        done
    fi

}

# vim: ai:ts=4:sw=4:et
