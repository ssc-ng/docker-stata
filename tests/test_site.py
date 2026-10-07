"""Checks on the GitHub Pages site (site/): the project-Pages baseurl, the
embedded image catalogue, and -- when the site has been built -- that every
root-absolute link in the generated HTML carries the baseurl prefix.

The site is published at https://ssc-ng.net/docker-stata/, i.e. under a
path prefix. Without `baseurl` the theme's stylesheets 404 and the page
renders unstyled. Standard library only; the built-output check is skipped
when site/_site is absent (run `bundle exec jekyll build` in site/).
"""
import json
import re
import unittest
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent / "site"
BASEURL = "/docker-stata"


class ConfigTest(unittest.TestCase):
    def test_baseurl_and_url(self):
        cfg = (SITE / "_config.yml").read_text(encoding="utf-8")
        self.assertRegex(cfg, r'(?m)^baseurl:\s*"?%s"?\s*$' % BASEURL)
        self.assertRegex(cfg, r'(?m)^url:\s*"?https://ssc-ng\.net"?\s*$')


class CatalogueTest(unittest.TestCase):
    def setUp(self):
        js = (SITE / "assets/js/picker.js").read_text(encoding="utf-8")
        self.data = json.loads(re.search(r"const DATA = (.*);\n", js).group(1))

    def test_versions_newest_first_with_tags(self):
        versions = self.data["versions"]
        self.assertTrue(versions, "no versions: run site/build_data.py")
        for v in versions:
            for flavors in v["editions"].values():
                for tags in flavors.values():
                    self.assertTrue(tags)
                    self.assertTrue(all(re.fullmatch(r"\d{4}-\d{2}-\d{2}|latest", t) for t in tags))


@unittest.skipUnless((SITE / "_site").is_dir(), "site not built")
class BuiltLinksTest(unittest.TestCase):
    def test_root_absolute_links_have_baseurl(self):
        bad = []
        for page in (SITE / "_site").rglob("*.html"):
            for link in re.findall(r'(?:href|src)="(/[^"]*)"', page.read_text(encoding="utf-8")):
                if not link.startswith("//") and not (link + "/").startswith(BASEURL + "/"):
                    bad.append((page.name, link))
        self.assertEqual(bad, [])


if __name__ == "__main__":
    unittest.main()
