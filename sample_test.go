package main

import (
  "testing"
  "io/ioutil"
  "net/http"
  "net/http/httptest"
)

func TestPing(t *testing.T) {
  ts := httptest.NewServer( http.HandlerFunc( Ping ) )
  defer ts.Close()

  r,err := http.Get(ts.URL)
  if err != nil {
    t.Fatalf("Error by http.Get(). %v", err)
  }

  data, err := ioutil.ReadAll(r.Body)
  if err != nil {
    t.Fatalf("Error by ioutil.ReadAll(). %v", err)
  }

  if "Hello world!" != string(data) {
    t.Fatalf("Data Error. %v", string(data))
  }
}

func TestDeepPing(t *testing.T) {
  ts := httptest.NewServer( http.HandlerFunc( DeepPing ) )
  defer ts.Close()

  r,err := http.Get(ts.URL)
  if err != nil {
    t.Fatalf("Error by http.Get(). %v", err)
  }

  data, err := ioutil.ReadAll(r.Body)
  if err != nil {
    t.Fatalf("Error by ioutil.ReadAll(). %v", err)
  }

  if "Hello world!" != string(data) {
    t.Fatalf("Data Error. %v", string(data))
  }
}

