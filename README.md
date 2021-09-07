Example external plugin for searx
=================================


This is a sample external plugin for searx.

### Installation

Run `python setup.py install` in the same environment with searx.

#### In NixOS server

[Nix](https://nixos.org/) is a purely functional package manager & NixOS is a GNU\Linux distribution built with that package manager  
NixPkgs provides packages for any system running the Nix package manager (available on Linux & MacOS).  
This allows for fully declarative system configuration, atomic updates & rollbacks

If the Searx is installed on the NixOS server 
it is possible to add plugin to both current generation configuration and to flake-based one
- via specifying `nix-flake input`
- import module with "fetchFromGithub" 

(See [example configuration](https://github.com/efim/nix-searx-container-example)). 

### Development
#### With Nix
For local development nix provides environment with installed Searx & required dependencies  
Use `$ nix-shell` or `$ nix develop` (for Nix with flakes enabled) to enter such shell

It will expose command `searx-run` that would start local Searx instance with plugin installed  
Additionally `nix-direnv` can be used to automatically reload environment on file-change

(all dependencies are installed into /nix/store and don't interfere with other parts of OS)
