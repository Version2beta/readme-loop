package wrap

import "testing"

func TestWrapRejectsBadWidth(t *testing.T) {
	if _, err := Wrap("ok", 5); err != nil { // must-succeed case first
		t.Fatalf("Wrap(width 5) returned error %v, want nil", err)
	}
	if _, err := Wrap("x", 0); err == nil {
		t.Errorf("Wrap(width 0) returned nil error, want an error")
	}
}

func TestWrapLines(t *testing.T) {
	cases := []struct {
		in    string
		width int
		want  string
	}{
		{"the quick brown fox", 10, "the quick\nbrown fox"},
		{"a   b\tc", 3, "a b\nc"},
		{"supercalifragilistic is long", 6, "supercalifragilistic\nis\nlong"},
		{"", 4, ""},
	}
	for _, c := range cases {
		got, err := Wrap(c.in, c.width)
		if err != nil || got != c.want {
			t.Errorf("Wrap(%q,%d) = %q,%v want %q,nil", c.in, c.width, got, err, c.want)
		}
	}
}
