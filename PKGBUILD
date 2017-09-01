# Author: Carlos Millán Soler <carmilso@upv.es>

pkgname=checkpkg
pkgver=1.1
pkgrel=1
pkgdesc="Bash script to check updates of packages given from arguments or stdin with no need to update the local repositories."
arch=('any')
url="https://github.com/carmilso/$pkgname"
license=('GPL3')
source=("https://github.com/carmilso/$pkgname/releases/download/v$pkgver/$pkgname-$pkgver.tar.gz")
depends=('jq')

package() {
  cd "$pkgname-$pkgver"
  make DESTDIR="$pkgdir" install
}
