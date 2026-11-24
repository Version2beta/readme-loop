// Package slug turns titles into URL slugs.
package slug

import "strings"

// Slugify lowercases s, replaces each run of characters that are not
// ASCII letters or digits with a single hyphen, and trims hyphens from
// both ends. An input with no letters or digits returns "".
func Slugify(s string) string {
	var b strings.Builder
	sep := false
	for _, r := range strings.ToLower(s) {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			if sep && b.Len() > 0 {
				b.WriteByte('-')
			}
			sep = false
			b.WriteRune(r)
		} else {
			sep = true
		}
	}
	return b.String()
}
