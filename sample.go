package main

import (
	"os"
	"fmt"
	"net/http"
	"database/sql"
	log "github.com/sirupsen/logrus"
	mysql "github.com/go-sql-driver/mysql"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	sqltrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/database/sql"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

type Server struct {
	db *sql.DB
}

func (s *Server) Ping(w http.ResponseWriter, r *http.Request) {
	log.Info("ping ok")
	fmt.Fprintf(w, "Hello world!")
}

func (s *Server) DeepPing(w http.ResponseWriter, r *http.Request) {
	_, err := s.db.Exec("SELECT 1")
	if err != nil {
		log.Info("deep_ping ng")
		fmt.Fprintf(w, "[ERROR]");
		w.WriteHeader(http.StatusServiceUnavailable)
	} else {
		log.Info("deep_ping ok")
		fmt.Fprintf(w, "Hello world!")	
	}
}

func DatabaseOpen() *sql.DB {
	dbuser := os.Getenv("DBUSER")
	dbpass := os.Getenv("DBPASS")
	dbaddress := os.Getenv("DBADDRESS")
	dbport := os.Getenv("DBPORT")
	dbname:= os.Getenv("DBNAME")

	sqltrace.Register("mysql", &mysql.MySQLDriver{}, sqltrace.WithServiceName("sample-db"))
	db, err := sqltrace.Open("mysql", dbuser + ":" + dbpass + "@tcp("+ dbaddress + ":" + dbport + ")/" + dbname)

	if err != nil {
        panic(err)
	}
	
	err = db.Ping()
    if err != nil {
        panic(err)
    }
	
	return db
}

func main() {
    tracer.Start(tracer.WithServiceName("sample"))
    defer tracer.Stop()

	log.SetFormatter(&log.JSONFormatter{})
	log.Info("start")

	db := DatabaseOpen()
	defer db.Close()

	s := Server{db : db}
	mux := httptrace.NewServeMux()
	mux.HandleFunc("/ping", s.Ping)
	mux.HandleFunc("/deep_ping", s.DeepPing)
	http.ListenAndServe(":80", mux)
}

