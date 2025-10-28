package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from Go!")
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Server is running on :80")
	http.ListenAndServe(":80", nil)
}