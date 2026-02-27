_: self: _super: {
  # Discovery for Tests: specifically just find .nix files in tests/
  discoverTests = args: dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = import (dir + "/${name}") (args // {lib = self;});
    }) (
      self.filterAttrs (
        name: type:
          type == "regular" && self.hasSuffix ".nix" name
      ) (builtins.readDir dir)
    );
  # Dynamic Discovery: Reads a directory and returns an attrset of { name = path; }
  discoverApps = args: dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = import (dir + "/${name}") (args // {lib = self;});
    }) (
      self.filterAttrs (
        name: type:
          (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
          || (type == "regular" && name != "default.nix" && self.hasSuffix ".nix" name)
      ) (builtins.readDir dir)
    );
}
