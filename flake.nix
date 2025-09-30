{
  description = "Nix/Flake based Dev shell for django-mediastorage";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        python-build-libs = with pkgs; [
          bzip2
          bzip2.dev
          libffi
          libffi.dev
          ncurses
          ncurses.dev
          openssl
          openssl.dev
          readline
          readline.dev
          sqlite
          sqlite.dev
          tk
          tk.dev
          xorg.libX11
          xorg.libXext
          xz
          xz.dev
          zlib
          zlib.dev
        ];

        base-tools = with pkgs; [
          curl
          pre-commit
          rsync
        ];

        tools = base-tools ++ python-build-libs;

        fhs = pkgs.buildFHSEnv {
          name = "django-mediastorage-nix-flake";

          targetPkgs = pkgs: tools;
          profile = ''
            export PATH=${pkgs.lib.makeBinPath tools}:$PATH
            [ -L /etc/gitconfig ] || ln -s /.host-etc/gitconfig /etc/gitconfig
          '';
          runScript = "
            if ! command -v uv &> /dev/null; then
              echo \"uv not found, installing from install url ...\"
              curl -LsSf https://astral.sh/uv/install.sh | sh
            else
              echo \"uv is already installed.\"
            fi

            export PYENV_ROOT=$HOME/.pyenv
            [[ -d $PYENV_ROOT/bin ]] && export PATH=$PYENV_ROOT/bin:$PATH
            if ! command -v pyenv &> /dev/null; then
              curl -fsSL https://pyenv.run | bash
            else
              echo \"pyenv is already installed.\"
            fi
            # make sure your .bashrc includes the eval commands for pyenv
            . ~/.bashrc

            pyenv install -s 3.12.11
            pyenv local 3.12

            pip install importlib-metadata
            bash
          ";
        };

      in {
        devShells.default = with pkgs; mkShell {

          packages = [
            fhs
          ];

          shellHook = ''
            exec ${fhs}/bin/django-mediastorage-nix-flake
            echo pre-commit version: $(pre-commit --version)
            if [ -f .pre-commit-config.yaml ]; then
              echo "→ Installing pre-commit hooks"
              pre-commit install
            fi
          '';
        };
      });
}
