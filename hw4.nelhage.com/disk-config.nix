{ lib, ... }:
let
  nvmconf = {
    type = "gpt";
    partitions = {
      grub = {
        size = "1M";
        type = "EF02";
      };
      boot = {
        size = "1G";
        type = "EF00";
        content = {
          type = "mdraid";
          name = "boot";
        };
      };
      primary = {
        size = "100%";
        content = {
          type = "mdraid";
          name = "vg00";
        };
      };
    };
  };
in
{
  disko.devices = {
    disk = {
      nvme1n1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = nvmconf;
      };
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = nvmconf;
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };
      vg00 = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "lvm_pv";
          vg = "vg00";
        };
      };
    };
    lvm_vg = {
      vg00 = {
        type = "lvm_vg";
        lvs = {
          nix = {
            size = "50G";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/nix";
            };
          };
          root = {
            size = "300G";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
