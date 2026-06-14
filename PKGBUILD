# Maintainer: Alfa <AlfaPC11@users.noreply.github.com>
# SPDX-License-Identifier: BSL-1.0

pkgname=adfmt-git
pkgver=0.3.5.r0.g845a9d3
pkgrel=1
pkgdesc="Alfa's D Formatter development version"
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
  cd adfmt
  git describe --long --tags --abbrev=7 \
    | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  cd adfmt
  dub build --build=release --compiler=ldc2
}

check() {
  cd adfmt
  dub test --compiler=ldc2
}

package() {
  cd adfmt
  install -Dm755 bin/adfmt "$pkgdir/usr/bin/adfmt"
  install -Dm644 LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 PATENTS "$pkgdir/usr/share/licenses/$pkgname/PATENTS"
  install -Dm644 NOTICE "$pkgdir/usr/share/licenses/$pkgname/NOTICE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 DIFFERENCES.md "$pkgdir/usr/share/doc/$pkgname/DIFFERENCES.md"
  install -Dm644 HISTORY.md "$pkgdir/usr/share/doc/$pkgname/HISTORY.md"
  cp -r docs examples "$pkgdir/usr/share/doc/$pkgname/"
  install -Dm644 bash-completion/completions/adfmt \
    "$pkgdir/usr/share/bash-completion/completions/adfmt"
}
