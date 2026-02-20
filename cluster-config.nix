{
  clusterName = "adams";

  controlNodes = [
    {
      hostname = "cluster-manager-1";
      machine = {
        mode = "metal";
      };
      ipAddress = "192.168.1.252";
      extensions = {
        official = [
          "siderolabs/qemu-guest-agent"
          "siderolabs/tailscale"
        ];
      };
    }
  ];

  workerNodes = [
    {
      hostname = "cluster-worker-1";
      machine = {
        mode = "metal";
      };
      ipAddress = "192.168.1.253";
      extensions = {
        official = [
          "siderolabs/qemu-guest-agent"
          "siderolabs/tailscale"
        ];
      };
    }
  ];
}
