{
  description = "sample external plugin";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/21.05";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, ... }:
    let
      # System types to support.
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # python module name, that's used in `setup.py`
      pluginName = "plugin1";

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);
      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (
        system:
          import nixpkgs {
            inherit system;
            overlays = [ self.overlay ];
          }
      );
    in
      {

        overlay = final: prev: rec {
          searx-sample-plugin = prev.python38Packages.buildPythonPackage {
            pname = "searx-sample-plugin";
            version = "1.0";
            buildInputs = [
              prev.searx
            ];
            src = ./.;
            doCheck = true;
          };

          # overlaying searx with version that depends plugin
          # results in plugin being installed in the searx environment via python setuptools
          # which is the requirement for the plugin to be available for searx:
          # https://searx.github.io/searx/dev/plugins.html#external-plugins
          searx = prev.searx.overrideAttrs (
            oldAttrs: {
              propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
                searx-sample-plugin
              ];
              postFixup = ''
                ${oldAttrs.postFixup}
                mkdir -p $out/share/static/plugins/external_plugins/plugin_${pluginName}
                cp -r ${searx-sample-plugin}/lib/python3.8/site-packages/${pluginName}/resources/. $out/share/static/plugins/external_plugins/plugin_${pluginName}/
              '';
            }
          );

        };

        packages = forAllSystems (
          system:
            {
              inherit (nixpkgsFor.${system}) searx-sample-plugin searx;
            }
        );

        # The default package for 'nix build'. This makes sense if the
        # flake provides only one package or there is a clear "main"
        # package.
        # Returns Searx with plugin enabled
        defaultPackage = forAllSystems (system: self.packages.${system}.searx);

        # To use as `nix develop`
        # will provide shell with
        # - `searx-run`
        # - simple searx config that would allow its launch & plugin utilization
        devShell = forAllSystems (
          system: nixpkgsFor.${system}.mkShell rec {
            packages = with nixpkgsFor.${system}; [ searx searx-sample-plugin ];
            settingsFile = nixpkgsFor.${system}.writeText "settings.yml"
              ''
                use_default_settings: True
                server:
                    secret_key : "dev-server-secret"

                plugins:
                  - ${pluginName}
              '';
            SEARX_SETTINGS_PATH = "${settingsFile}";
          }
        );

        # Can be used to add plugin to searx installation
        # in the server configuration
        # 1. add this flake as input
        # ```
        # inputs = {
        #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
        #   sample-searx-plugin.url = "github:efim/sample-searx-plugin";
        # };
        # ```
        # 2. add module for import:
        # ```
        # modules = [ sample-searx-plugin.nixosModules.sample-searx-plugin-module ]
        # ```
        # This will add overlay for searx, to depend on plugin and have it installed in the python env
        # and add configuration line to mark plugin for availability in settins
        # see: https://searx.github.io/searx/dev/plugins.html#external-plugins
        nixosModules.sample-searx-plugin-module = { pkgs, ... }:
          {
            nixpkgs.overlays = [ self.overlay ];
            services.searx.settings = {
              plugins = [ pluginName ];
            };
          };


      };

}
