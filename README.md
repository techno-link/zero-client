# zero-client

```
sudo dd if="mini.iso" bs=1 count=466 of="mini-mbr.img"
```

```
xorriso -as mkisofs -r -V "Zero Client" \
            -cache-inodes -J -l \
            -isohybrid-mbr "mini-mbr.img" \
            -c boot.cat \
            -b isolinux.bin \
            -no-emul-boot -boot-load-size 4 -boot-info-table \
            -eltorito-alt-boot \
            -e boot/grub/efi.img \
            -no-emul-boot -isohybrid-gpt-basdat \
            -o "custom.iso" \
            "mini"
```


grub.cfg

```
menuentry "Zero Unattended Installation" {
    set gfxpayload=keep
    linux    /linux auto=true priority=critical debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=us ubiquity/reboot=true languagechooser/language-name=English countrychooser/shortlist=US localechooser/supported-locales=en_US.UTF-8 automatic-ubiquity noprompt noshell netcfg/choose_interface=auto debian-installer/allow_unauthenticated_ssl=true url=https://raw.githubusercontent.com/techno-link/zero-client/master/preseed.cfg boot=casper quiet splash ---
    initrd    /initrd.gz
}
```

## TODO

+ Automate USB creation...
    - production - everything locked
    - development - everything locked, but from dev branch
    - testing (dev/prod) - xterm and sudo for prod/dev
    - create BIOS boot menuetry - txt.cfg
    
+ Replace volume control with pactrl script for auto discovery and volume levels.
+ https://linuxize.com/post/how-to-set-up-automatic-updates-on-ubuntu-18-04/
-
