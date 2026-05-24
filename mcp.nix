{pkgs, ...}: {
  programs = {
    playwright.enable = true;
  };
  settings.servers = {
    flux-operator-mcp = {
      command = "${pkgs.fluxcd-operator-mcp}/bin/fluxcd-operator-mcp";
    };
  };
  flavors.opencode.enable = true;
}
