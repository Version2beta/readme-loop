// Package wrap wraps text to a width.
package wrap

// Wrap splits text into words on whitespace and joins them into lines no
// longer than width, separated by "\n". A word longer than width gets a
// line of its own. width < 1 returns an error.
func Wrap(text string, width int) (string, error) { return "", nil }
