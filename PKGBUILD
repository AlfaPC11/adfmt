# Maintainer: Alfa <AlfaPC11@users.noreply.github.com>
# SPDX-License-Identifier: BSL-1.0

pkgname=adfmt-git
epoch=1
pkgver=0.4.0.r0.g0000000
pkgrel=1
pkgdesc="Alfa's D Formatter with separate declaration and control-flow brace styles"
arch=('x86_64')
url='https://github.com/AlfaPC11/adfmt'
license=('BSL-1.0')
depends=('gcc-libs' 'glibc')
makedepends=('dub' 'git' 'ldc')
provides=('adfmt')
conflicts=('adfmt')
options=('!debug')
source=('adfmt::git+https://github.com/AlfaPC11/adfmt.git')
sha256sums=('SKIP')

pkgver() {
  cd "$srcdir/adfmt"
  git describe --long --tags --match 'adfmt-v[0-9]*' --abbrev=7 |
    sed 's/^adfmt-v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  cd "$srcdir/adfmt"
  mkdir -p bin
  dub build --build=release --compiler=ldc2
}

check() {
  cd "$srcdir/adfmt"
  local runner
  runner="$(mktemp)"
  trap 'rm -f "$runner"' RETURN
  dub test --compiler=ldc2
  dub build --build=release --compiler=ldc2
  ldc2 tests/test.d -of="$runner"
  (cd tests && "$runner")
  ADFMT_BIN="$PWD/bin/adfmt" tests/cli.sh
}

package() {
  cd "$srcdir/adfmt"
  install -Dm755 bin/adfmt "$pkgdir/usr/bin/adfmt"
  install -Dm644 LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 PATENTS "$pkgdir/usr/share/licenses/$pkgname/PATENTS"
  install -Dm644 NOTICE "$pkgdir/usr/share/licenses/$pkgname/NOTICE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 CHANGELOG.md "$pkgdir/usr/share/doc/$pkgname/CHANGELOG.md"
  install -Dm644 DIFFERENCES.md "$pkgdir/usr/share/doc/$pkgname/DIFFERENCES.md"
  install -Dm644 HISTORY.md "$pkgdir/usr/share/doc/$pkgname/HISTORY.md"
  install -Dm644 .adfmt "$pkgdir/usr/share/doc/$pkgname/adfmt.example"
  cp -r docs examples "$pkgdir/usr/share/doc/$pkgname/"
  install -Dm644 bash-completion/completions/adfmt \
    "$pkgdir/usr/share/bash-completion/completions/adfmt"
}
