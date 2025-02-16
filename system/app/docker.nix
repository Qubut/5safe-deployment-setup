{
  pkgs,
  lib,
  systemSettings,
  userSettings,
  storageDriver ? "btrfs",
  ...
}:

assert lib.asserts.assertOneOf "storageDriver" storageDriver [
  null
  "aufs"
  "btrfs"
  "devicemapper"
  "overlay"
  "overlay2"
  "zfs"
];
{

  hardware.nvidia-container-toolkit = {
    enable = systemSettings.hasNvidia;
    mount-nvidia-executables = true;
    mount-nvidia-docker-1-directories = true;
  };
  virtualisation={
    containers.enable = true;
    podman = {
      enable = false;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
      # extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS
    };
    docker = {
      # package = pkgs.docker_25;
      enable = true;
      enableOnBoot = true;
      # enableNvidia = true;
      storageDriver = storageDriver;
      autoPrune.enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
        default-runtime = if (systemSettings.hasNvidia) then "nvidia" else "containerd";
        exec-opts = ["native.cgroupdriver=cgroupfs"];
      };
    };
  };

};
  users.users.${userSettings.username}.extraGroups = [ "docker" ];
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    containerd
    lazydocker
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];
}
