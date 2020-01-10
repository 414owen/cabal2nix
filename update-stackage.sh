#! /usr/bin/env bash

set -eu -o pipefail

cd "$(dirname "$0")"

tmpfile=$(mktemp "update-stackage.XXXXXXX")
# shellcheck disable=SC2064
trap "rm ${tmpfile} ${tmpfile}.new" 0

curl -L -s "https://stackage.org/lts/cabal.config" >"$tmpfile"
version=$(sed -rn "s/^--.*http:..(www.)?stackage.org.snapshot.lts-//p" "$tmpfile")

# Create a simple yaml version of the file.
sed -r \
    -e '/^--/d' \
    -e 's|^constraints:||' \
    -e 's|^ +|  - |' \
    -e 's|,$||' \
    -e '/installed$/d' \
    -e '/^$/d' \
    < "${tmpfile}" | sort --ignore-case >"${tmpfile}.new"

# Drop restrictions on some tools where we always want the latest version.
sed -r \
    -e '/ cabal-install /d' \
    -e '/ cabal2nix /d' \
    -e '/ cabal2spec /d' \
    -e '/ distribution-nixpkgs /d' \
    -e '/ git-annex /d' \
    -e '/ hindent /d' \
    -e '/ hledger/d' \
    -e '/ hlint /d' \
    -e '/ hoogle /d' \
    -e '/ hopenssl /d' \
    -e '/ jailbreak-cabal /d' \
    -e '/ json-autotype/d' \
    -e '/ language-nix /d' \
    -e '/ shake /d' \
    -e '/ ShellCheck /d' \
    -e '/ stack /d' \
    -e '/ weeder /d' \
    < "${tmpfile}.new" > "${tmpfile}"

# Drop the previous configuration ...
# shellcheck disable=SC1004
sed -e '/  # LTS Haskell/,/^$/c \TODO\
'   -i nixpkgs/pkgs/development/haskell-modules/configuration-hackage2nix.yaml

# ... and replace it with the new one.
sed -e "/TODO/r $tmpfile" \
    -e "s/TODO/  # LTS Haskell $version/" \
    -i nixpkgs/pkgs/development/haskell-modules/configuration-hackage2nix.yaml
