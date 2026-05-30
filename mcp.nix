{pkgs, ...}: {
  programs = {
    playwright.enable = true;
  };
  settings.servers = {
    flux-operator-mcp = {
      command = "${pkgs.fluxcd-operator-mcp}/bin/fluxcd-operator-mcp";
    };
    kubernetes-mcp-server = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "kubernetes-mcp-server@latest"
      ];
    };
  };
  flavors.opencode.enable = true;
}
