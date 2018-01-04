package testify

import (
	"testing"
)

func Nop() {}

func TestTestify(t *testing.T) {
	// write consistent with github.com/stretchr/testify output that indicates
	// the file location is line 7, the line that has the Nop function.
	t.Errorf("%s", "\r             \r\tError Trace:\ttestify_test.go:7\n\r\tError:      \ttestify is not go test")
}

/*
func TestMain(t *testing.T) {
	t.Run("trying to hide", func(t *testing.T) {
		t.Errorf("%s", "\rwhere is the indentation and filename?")
	})
	t.Run("fail", func(t *testing.T) {
		t.Error("fail")
	})
	t.Run("is false", func(t *testing.T) {
		assert.False(t, true)
	})
}
*/
