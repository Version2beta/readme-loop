// Package wrap wraps text to a width.
package wrap

import (
	"errors"
	"strings"
)

// Wrap splits text into words on whitespace and joins them into lines no
// longer than width, separated by "\n". A word longer than width gets a
// line of its own. width < 1 returns an error.
func Wrap(text string, width int) (string, error) {
	if width < 1 {
		return "", errors.New("wrap: width must be at least 1")
	}
	var lines []string
	cur := ""
	for _, w := range strings.Fields(text) {
		switch {
		case cur == "":
			cur = w
		case len(cur)+1+len(w) <= width:
			cur += " " + w
		default:
			lines = append(lines, cur)
			cur = w
		}
	}
	if cur != "" {
		lines = append(lines, cur)
	}
	return strings.Join(lines, "\n"), nil
}
