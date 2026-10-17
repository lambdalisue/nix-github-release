{ pkgs, nix-github-release }:
let
  inherit (nix-github-release.lib) fromDescribe stampCargo;

  # A failing case is listed by name in the build log, with what it expected
  # and what it got.
  assertNone =
    name: failures:
    if failures == [ ] then
      pkgs.runCommand name { } "touch $out"
    else
      throw "${name}: ${builtins.toJSON failures}";
in
{
  values = assertNone "values" (
    pkgs.lib.runTests {
      testAReleaseTagIsItsVersion = {
        expr = fromDescribe {
          described = "v1.2.3";
          rev = "abc1234";
        };
        expected = "1.2.3";
      };
      testAPrereleaseTagKeepsItsSuffix = {
        expr = fromDescribe {
          described = "v1.2.3-rc.1";
          rev = "abc1234";
        };
        expected = "1.2.3-rc.1";
      };
      testACommitPastATagIsDescribedFromIt = {
        expr = fromDescribe {
          described = "v1.2.3-4-gabc1234";
          rev = "abc1234";
        };
        expected = "1.2.3-4-gabc1234";
      };
      testTheTrailingNewlineOfTheFileIsIgnored = {
        expr = fromDescribe {
          described = "v1.2.3\n";
          rev = "abc1234";
        };
        expected = "1.2.3";
      };
      testAnUnfilledPlaceholderNamesTheCommit = {
        expr = fromDescribe {
          described = "$Format:%(describe:tags,match=v[0-9]*)$\n";
          rev = "abc1234";
        };
        expected = "0.0.0-abc1234";
      };
      testACommitBeforeAnyTagNamesTheCommit = {
        expr = fromDescribe {
          described = "\n";
          rev = "abc1234";
        };
        expected = "0.0.0-abc1234";
      };
      testTheFallbackStartsFromTheGivenPlaceholder = {
        expr = fromDescribe {
          described = "";
          rev = "abc1234";
          placeholder = "0.1.0";
        };
        expected = "0.1.0-abc1234";
      };
      testStampingAlsoNamesTheVersionOfTheDerivation = {
        expr =
          (stampCargo {
            inherit pkgs;
            version = "1.2.3";
          } { }).version;
        expected = "1.2.3";
      };
    }
  );

  # Stamps a workspace's manifest and lock the way a release workflow does,
  # through the hooks a crane or rustPlatform build already runs.
  stamp-cargo = pkgs.stdenvNoCC.mkDerivation (
    stampCargo
      {
        inherit pkgs;
        version = "1.2.3-4-gabc1234";
      }
      {
        name = "stamp-cargo";
        src = ./fixtures/cargo/input;
        # What the caller already had must still run.
        nativeBuildInputs = [ pkgs.hello ];
        postPatch = ''
          hello > greeting
        '';
        dontBuild = true;
        installPhase = ''
          diff -u ${./fixtures/cargo/expected/Cargo.toml} Cargo.toml
          diff -u ${./fixtures/cargo/expected/Cargo.lock} Cargo.lock
          test -s greeting
          touch $out
        '';
      }
  );
}
