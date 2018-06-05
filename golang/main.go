package main

import (
	"fmt"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"strconv"
)

func main() {
	router := mux.NewRouter()
	router.HandleFunc("/", Index)
	router.HandleFunc("/orderbook", ViewOrderbook)
	router.HandleFunc("/buy/{userId:[0-9]+}/{price:[0-9]+}", PlaceBuy)
	router.HandleFunc("/sell/{userId:[0-9]+}/{price:[0-9]+}", PlaceSell)
	log.Fatal(http.ListenAndServe(":8080", router))
}

func Index(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello")
}

func ViewOrderbook(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "TODO")
}

func PlaceBuy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId, _ := strconv.Atoi(vars["userId"])
	price, _ := strconv.Atoi(vars["price"])
	fmt.Fprintln(w, "TODO:", userId, price)
}

func PlaceSell(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userId, _ := strconv.Atoi(vars["userId"])
	price, _ := strconv.Atoi(vars["price"])
	fmt.Fprintln(w, "TODO:", userId, price)
}
